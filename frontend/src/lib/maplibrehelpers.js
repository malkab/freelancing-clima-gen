/**
 *
 * Funciones de ayuda para MapLibre.
 *
 */
export default class MapLibreHelpers {

    /**
     *
     * Añade una o varias capas antes de una capa existente. Se
     * añaden en el orden que aparezcan en layersDef, de modo que
     * la primera capa es la que queda por debajo de las demás.
     *
     * @param {Object} map Instancia de MapLibre.
     * @param {Object|Object[]} layersDef Definición de capa o
     * lista de capas.
     * @param {string} beforeLayerId ID de la capa de referencia
     * ante la que añadir las capas.
     * @returns {string[]} IDs de capas añadidas.
     */
    addLayersBefore(map, layersDef, beforeLayerId = null) {

        const layers = Array.isArray(layersDef) ? layersDef : [layersDef];
        const insertedLayerIds = [];

        layers.forEach((layerDef) => {

            if (!layerDef || typeof layerDef !== "object" || typeof layerDef.id !== "string") {
                return;
            }

            // Borrar antes de añadir.
            if (map.getLayer(layerDef.id)) {
                map.removeLayer(layerDef.id);
            }

            map.addLayer(layerDef, beforeLayerId);
            insertedLayerIds.push(layerDef.id);
        });

        return insertedLayerIds;
    }


    /**
     *
     * Elimina del estilo actual del mapa todas las capas cuyo
     * metadata.group sea "group".
     *
     * @param {Object} map Instancia de MapLibre.
     * @param {string} group El valor del metadata.group a eliminar.
     * @returns {string[]} IDs de capas eliminadas.
     *
     */
    clearLayersByMetadataGroup(map, group) {

        const style = map.getStyle();

        const layers = Array.isArray(style?.layers) ? style.layers : [];

        const variableLayers = layers
            .filter((layer) => layer?.metadata?.group === group)
            .map((layer) => layer.id)
            .filter((layerId) => typeof layerId === "string");

        for (let index = variableLayers.length - 1; index >= 0; index -= 1) {
            const layerId = variableLayers[index];
            if (map.getLayer(layerId)) {
                map.removeLayer(layerId);
            }
        }

        return variableLayers;

    }


    /**
     *
     * Añade al maxBounds de un mapa un gutter (margen) en grados EPSG:4326 para encajar la visualización inicial del contexto de datos.
     *
     * @param {Object} bounds El maxBounds de MapLibre, en EPSG:4326.
     * @param {number} gutter Grados EPSG:4326 a aplicar.
     * @returns {Object} Los bounds modificados.
     */
    addBoundGutter(bounds, gutter) {
        return ([
            [
                bounds[0][0] - gutter,
                bounds[0][1] - gutter
            ],
            [
                bounds[1][0] + gutter,
                bounds[1][1] + gutter
            ]
        ]);
    }
}
