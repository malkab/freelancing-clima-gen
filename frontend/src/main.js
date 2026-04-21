/**
 *
 * Script principal.
 *
 */

import { Map, NavigationControl } from "maplibre-gl";
import mapStyle from "./assets/map.json";
import MapLibreHelpers from "./lib/maplibrehelpers.js";
import LegendComponent from "./components/legendcomponent.js";
import HoverComponent from "./components/hovercomponent.js";
import RuntimeConfig from "./lib/runtimeconfig.js";
import Martin from "./lib/martin.js";
import Variable from "./lib/variable.js";
import TerritorySelectorComponent from "./components/territoryselectorcomponent.js";
import VariableSelectorComponent from "./components/variableselectorcomponent.js";
import VariableInfoPanelComponent from "./components/variableinfopanelcomponent.js";
import SplashScreenComponent from "./components/splashscreencomponent.js";


/**
 *
 * Enganches DOM.
 *
 */
// Posicionamiento de la leyenda.
const legendContainer = document.getElementById("map-legend");

// Posicionamiento de la info de hover.
const hoverInfo = document.getElementById("map-hover-info");

// Selector de territorio.
const territorySelect = document.getElementById("territory-select");

// Selector de variable.
const variableSelect = document.getElementById("variable-select");

// Panel lateral de información de variable.
const variableInfoPanel = document.getElementById("variable-info-panel");

// Splash screen.
const splashScreen = document.getElementById("splash-screen");
const splashContent = document.getElementById("splash-content");
const splashClose = document.getElementById("splash-close");


/**
 *
 * Declaración de componentes y clases globales.
 *
 */
// Configuración de runtime.
const runtimeConfigInstance = new RuntimeConfig();

// Convierte el mapa MapLibre para enganchar a la config de
// Martin.
const martin = new Martin();

// Helpers de MapLibre.
const mapLibreHelpers = new MapLibreHelpers();

// Componente de leyenda.
const legendComponent = new LegendComponent(legendContainer);

// Componente de hover.
const hoverComponent = new HoverComponent(hoverInfo);

// Control de la API de variables.
const variable = new Variable();

// Componente selector de territorio.
const territorySelectorComponent = new TerritorySelectorComponent(territorySelect);

// Componente selector de variable.
const variableSelectorComponent = new VariableSelectorComponent(variableSelect);

// Componente panel de variable.
const variableInfoPanelComponent = new VariableInfoPanelComponent(variableInfoPanel);

// Componente splash screen.
const splashScreenComponent = new SplashScreenComponent(
    splashScreen,
    splashContent,
    splashClose,
);

// Almacen de variables globales.
let gs = {
    // Mapa MapLibre.
    map: null,
    // Listado actual de variables para el territorio
    // seleccionado.
    selectedTerritoryVariables: [],
    // Titulo actual de la leyenda.
    currentLegendTitle: null,
    // Variable seleccionada actual.
    selectedVariable: null,
 };


/**
 *
 * Inicialización del mapa, que es lo que desencadena el resto de
 * inicializaciones y eventos.
 *
 */

bootstrap();

async function bootstrap() {

    /**
     *
     * Configuración.
     *
     */
    // Intenta leer la configuración de entorno.
    const runtimeConfig = await runtimeConfigInstance.loadRuntimeConfig();

    // Inyectar la configuración en el store global para que esté disponible.
    gs = { ...gs, ...runtimeConfig };

    // Inicialización de splash con mensaje HTML.
    splashScreenComponent.init();
    splashScreenComponent.open(`
        <p>Esta aplicación muestra las variables territoriales utilizadas en el estudio, así como sus resultadaos, sobre un mapa interactivo.</p>
        <p>Seleccione en los desplegables el nivel de desagregación territorial y la variable que desee visualizar.</p>
    `);

    // Inicializamos el selector territorial con el valor por
    // defecto.
    territorySelect.value = runtimeConfig.selectedTerritory;
    territorySelectorComponent.selectedValue = runtimeConfig.selectedTerritory;

    territorySelectorComponent.init();

    // Cargamos el listado de variables para el territorio
    // seleccionado.
    gs.selectedTerritoryVariables =
        await variable.fetchVariablesByTerritory(
            runtimeConfig.apiBaseUrl,
            runtimeConfig.selectedTerritory,
        );

    // Inicializamos el selector de variable con el valor por
    // defecto.
    variableSelectorComponent.init();

    // Rellenamos el selector de variable con las variables del
    // territorio.
    const initialVariableOption = variableSelectorComponent.setOptions(
        gs.selectedTerritoryVariables,
        runtimeConfig.selectedVariable,
    );

    // Establecemos la variable seleccionada por defecto y su
    // nombre para la leyenda.
    if (initialVariableOption) {
        runtimeConfig.selectedVariable = initialVariableOption.value;
        gs.currentLegendTitle = initialVariableOption.label;
        gs.selectedVariable = initialVariableOption;
        variableInfoPanelComponent.render(gs.selectedVariable);
    } else {
        gs.currentLegendTitle = runtimeConfig.selectedVariable;
        gs.selectedVariable = null;
        variableInfoPanelComponent.render(null);
    }

    // Configuramos el estilo de mapa con las URLs de Martin.
    const runtimeMapStyle =
        martin.withRuntimeApiUrls("/martin",
            runtimeConfig.martinBaseUrl, mapStyle);

    /**
     *
     * Configuración del mapa.
     *
     */
    // Alteramos el maxBounds para que quepa bien en el mapa de
    // salida.
    let maxBounds =
        mapLibreHelpers.addBoundGutter(
            runtimeConfig.maxBounds,
            runtimeConfig.boundGutter
        );

    // Opciones de mapa.
    gs.map = new Map({
        container: "map",
        center: runtimeConfig.center,
        zoom: runtimeConfig.zoom,
        maxBounds: maxBounds,
        attributionControl: {
            compact: true,
            customAttribution: "Proyecto Clima-Gen | MapLibre"
        }
    });

    // Vinculamos la splash al mapa para bloquear interacción hasta cierre.
    splashScreenComponent.attachMap(gs.map);
    splashScreenComponent.lockMapInteraction();

    // Evento de carga del mapa.
    gs.map.on("load", async (event) => {

        // Cogemos la variable inicial para cargar el mapa con
        // datos.
        await variable.fetchVariable(
                runtimeConfig.apiBaseUrl,
                runtimeConfig.selectedTerritory,
                runtimeConfig.selectedVariable
            );

    });

    // Esto se dispara cada vez que pasa algo en el mapa y este
    // acaba de procesar lo que sea.
    gs.map.on("idle", (event) => {

        // Stops de color de variable_area.
        let stops = legendComponent.getLayerColorStops(
            gs.map.getStyle(),
            "variable_area"
        );

        // Renderizamos leyenda.
        legendComponent.renderLegend(stops, gs.currentLegendTitle);

    });

    // Deshabilitamos rotación con gestos táctiles.
    gs.map.touchZoomRotate.disableRotation();

    // Añadimos controles de navegación.
    gs.map.addControl(new NavigationControl(), "top-right");

    // Evento de mapa de movimiento de ratón, desencadena el
    // hover.
    gs.map.on("mousemove", (event) => {

        hoverComponent.handleMouseMove(
            event,
            "variable_area",
            runtimeConfig.selectedVariable,
            gs.currentLegendTitle,
        );

    });

    gs.map.on("mouseleave", () => {
        hoverComponent.handleMouseLeave(gs.map);
    });

    // Evento de carga de variable.
    variable.on("variableLoaded", (event) => {

        const layers = event.detail.layers;

        // Cargamos las capas de variable en el mapa.
        mapLibreHelpers.addLayersBefore(gs.map, [
            layers.variable_area,
            layers.variable_borde,
            layers.variable_centroid
        ], "variables");

    });

    // Cambio en el selector de territorio.
    territorySelectorComponent.on("territoryChanged", async (event) => {

        const selectedTerritory = event.detail.value;

        runtimeConfig.selectedTerritory = selectedTerritory;

        gs.selectedTerritoryVariables =
            await variable.fetchVariablesByTerritory(
                runtimeConfig.apiBaseUrl,
                selectedTerritory,
            );

        const selectedVariableOption = variableSelectorComponent.setOptions(
            gs.selectedTerritoryVariables,
            runtimeConfig.selectedVariable,
        );

        if (selectedVariableOption) {
            runtimeConfig.selectedVariable = selectedVariableOption.value;
            gs.currentLegendTitle = selectedVariableOption.label;
            gs.selectedVariable = selectedVariableOption;
            variableInfoPanelComponent.render(gs.selectedVariable);
        } else {
            gs.selectedVariable = null;
            variableInfoPanelComponent.render(null);
        }

        await variable.fetchVariable(
            runtimeConfig.apiBaseUrl,
            selectedTerritory,
            runtimeConfig.selectedVariable,
        );

    });

    // Cambio en el selector de variable.
    variableSelectorComponent.on("variableChanged", async (event) => {
        const selectedVariable = event.detail.value;
        const selectedVariableLabel = event.detail.label;
        const selectedVariableOption = event.detail.option ?? null;

        runtimeConfig.selectedVariable = selectedVariable;
        gs.currentLegendTitle = selectedVariableLabel;
        gs.selectedVariable = selectedVariableOption;
        variableInfoPanelComponent.render(gs.selectedVariable);

        mapLibreHelpers.clearLayersByMetadataGroup(gs.map, "variable");

        await variable.fetchVariable(
            runtimeConfig.apiBaseUrl,
            runtimeConfig.selectedTerritory,
            selectedVariable,
        );
    });

    // Inicializamos el mapa finalmente para que todo se
    // desencadene.
    gs.map.setStyle(runtimeMapStyle);

}
