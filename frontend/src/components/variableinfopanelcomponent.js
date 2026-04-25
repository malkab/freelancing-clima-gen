/**
 *
 * Panel lateral para mostrar metadatos de la variable seleccionada.
 *
 */
export default class VariableInfoPanelComponent {

    /**
     *
     * @param {HTMLElement|null} container Contenedor del panel.
     */
    constructor(container = null) {
        this.container = container;
    }


    /**
     *
     * Refresca el panel con la variable activa.
     *
     * @param {Object|null} variableOption Opcion seleccionada en el selector de variables.
     */
    render(variableOption) {
        if (!this.container) {
            return;
        }

        if (!variableOption) {
            this.container.innerHTML = "";
            this.container.style.display = "none";
            return;
        }

        const title = variableOption.label ?? variableOption.value ?? "Variable";
        const descriptionShort =
            variableOption.description_short
            ?? variableOption.descriptionShort
            ?? "Sin descripcion corta disponible.";

        this.container.innerHTML = `
            <h2>${title}</h2>
            <div id="variable-description">${descriptionShort}</div>
        `;

        this.container.style.display = "block";
    }
}
