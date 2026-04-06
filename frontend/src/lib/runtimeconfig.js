/**
 *
 * Clase con una serie de funcionalidades para gestionar
 * configuraciones en tiempo de ejecución.
 *
 * Resuelve la configuración en tiempo de ejecución a partir de
 * un archivo JSON.
 *
 */

/**
 *
 * Configuración por defecto, usada si no se puede cargar la
 * configuración externa.
 *
 */
const DEFAULT_RUNTIME_CONFIG = {
    "martinBaseUrl": "http://localhost:5173/martin",
    "apiBaseUrl": "http://localhost:8000/api/v1/",
    "selectedTerritory": "autonomia",
    "selectedVariable": "indice_clima_gen_sin_cambio_climatico",
    "maxBounds": [ [-20, 27], [6, 44] ],
    "center": [-6.75, 36],
    "zoom": 4
};

/**
 *
 * Clase encargada de cargar la configuración de runtime desde un
 * archivo JSON externo, con una configuración por defecto como
 * fallback.
 *
 */
export default class RuntimeConfig {

    /**
     *
     * Intenta cargar la configuración de
     * public/runtime-config.json. Si falla, se usa la
     * configuración por defecto.
     *
     * @returns {Promise<{martinBaseUrl: string, apiBaseUrl:
     * string}>} La configuración de runtime.
     *
     */
    async loadRuntimeConfig() {
        try {
            const response = await fetch("/runtime-config.json", {
                cache: "no-store",
            });

            if (!response.ok) {
                throw new Error(`Runtime config request failed with ${response.status}`);
            }

            const loadedConfig = await response.json();

            return {
                ...DEFAULT_RUNTIME_CONFIG,
                ...loadedConfig,
                martinBaseUrl: this.normalizeBaseUrl(loadedConfig.martinBaseUrl),
                apiBaseUrl: this.normalizeBaseUrl(loadedConfig.apiBaseUrl)
            };

        } catch (error) {

            console.warn("Using default runtime config", error);
            return {
                ...DEFAULT_RUNTIME_CONFIG,
                martinBaseUrl: this.normalizeBaseUrl(DEFAULT_RUNTIME_CONFIG.martinBaseUrl),
                apiBaseUrl: this.normalizeBaseUrl(DEFAULT_RUNTIME_CONFIG.apiBaseUrl)
            };

        }
    }

    /**
     *
     * Devuelve la URL sin el "/" final.
     *
     * @param {string} url La URL a normalizar.
     * @returns {string} La URL normalizada.
     *
     */
    normalizeBaseUrl(url) {
        return url.endsWith("/") ? url.slice(0, -1) : url;
    }

}
