import mapStyle from "./assets/map.json";
import MapComponent from "./components/mapcomponent.js";
import LegendComponent from "./components/legendcomponent.js";
import HoverComponent from "./components/hovercomponent.js";


/**
 *
 * Enganches DOM.
 *
 */
// Posicionamiento de la leyenda.
const legendContainer = document.getElementById("map-legend");
const hoverInfo = document.getElementById("map-hover-info");


/**
 *
 * Declaración de componentes.
 *
 */
// Componente mapa.
const mapComponent = new MapComponent();

// Componente de leyenda.
const legendComponent = new LegendComponent(legendContainer);

// Componente de hover.
const hoverComponent = new HoverComponent(hoverInfo);


/**
 *
 * Configuración de la leyenda (depende del mapa).
 *
 */
legendComponent.watchEvents(mapComponent);


/**
 *
 * Configuración del hover (depende del mapa).
 *
 */
hoverComponent.watchEvents(mapComponent);


/**
 *
 * Inicialización del mapa.
 *
 */

// Bounds para península y Canarias.
var maxBounds =  [
    [-20, 27],
    [6, 44],
]

// Lo alteramos para que quepa bien en el mapa de salida.
maxBounds = mapComponent.addBoundGutter(maxBounds, 10.5);

// Opciones de mapa.
var mapOptions = {
    container: "map",
    style: mapStyle,
    center: [-6.75, 36],
    zoom: 4,
    maxBounds: maxBounds
};

// Inicializamos el mapa.
mapComponent.initMap(mapOptions);

// Deshabilitamos rotación con gestos táctiles.
mapComponent.map.touchZoomRotate.disableRotation();

// Añadimos controles de navegación.
mapComponent.map.addControl(new maplibregl.NavigationControl(), "top-right");
