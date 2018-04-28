FROM node:9.11.1

WORKDIR /app/

RUN npm install create-elm-app@1.10.4
ENV PATH=/app/node_modules/.bin:$PATH

COPY elm-package.json .
RUN elm-app install -y

COPY public ./public
COPY src ./src
RUN elm-app build


FROM golang:1.10.1

RUN curl -Lo /usr/local/bin/dep https://github.com/golang/dep/releases/download/v0.4.1/dep-linux-amd64 && \
    echo "31144e465e52ffbc0035248a10ddea61a09bf28b00784fd3fdd9882c8cbb2315  /usr/local/bin/dep" | sha256sum -c && \
    chmod +x /usr/local/bin/dep

WORKDIR  /go/src/github.com/simonswine/rocklet-ui

COPY Gopkg.toml .
COPY Gopkg.lock .

RUN dep ensure -vendor-only

ADD *.go ./
RUN  CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o rocklet-ui .

FROM alpine:3.7

RUN apk add --update ca-certificates && update-ca-certificates

ENV ROCKLET_UI_STATIC_ASSETS=/var/www
EXPOSE 8812

COPY --from=0 /app/build /var/www
COPY --from=1 /go/src/github.com/simonswine/rocklet-ui/rocklet-ui /usr/local/bin/rocklet-ui

CMD ["/usr/local/bin/rocklet-ui"]
