
/**
 *
 * Clase encargada de gestionar las variables del mapa desde la
 * API.
 *
 * Tiene un evento llamado "variableLoaded" que se emite cuando
 * se han cargado los datos de la variable, con el detalle de las
 * capas a cargar.
 *
 */
export default class Variable {

    /**
     *
     * Constructor.
     *
     */
    constructor() {

        this.eventTarget = new EventTarget();

    }


    /**
     *
     * Devuelve las capas MapLibre de la variable para
     * inyectarlos en el mapa.
     *
     * @param {string} apiBaseUrl La URL de la API.
     * @param {string} territory El territorio para sobre el que
     * pedir la variable.
     * @param {string} variable El ID de la variable a pedir.
     * @returns {Promise<Object>} Los datos de la variable.
     *
     */
    async fetchVariable(apiBaseUrl, territory, variable) {

        const endpoint = `${apiBaseUrl}/carto/${territory}/${variable}`;

        const response = await fetch(endpoint, {
            method: "GET",
            headers: {
                "Accept": "application/json",
            },
        });

        if (!response.ok) {
            throw new Error(`Variable API request failed with ${response.status}`);
        }

        const out = await response.json();

        // Emitimos el evento de recepción de las capas.
        this.eventTarget.dispatchEvent(
            new CustomEvent("variableLoaded", {
                detail: { "layers": out }
            })
        );

        return out;

    }


    /**
     *
     * Recupera el listado de variables disponible para un
     * territorio.
     *
     * Endpoint: /api/v1/variable/{territory}
     *
     * @param {string} apiBaseUrl URL base de API.
     * @param {string} territory Territorio seleccionado.
     * @returns {Promise<Object|Array>} Listado de variables.
     */
    async fetchVariablesByTerritory(apiBaseUrl, territory) {

        const endpoint = `${apiBaseUrl}/variable/${territory}`;

        const response = await fetch(endpoint, {
            method: "GET",
            headers: {
                "Accept": "application/json",
            },
        });

        if (!response.ok) {
            throw new Error(`Variable list API request failed with ${response.status}`);
        }

        const out = await response.json();

        this.eventTarget.dispatchEvent(
            new CustomEvent("variableListLoaded", {
                detail: {
                    territory,
                    variables: out.rows,
                },
            })
        );

        return out.rows;

    }


    /**
     *
     * Subscriptor de eventos.
     *
     * @param {string} eventType El tipo de evento a escuchar.
     * @param {Function} listener La función a ejecutar cuando se
     * emita el evento.
     *
     */
    on(eventType, listener) {
        this.eventTarget.addEventListener(eventType, listener);
    }

}
