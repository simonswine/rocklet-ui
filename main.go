/*
Copyright 2017 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"
	"github.com/rs/zerolog"
	"k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/fields"
	"k8s.io/apimachinery/pkg/util/runtime"
	"k8s.io/apimachinery/pkg/util/wait"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/cache"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/workqueue"

	vacuumv1alpha1 "github.com/simonswine/rocklet/pkg/apis/vacuum/v1alpha1"
	vacuum "github.com/simonswine/rocklet/pkg/client/clientset/versioned"
)

var log = zerolog.New(os.Stdout).With().Timestamp().Str("app", "rocklet-ui").Logger().Level(zerolog.DebugLevel)

var hub *Hub

var controllerIndex = make(map[string]*Controller)

type Controller struct {
	indexer  cache.Indexer
	queue    workqueue.RateLimitingInterface
	informer cache.Controller
	resource string
}

func NewController(queue workqueue.RateLimitingInterface, indexer cache.Indexer, informer cache.Controller, resource string) *Controller {
	return &Controller{
		informer: informer,
		indexer:  indexer,
		queue:    queue,
		resource: resource,
	}
}

func (c *Controller) processNextItem() bool {
	// Wait until there is a new item in the working queue
	key, quit := c.queue.Get()
	if quit {
		return false
	}
	// Tell the queue that we are done with processing this key. This unblocks the key for other workers
	// This allows safe parallel processing because two pods with the same key are never processed in
	// parallel.
	defer c.queue.Done(key)

	// Invoke the method containing the business logic
	err := c.sendNotify(key.(string))
	// Handle the error if something went wrong during the execution of the business logic
	c.handleErr(err, key)
	return true
}

func (c *Controller) sendNotify(key string) error {
	notifyKey := fmt.Sprintf("%s/%s", c.resource, key)
	log.Info().Str("notify_key", notifyKey).Msg("received update")
	hub.broadcast <- []byte(notifyKey)
	return nil
}

// handleErr checks if an error happened and makes sure we will retry later.
func (c *Controller) handleErr(err error, key interface{}) {
	if err == nil {
		// Forget about the #AddRateLimited history of the key on every successful synchronization.
		// This ensures that future processing of updates for this key is not delayed because of
		// an outdated error history.
		c.queue.Forget(key)
		return
	}

	// This controller retries 5 times if something goes wrong. After that, it stops trying.
	if c.queue.NumRequeues(key) < 5 {
		log.Info().Msgf("Error syncing pod %v: %v", key, err)

		// Re-enqueue the key rate limited. Based on the rate limiter on the
		// queue and the re-enqueue history, the key will be processed later again.
		c.queue.AddRateLimited(key)
		return
	}

	c.queue.Forget(key)
	// Report to an external entity that, even after several retries, we could not successfully process this key
	runtime.HandleError(err)
	log.Info().Msgf("Dropping %s %q out of the queue: %v", c.resource, key, err)
}

func (c *Controller) Run(threadiness int, stopCh chan struct{}) {
	defer runtime.HandleCrash()

	// Let the workers stop when we are done
	defer c.queue.ShutDown()
	log.Info().Str("resource", c.resource).Msg("starting controller")

	go c.informer.Run(stopCh)

	// Wait for all involved caches to be synced, before processing items from the queue is started
	if !cache.WaitForCacheSync(stopCh, c.informer.HasSynced) {
		runtime.HandleError(fmt.Errorf("Timed out waiting for caches to sync"))
		return
	}

	for i := 0; i < threadiness; i++ {
		go wait.Until(c.runWorker, time.Second, stopCh)
	}

	<-stopCh
	log.Info().Str("resource", c.resource).Msg("stopping controller")
}

func (c *Controller) runWorker() {
	for c.processNextItem() {
	}
}

func main() {
	var kubeconfig string
	var master string
	var listen string

	hub = newHub()
	go hub.run()

	flag.StringVar(&kubeconfig, "kubeconfig", "", "absolute path to the kubeconfig file")
	flag.StringVar(&master, "master", "", "master url")
	flag.StringVar(&listen, "listen", ":8812", "listen host")
	flag.Parse()

	var config *rest.Config
	var err error

	if kubeconfig != "" {
		// creates the connection
		config, err = clientcmd.BuildConfigFromFlags(master, kubeconfig)
		if err != nil {
			log.Fatal().Err(err).Msg("error building config from kubeconfig")
		}
	} else {
		config, err = rest.InClusterConfig()
		if err != nil {
			log.Fatal().Err(err).Msg("error building in-cluster config")
		}
	}

	// creates the clientset
	clientset, err := vacuum.NewForConfig(config)
	if err != nil {
		log.Fatal().Err(err).Msg("error creating client set")
	}

	// create the pod watcher
	vacuumListWatcher := cache.NewListWatchFromClient(clientset.VacuumV1alpha1().RESTClient(), "vacuums", v1.NamespaceAll, fields.Everything())
	cleaningListWatcher := cache.NewListWatchFromClient(clientset.VacuumV1alpha1().RESTClient(), "cleanings", v1.NamespaceAll, fields.Everything())

	// create the workqueue
	vacuumQueue := workqueue.NewRateLimitingQueue(workqueue.DefaultControllerRateLimiter())
	cleaningQueue := workqueue.NewRateLimitingQueue(workqueue.DefaultControllerRateLimiter())

	vacuumIndexer, vacuumInformer := cache.NewIndexerInformer(vacuumListWatcher, &vacuumv1alpha1.Vacuum{}, 0, cache.ResourceEventHandlerFuncs{
		AddFunc: func(obj interface{}) {
			key, err := cache.MetaNamespaceKeyFunc(obj)
			if err == nil {
				vacuumQueue.Add(key)
			}
		},
		UpdateFunc: func(old interface{}, new interface{}) {
			key, err := cache.MetaNamespaceKeyFunc(new)
			if err == nil {
				vacuumQueue.Add(key)
			}
		},
		DeleteFunc: func(obj interface{}) {
			// IndexerInformer uses a delta queue, therefore for deletes we have to use this
			// key function.
			key, err := cache.DeletionHandlingMetaNamespaceKeyFunc(obj)
			if err == nil {
				vacuumQueue.Add(key)
			}
		},
	}, cache.Indexers{})
	controllerIndex["vacuums"] = NewController(vacuumQueue, vacuumIndexer, vacuumInformer, "vacuums")

	cleaningIndexer, cleaningInformer := cache.NewIndexerInformer(cleaningListWatcher, &vacuumv1alpha1.Cleaning{}, 0, cache.ResourceEventHandlerFuncs{
		AddFunc: func(obj interface{}) {
			key, err := cache.MetaNamespaceKeyFunc(obj)
			if err == nil {
				cleaningQueue.Add(key)
			}
		},
		UpdateFunc: func(old interface{}, new interface{}) {
			key, err := cache.MetaNamespaceKeyFunc(new)
			if err == nil {
				cleaningQueue.Add(key)
			}
		},
		DeleteFunc: func(obj interface{}) {
			// IndexerInformer uses a delta queue, therefore for deletes we have to use this
			// key function.
			key, err := cache.DeletionHandlingMetaNamespaceKeyFunc(obj)
			if err == nil {
				cleaningQueue.Add(key)
			}
		},
	}, cache.Indexers{})
	controllerIndex["cleanings"] = NewController(cleaningQueue, cleaningIndexer, cleaningInformer, "cleanings")

	// setup http server
	m := mux.NewRouter()
	s := http.Server{
		Addr:    listen,
		Handler: m,
	}

	// setup static asset passthrough
	if dir := os.Getenv("ROCKLET_UI_STATIC_ASSETS"); dir != "" {
		log.Info().Str("wwwroot", dir).Msg("handling static assets")
		m.PathPrefix("/static/").Handler(http.FileServer(http.Dir(dir)))
		m.Path("/index.html").Handler(http.FileServer(http.Dir(dir)))
		m.Path("/service-worker.js").Handler(http.FileServer(http.Dir(dir)))
		m.Path("/favicon.ico").Handler(http.FileServer(http.Dir(dir)))
		m.Path("/index.html").Handler(http.FileServer(http.Dir(dir)))
	}

	m.HandleFunc("/apis/vacuum.swine.de/v1alpha1/{type}", handleList)
	m.HandleFunc("/apis/vacuum.swine.de/v1alpha1/namespaces/{namespace}/{type}/{name}", handleSingle)
	m.HandleFunc("/apis/vacuum.swine.de/v1alpha1/namespaces/{namespace}/{type}/{name}/map", handleMap)

	// websocket notifications
	m.HandleFunc("/ws/notify", handleNotify)

	l, err := net.Listen("tcp", s.Addr)
	if err != nil {
		log.Fatal().Err(err).Msg("error listening on tcp socket")
	}

	// Now let's start the controller
	stop := make(chan struct{})
	defer close(stop)
	go controllerIndex["vacuums"].Run(1, stop)
	go controllerIndex["cleanings"].Run(1, stop)
	go s.Serve(l)

	// Wait forever
	select {}
}

func handleList(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)

	var obj interface{}

	switch vars["type"] {
	case "vacuums":
		list := vacuumv1alpha1.VacuumList{}
		c := controllerIndex[vars["type"]]
		for _, elem := range c.indexer.List() {
			switch v := elem.(type) {
			case *vacuumv1alpha1.Vacuum:
				list.Items = append(list.Items, *v)
			default:
				continue
			}
		}
		obj = &list
	case "cleanings":
		list := vacuumv1alpha1.CleaningList{}
		c := controllerIndex[vars["type"]]
		for _, elem := range c.indexer.List() {
			switch v := elem.(type) {
			case *vacuumv1alpha1.Cleaning:
				smaller := v.DeepCopy()
				smaller.Status.Path = []vacuumv1alpha1.Position(nil)
				smaller.Status.Map = nil
				list.Items = append(list.Items, *smaller)
			default:
				continue
			}
		}
		obj = &list
	default:
		httpError(w, fmt.Sprintf("type %s not found", vars["type"]), 500)
	}
	b, err := json.Marshal(obj)
	if err != nil {
		httpError(w, err.Error(), 500)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(b)
}

func handleMap(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	c := controllerIndex[vars["type"]]

	item, exists, err := c.indexer.GetByKey(fmt.Sprintf("%s/%s", vars["namespace"], vars["name"]))
	if err != nil {
		httpError(w, err.Error(), 500)
		return
	}

	if !exists {
		httpError(w, "not found", 404)
		return
	}

	switch v := item.(type) {
	case *vacuumv1alpha1.Vacuum:
		w.Header().Set("Content-Type", "image/png")
		w.Write(v.Status.Map)
	case *vacuumv1alpha1.Cleaning:
		w.Header().Set("Content-Type", "image/png")
		w.Write(v.Status.Map.Data)
	default:
		httpError(w, "unsupported type", 500)
		return
	}
}

func handleSingle(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	c := controllerIndex[vars["type"]]

	item, exists, err := c.indexer.GetByKey(fmt.Sprintf("%s/%s", vars["namespace"], vars["name"]))
	if err != nil {
		httpError(w, err.Error(), 500)
		return
	}

	if !exists {
		httpError(w, "not found", 404)
		return
	}

	b, err := json.Marshal(item)
	if err != nil {
		httpError(w, err.Error(), 500)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(b)
}

func httpError(w http.ResponseWriter, err string, status int) {
	log.Warn().Int("status", status).Msg(err)
	http.Error(w, err, status)
}
