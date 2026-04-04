/**
 *
 * Funcionalidad del hover sobre el mapa.
 *
 */
export default class HoverComponent {

    /**
     *
     * Constructor.
     *
     * @param {HTMLElement} hoverInfoContainer Contenedor para mostrar información del hover.
     *
     */
    constructor(hoverInfoContainer = null) {

        this.hoverInfoContainer = hoverInfoContainer;

    }


    /**
     *
     * Subscripciones a eventos de la aplicación.
     *
     * @param {MapComponent} mapComponent Map component emitter.
     *
     */
    watchEvents(mapComponent) {

        // Escuchamos los movimientos del ratón sobre el mapa.
        mapComponent.onMouseMove((event) =>
            this.handleMouseMove(event, "variable_area"));

    }


    /**
     *
     * Refresco del hover al mover el ratón sobre el mapa.
     *
     * @param {Event} event El evento de movimiento del ratón emitido por MapLibre.
     * @param {string} layerId La layer a la que prestar atención para mostrar información de hover.
     * @param {number} maxHoveredFeatures Número máximo de features a mostrar en el hover.
     *
     */

    handleMouseMove(event, layerId, maxHoveredFeatures = 1) {

        // Extraemos la información relevante del evento: el de movimiento del ratón y el propio mapa.
        var mouseEvent = event.detail.mouseevent;
        var map = event.detail.map;

        // Coordenadas
        const { lng, lat } = mouseEvent.lngLat;

        // Consultamos las features bajo el cursor, limitándonos a la capa de interés.
        const features = map.queryRenderedFeatures(mouseEvent.point, {
            layers: [layerId],
        });

        // No hay nada.
        if (features.length === 0) {
            map.getCanvas().style.cursor = "crosshair";
            this.hoverInfoContainer.textContent = `Lon: ${lng.toFixed(4)} | Lat: ${lat.toFixed(4)}\nNo geometry under cursor`;
            return;
        }

        // Cambiamos el cursor para indicar que hay algo interactuable.
        map.getCanvas().style.cursor = "pointer";

        // Preparamos la información de las features para mostrar en el hover, limitándonos al número máximo configurado.
        const featurePayload = features.slice(0, maxHoveredFeatures).map((feature) => ({
            id: feature.id ?? null,
            layer: feature.layer.id,
            source: feature.source,
            sourceLayer: feature.sourceLayer ?? null,
            geometryType: feature.geometry?.type ?? null,
            properties: feature.properties,
        }));

        // Actualizamos el contenido del hover con la información de las coordenadas y las features encontradas bajo el cursor.
        this.hoverInfoContainer.textContent = JSON.stringify(
            {
                coordinates: {
                    lon: Number(lng.toFixed(6)),
                    lat: Number(lat.toFixed(6)),
                },
                matchedFeatures: features.length,
                features: featurePayload,
            },
            null,
            2,
        );
    }

}