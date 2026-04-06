import RuntimeConfig from "./runtimeconfig";

/**
 *
 * Funciones de ayuda para integrar Martin en el frontend.
 *
 */
export default class Martin {

    /**
     *
     * Traduce las URLs de los tiles en el estilo del mapa,
     * reemplazando el marcador "martinUrlPlaceHolder" por la URL
     * base de Martin "martinUrl". Devuelve un clon del estilo de
     * mapa con la transformación hecha.
     *
     * @param {string} martinUrlPlaceHolder El marcador que se
     * busca en las URLs de los tiles para reemplazar.
     * @param {string} martinUrl La URL base de Martin.
     * @param {*} mapJson El estilo del mapa en formato JSON.
     * @returns {*} El estilo del mapa con las URLs de los tiles
     * actualizadas.
     */
    withRuntimeApiUrls(martinUrlPlaceHolder, martinUrl, mapJson) {

        // Clonamos el estilo para no mutar el original.
        var nextStyle = structuredClone(mapJson);

        // Exploramos los sources del estilo y reemplazamos las URLs de los tiles que contienen el marcador de Martin por la URL base de Martin configurada en runtimeConfig.
        Object.values(nextStyle.sources ?? {}).forEach((source) => {
            if (!Array.isArray(source.tiles)) {
                return;
            }

            source.tiles = source.tiles.map((tileUrl) =>
                this.replaceMartinBaseUrl(
                    martinUrlPlaceHolder,
                    tileUrl,
                    martinUrl
                ));
        });

        return nextStyle;

    }


    /**
     *
     * Reemplaza las URLs de los tiles que contienen
     * "martinPlaceHolder" por la URL base de Martin configurada
     * en runtimeConfig.
     *
     * @param {string} martinPlaceHolder El marcador que se busca
     * en las URLs de los tiles para reemplazar.
     * @param {string} tileUrl La URL del tile que se va a
     * procesar.
     * @param {string} martinBaseUrl La URL base de Martin.
     * @returns {string} La URL del tile con el marcador de
     * Martin reemplazado por la URL base de Martin.
     */
    replaceMartinBaseUrl(martinPlaceHolder, tileUrl, martinBaseUrl) {

        if (typeof tileUrl !== "string") {
            return tileUrl;
        }

        const markerIndex = tileUrl.indexOf(martinPlaceHolder);

        if (markerIndex === -1) {
            return tileUrl;
        }

        const suffix = tileUrl.slice(
            markerIndex + martinPlaceHolder.length);

        return `${martinBaseUrl}${suffix}`;

    }

}