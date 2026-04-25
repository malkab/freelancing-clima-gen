/**
 *
 * Clase para la gestión de la leyenda.
 *
 */
export default class LegendComponent {

    /**
     *
     * Constructor.
     *
     * @param {HTMLElement} legendContainer Contenedor HTML para la leyenda.
     *
     */
    constructor(legendContainer = null) {

        this.legendContainer = legendContainer;

    }


    /**
     *
     * Renderiza una leyenda de gradiente horizontal basada en los stops de color.
     *
     * @param {{ value: number, color: string }[]} stops Stops de la leyenda.
     * @param {string} title Título de la leyenda.
     *
     */
    renderLegend(stops, title) {

        if (!this.legendContainer || stops.length === 0) {
            return;
        }

        const minValue = Math.min(...stops.map((stop) => stop.value));
        const maxValue = Math.max(...stops.map((stop) => stop.value));
        const range = Math.max(maxValue - minValue, 1);

        const gradient = stops
            .map((stop) => {
                const offset = ((stop.value - minValue) / range) * 100;
                return `${stop.color} ${offset.toFixed(2)}%`;
            })
            .join(", ");

        const ticks = stops
            .map((stop) => {
                const offset = ((stop.value - minValue) / range) * 100;
                return `<span class="map-legend-tick" style="left: ${offset.toFixed(2)}%">${stop.value}</span>`;
            })
            .join("");

        this.legendContainer.innerHTML = `
        <h4>${title}</h4>
        <div id="map-legend-bar" style="background: linear-gradient(to right, ${gradient});"></div>
        <div id="map-legend-scale">${ticks}</div>
        `;

    }


    /**
     *
     * Extrae los stops de la leyenda de la expresión
     * `fill-color` de un layer.
     *
     * En un estilo de MapLibre fill-color como este se define
     * como una expresión de interpolación, por ejemplo:
     *
     * "fill-color": [
     *      "interpolate", ["linear"],
     *      ["to-number", ["get", "field"]],
     *      34, "#2b83ba",
     *      40, "#abdda4",
     *      70, "#ffffbf",
     *      90, "#fdae61",
     *      128, "#d7191c"
     * ]
     *
     * @param {object} style Objeto de estilo de MapLibre.
     * @param {string} layerId La capa a inspeccionar.
     * @returns {{ value: number, color: string }[]} Stops
     * numéricos/colores extraídos.
     *
     */
    getLayerColorStops(style, layerId) {

        const layer = style?.layers?.find((entry) => entry.id === layerId);
        const fillColor = layer?.paint?.["fill-color"];

        if (!Array.isArray(fillColor) || fillColor[0] !== "interpolate") {
            return [];
        }

        const stops = [];

        for (let index = 3; index < fillColor.length; index += 2) {
            const value = Number(fillColor[index]);
            const color = fillColor[index + 1];

            if (!Number.isFinite(value) || typeof color !== "string") {
                continue;
            }

            stops.push({ value, color });
        }

        return stops;

    }
}
