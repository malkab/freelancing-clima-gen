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
     * Refresco del hover al mover el ratón sobre el mapa.
     *
     * @param {Event} event El evento de movimiento del ratón
     * emitido por MapLibre.
     * @param {string} layerId La layer a la que prestar atención
     * para mostrar información de hover.
     * @param {number} maxHoveredFeatures Número máximo de
     * features a mostrar en el hover.
     *
     */

    handleMouseMove(event, layerId, selectedVariable, selectedVariableLabel, maxHoveredFeatures = 1) {

        // El mapa que viene en el evento.
        var map = event.target;

        // Consultamos las features bajo el cursor, limitándonos
        // a la capa de interés.
        const features = map.queryRenderedFeatures(event.point, {
            layers: [layerId],
        });

        // No hay nada.
        if (features.length === 0) {
            map.getCanvas().style.cursor = "crosshair";
            this.hide();
            return;
        }

        // Cambiamos el cursor para indicar que hay algo
        // interactuable.
        map.getCanvas().style.cursor = "pointer";

        const selectedFeature = features.slice(0, maxHoveredFeatures)[0];
        const variableKey = selectedVariable ?? "value";
        const variableLabel = selectedVariableLabel ?? variableKey;
        const variableValue = selectedFeature?.properties?.[variableKey];
        const nameUnit =
            selectedFeature?.properties?.nameunit
            ?? selectedFeature?.properties?.NAMEUNIT
            ?? selectedFeature?.properties?.name
            ?? "-";

        this.hoverInfoContainer.textContent = `${nameUnit}: ${this.formatValue(variableValue)}`;
        this.show();
        this.reposition(event.point, map);
    }


    handleMouseLeave(map) {
        map.getCanvas().style.cursor = "";
        this.hide();
    }


    reposition(point, map) {
        if (!this.hoverInfoContainer) {
            return;
        }

        const spacing = 14;
        this.hoverInfoContainer.style.left = `${point.x + spacing}px`;
        this.hoverInfoContainer.style.top = `${point.y + spacing}px`;

        const tooltipRect = this.hoverInfoContainer.getBoundingClientRect();
        const mapWidth = map.getContainer().clientWidth;
        const mapHeight = map.getContainer().clientHeight;

        let nextLeft = point.x + spacing;
        let nextTop = point.y + spacing;

        if (nextLeft + tooltipRect.width > mapWidth - spacing) {
            nextLeft = point.x - tooltipRect.width - spacing;
        }

        if (nextTop + tooltipRect.height > mapHeight - spacing) {
            nextTop = point.y - tooltipRect.height - spacing;
        }

        this.hoverInfoContainer.style.left = `${Math.max(spacing, nextLeft)}px`;
        this.hoverInfoContainer.style.top = `${Math.max(spacing, nextTop)}px`;
    }


    formatValue(value) {
        if (value === null || value === undefined || value === "") {
            return "-";
        }

        const asNumber = Number(value);
        if (Number.isFinite(asNumber)) {
            return asNumber.toLocaleString("es-ES", { maximumFractionDigits: 3 });
        }

        return String(value);
    }


    show() {
        if (this.hoverInfoContainer) {
            this.hoverInfoContainer.style.display = "block";
        }
    }


    hide() {
        if (this.hoverInfoContainer) {
            this.hoverInfoContainer.style.display = "none";
        }
    }

}
