const boundGutter = 13;

const map = new maplibregl.Map({
  container: "map",
  style: "https://demotiles.maplibre.org/style.json",
  center: [-6.75, 36],
  zoom: 4,
  maxBounds: [
    [-20-boundGutter, 27-boundGutter],   // southwest [lng, lat]
    [6+boundGutter, 44+boundGutter],   // northeast [lng, lat]
  ],
});

map.addControl(new maplibregl.NavigationControl(), "top-right");
