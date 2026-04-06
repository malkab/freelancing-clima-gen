/**
 *
 * Componente UX para seleccionar la variable a pintar en mapa.
 *
 */
export default class VariableSelectorComponent {

    /**
     *
     * @param {HTMLSelectElement|null} selectElement Elemento
     * select de variable.
     *
     */
    constructor(selectElement = null) {

        this.selectElement = selectElement;
        this.eventTarget = new EventTarget();
        this.selectedValue = selectElement?.value ?? "";
        this.options = [];

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
     * Carga opciones en el dropdown desde la respuesta de la API
     * de variables.
     *
     * @param {Array|Object} variablesList Listado de variables
     * recibido por API.
     * @param {string|null} preferredValue Valor preferido a
     * seleccionar.
     * @returns {{value: string, label: string}|null} Opción
     * seleccionada.
     *
     */
    setOptions(variablesList, preferredValue = null) {
        if (!this.selectElement) {
            return null;
        }

        const normalizedOptions = this.normalizeVariablesList(variablesList);
        this.options = normalizedOptions;

        this.selectElement.innerHTML = "";

        normalizedOptions.forEach((option) => {
            const optionElement = document.createElement("option");
            optionElement.value = option.value;
            optionElement.textContent = option.label;
            this.selectElement.appendChild(optionElement);
        });

        if (normalizedOptions.length === 0) {
            this.selectedValue = "";
            return null;
        }

        const defaultSelectedValue = this.getDefaultSelectedValue(normalizedOptions, preferredValue);
        this.selectElement.value = defaultSelectedValue;
        this.selectedValue = defaultSelectedValue;

        return this.options.find((option) => option.value === defaultSelectedValue) ?? null;
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
        const selectedOption = this.options.find((option) => option.value === this.selectedValue) ?? null;

        this.eventTarget.dispatchEvent(new CustomEvent("variableChanged", {
            detail: {
                value: this.selectedValue,
                label: event.target.options[event.target.selectedIndex]?.text ?? this.selectedValue,
                option: selectedOption,
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


    /**
     *
     * Normaliza la lista de variables recibida por la API para
     * el selector.
     *
     * @param {Array|Object} variablesList Listado de variables.
     * @returns {Array} Lista de opciones normalizadas.
     *
     */
    normalizeVariablesList(variablesList) {

        return variablesList
            .map((item) => {

                const value = item.variable_id;
                const label = item.name;
                const description_short = item.description_short;

                return {
                    value,
                    label,
                    description_short,
                };
            });

    }


    /**
     *
     * Devuelve el valor a seleccionar por defecto en el
     * dropdown.
     *
     * @param {Array} options Lista de las opciones.
     * @param {string} preferredValue Valor a buscar.
     * @returns {string} Valor a seleccionar por defecto.
     *
     */
    getDefaultSelectedValue(options, preferredValue) {
        if (typeof preferredValue === "string" && options.some((option) => option.value === preferredValue)) {
            return preferredValue;
        }

        if (typeof this.selectedValue === "string" && options.some((option) => option.value === this.selectedValue)) {
            return this.selectedValue;
        }

        return options[0].value;
    }

}
