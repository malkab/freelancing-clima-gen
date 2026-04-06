/**
 *
 * Componente UX para seleccionar el nivel territorial.
 *
 */
export default class TerritorySelectorComponent {

    /**
     *
     * @param {HTMLSelectElement|null} selectElement Elemento
     * select del territorio.
     *
     */
    constructor(selectElement = null) {
        this.selectElement = selectElement;
        this.eventTarget = new EventTarget();
        this.selectedValue = selectElement?.value ?? "autonomia";
    }


    /**
     *
     * Inicializa listeners DOM.
     *
     */
    init() {
        if (!this.selectElement) {
            return;
        }

        this.selectElement.addEventListener("change", (event) => {
            this.handleSelectionChange(event);
        });
    }


    /**
     *
     * Gestiona el cambio de valor del dropdown y emite un evento
     * de dominio para el resto de la app.
     *
     * @param {Event} event Evento change del select.
     */
    handleSelectionChange(event) {

        const nextValue = event?.target?.value;

        if (typeof nextValue !== "string" || nextValue.length === 0) {
            return;
        }

        this.selectedValue = nextValue;

        this.eventTarget.dispatchEvent(new CustomEvent("territoryChanged", {
            detail: {
                value: this.selectedValue,
                label: event.target.options[event.target.selectedIndex]?.text ?? this.selectedValue,
            },
        }));

    }


    /**
     *
     * Subscriptor de eventos del componente.
     *
     * @param {string} eventType Tipo de evento.
     * @param {Function} listener Callback.
     */
    on(eventType, listener) {
        this.eventTarget.addEventListener(eventType, listener);
    }

}
