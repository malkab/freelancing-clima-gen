/**
 *
 * Splash screen modal que bloquea la interacción con el mapa
 * hasta que el usuario lo cierra.
 *
 */
export default class SplashScreenComponent {

    /**
     *
     * @param {HTMLElement|null} container Contenedor de la splash screen.
     * @param {HTMLElement|null} content Contenedor del mensaje HTML.
     * @param {HTMLButtonElement|null} closeButton Botón de cierre.
     *
     */
    constructor(container = null, content = null, closeButton = null) {
        this.container = container;
        this.content = content;
        this.closeButton = closeButton;
        this.map = null;
    }


    /**
     *
     * Inicializa eventos del componente.
     *
     */
    init() {
        if (this.closeButton) {
            this.closeButton.addEventListener("click", () => this.close());
        }
    }


    /**
     *
     * Asocia la instancia de mapa para bloquear/desbloquear interacción.
     *
     * @param {Object} map Instancia de MapLibre.
     */
    attachMap(map) {
        this.map = map;
    }


    /**
     *
     * Abre la splash y opcionalmente actualiza el mensaje HTML.
     *
     * @param {string|null} messageHtml Mensaje HTML a mostrar.
     */
    open(messageHtml = null) {
        if (!this.container) {
            return;
        }

        // if (this.content && typeof messageHtml === "string") {
        //     this.content.innerHTML = messageHtml;
        // }

        // this.container.style.display = "flex";
        this.lockMapInteraction();
    }


    /**
     *
     * Cierra la splash y habilita interacción de mapa.
     *
     */
    close() {
        if (!this.container) {
            return;
        }

        this.container.style.display = "none";
        this.unlockMapInteraction();
    }


    lockMapInteraction() {
        if (!this.map) {
            return;
        }

        this.map.dragPan?.disable();
        this.map.scrollZoom?.disable();
        this.map.boxZoom?.disable();
        this.map.dragRotate?.disable();
        this.map.keyboard?.disable();
        this.map.doubleClickZoom?.disable();
        this.map.touchZoomRotate?.disable();
    }


    unlockMapInteraction() {
        if (!this.map) {
            return;
        }

        this.map.dragPan?.enable();
        this.map.scrollZoom?.enable();
        this.map.boxZoom?.enable();
        this.map.dragRotate?.disable();
        this.map.keyboard?.enable();
        this.map.doubleClickZoom?.enable();
        this.map.touchZoomRotate?.enable();
        this.map.touchZoomRotate?.disableRotation();
    }
}
