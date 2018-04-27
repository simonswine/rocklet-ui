import './font_roboto.css';
import './font_material_icons.css';
import './material.teal-red.min.css';
import './main.css';

import { Vacuum } from './Vacuum.elm';
import registerServiceWorker from './registerServiceWorker';

Vacuum.embed(document.getElementById('root'));

registerServiceWorker();
