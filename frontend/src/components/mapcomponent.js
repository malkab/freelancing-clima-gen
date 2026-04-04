/**
 *
 * Funcionalidad relacionada con el mapa.
 *
 */
export default class MapComponent {

    /**
     *
     * Miembros públicos.
     *
     */
    map;


    /**
     *
     * Constructor.
     *
     */
    constructor() {

        this.map = null;
        this.eventTarget = new EventTarget();

    }


    /**
     *
     * Inicialización del mapa.
     *
     * @param {Object} options Opciones de configuración MapLibre
     * del mapa.
     *
     */
    initMap(mapOptions) {

        this.map = new maplibregl.Map(mapOptions);

        // Evento onload.
        this.map.on("load", () => {

            // Atrapamos eventos de movimiento del ratón.
            this.map.on("mousemove", (event) => {
                this.eventTarget.dispatchEvent(
                    new CustomEvent("mouseMove", {
                        detail: { map: this.map, mouseevent: event }
                }));
            });

            // Emitimos un primer evento de cambio de mapa.
            this.eventTarget.dispatchEvent(
                new CustomEvent("mapUpdated", {
                    detail: this.map
                })
            );
        });
    }


    /**
     *
     * Subscriptores de eventos.
     *
     */
    onMapUpdated(listener) {
        this.eventTarget.addEventListener("mapUpdated", listener);
    }

    onMouseMove(listener) {
        this.eventTarget.addEventListener("mouseMove", listener);
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
