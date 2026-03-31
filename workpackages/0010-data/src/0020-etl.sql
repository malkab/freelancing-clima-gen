/*

    Compone las tablas de unidades territoriales finales con
    todos los datos.

*/

begin;

-- Esquema de trabajo
drop schema if exists temp_etl cascade;

create schema if not exists temp_etl;

/*

    Tablas de geometrías.

*/
-- Geometrías de las autonomías peninsulares y canarias, unidas
-- en una sola tabla, con precisión reducida y transformadas a
-- Web Mercator.
create table temp_etl.autonomia_geom as
select
    substr(natcode, 3, 2) as unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,
    st_setsrid(st_reduceprecision(st_makevalid(st_transform(geom, 3857)), 1), 3857) as geom
from raw.autonomias_peninbal

union

select
    substr(natcode, 3, 2) as unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,
    st_setsrid(st_reduceprecision(st_makevalid(st_transform(geom, 3857)), 1), 3857) as geom
from raw.autonomias_regcan;

alter table temp_etl.autonomia_geom
add constraint pk_autonomia_geom_gid
primary key (unidad_territorial_id);


-- Geometrías de las provincias peninsulares y canarias, unidas
-- en una sola tabla, con precisión reducida y transformadas a
-- Web Mercator.
create table temp_etl.provincia_geom as
select
    substr(natcode, 5, 2) as unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,
    st_setsrid(st_reduceprecision(st_makevalid(st_transform(geom, 3857)), 1), 3857) as geom
from raw.provincias_peninbal

union

select
    substr(natcode, 5, 2) as unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,
    st_setsrid(st_reduceprecision(st_makevalid(st_transform(geom, 3857)), 1), 3857) as geom
from raw.provincias_regcan;

alter table temp_etl.provincia_geom
add constraint pk_provincia_geom_gid
primary key (unidad_territorial_id);


-- Geometrías de las municipios peninsulares y canarias, unidas
-- en una sola tabla, con precisión reducida y transformadas a
-- Web Mercator.
create table temp_etl.municipio_geom as
select
    substr(natcode, 7, 5) as unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,
    st_setsrid(st_reduceprecision(st_makevalid(st_transform(geom, 3857)), 1), 3857) as geom
from raw.municipios_peninbal

union

select
    substr(natcode, 7, 5) as unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,
    st_setsrid(st_reduceprecision(st_makevalid(st_transform(geom, 3857)), 1), 3857) as geom
from raw.municipios_regcan;

alter table temp_etl.municipio_geom
add constraint pk_municipio_geom_gid
primary key (unidad_territorial_id);


/*

    Tablas de datos ponderados.

*/
create table temp_etl.autonomia_datos_ponderados as
select
    substr(unidad_territorial, 1, 2) as unidad_territorial_id,
    *
from
    raw.autonomias_datos_ponderados;

alter table temp_etl.autonomia_datos_ponderados
add constraint autonomia_datos_ponderados_pkey
primary key(unidad_territorial_id);


create table temp_etl.provincia_datos_ponderados as
select
    substr(unidad_territorial, 1, 2) as unidad_territorial_id,
    *
from
    raw.provincias_datos_ponderados;

alter table temp_etl.provincia_datos_ponderados
add constraint provincia_datos_ponderados_pkey
primary key(unidad_territorial_id);


create table temp_etl.municipio_datos_ponderados as
select
    substr(unidad_territorial, 1, 5) as unidad_territorial_id,
    *
from
    raw.municipios_datos_ponderados;

alter table temp_etl.municipio_datos_ponderados
add constraint municipio_datos_ponderados_pkey
primary key(unidad_territorial_id);

/*

    Tablas de datos índice.

*/
create table temp_etl.autonomia_datos_indice as
select
    substr(unidad_territorial, 1, 2) as unidad_territorial_id,
    *
from
    raw.autonomias_datos_indice;

alter table temp_etl.autonomia_datos_indice
add constraint autonomia_datos_indice_pkey
primary key(unidad_territorial_id);


create table temp_etl.provincia_datos_indice as
select
    substr(unidad_territorial, 1, 2) as unidad_territorial_id,
    *
from
    raw.provincias_datos_indice;

alter table temp_etl.provincia_datos_indice
add constraint provincia_datos_indice_pkey
primary key(unidad_territorial_id);


create table temp_etl.municipio_datos_indice as
select
    substr(unidad_territorial, 1, 5) as unidad_territorial_id,
    *
from
    raw.municipios_datos_indice;

alter table temp_etl.municipio_datos_indice
add constraint municipio_datos_indice_pkey
primary key(unidad_territorial_id);

commit;

vacuum analyze temp_etl.autonomia_geom;
vacuum analyze temp_etl.provincia_geom;
vacuum analyze temp_etl.municipio_geom;

vacuum analyze temp_etl.autonomia_datos_ponderados;
vacuum analyze temp_etl.provincia_datos_ponderados;
vacuum analyze temp_etl.municipio_datos_ponderados;

vacuum analyze temp_etl.autonomia_datos_indice;
vacuum analyze temp_etl.provincia_datos_indice;
vacuum analyze temp_etl.municipio_datos_indice;


/*

    Creación de tablas finales.

*/
begin;

drop table if exists climagen.autonomia;

create table climagen.autonomia as
select
    -- Campos de geometría
    a.unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,

    -- Campos de datos ponderados
    round(riesgo_de_inundaciones::numeric, 1) as riesgo_de_inundaciones,
    round(riesgo_de_incendios::numeric, 1) as riesgo_de_incendios,
    round(exposicion_a_la_sequia::numeric, 1) as exposicion_a_la_sequia,
    round(exposicion_a_contaminacion::numeric, 1) as exposicion_a_contaminacion,
    round(proporcion_mujeres_empleadas_sector_primario::numeric, 1) as proporcion_mujeres_empleadas_sector_primario,
    round(igualdad_jefatura_titular_de_la_explotacion_agricola::numeric, 1) as igualdad_jefatura_titular_de_la_explotacion_agricola,
    round(proporcion_poblacion_infantil::numeric, 1) as proporcion_poblacion_infantil,
    round(igualdad_poblacion_infantil::numeric, 1) as igualdad_poblacion_infantil,
    round(proporcion_poblacion_65::numeric, 1) as proporcion_poblacion_65,
    round(igualdad_poblacion_65::numeric, 1) as igualdad_poblacion_65,
    round(proporcion_mujeres_sobre_la_poblacion_total::numeric, 1) as proporcion_mujeres_sobre_la_poblacion_total,
    round(dependencia::numeric, 1) as dependencia,
    round(discapacidad::numeric, 1) as discapacidad,
    round(igualdad_discapacidad::numeric, 1) as igualdad_discapacidad,
    round(igualdad_en_inmigraciones_procedentes_del_extranjero::numeric, 1) as igualdad_en_inmigraciones_procedentes_del_extranjero,
    round(igualdad_en_emigraciones_con_destino_al_extranjero::numeric, 1) as igualdad_en_emigraciones_con_destino_al_extranjero,
    round(distribucion_de_la_renta_p80_p20::numeric, 1) as distribucion_de_la_renta_p80_p20,
    round(riesgo_de_pobreza::numeric, 1) as riesgo_de_pobreza,
    round(renta_media_neta_por_persona::numeric, 1) as renta_media_neta_por_persona,
    round(renta_media_neta_por_hogar::numeric, 1) as renta_media_neta_por_hogar,
    round(proporcion_menores_18_anyos_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_menores_18_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_menores_18_anyos_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_menores_18_anyos_en_riesgo_pobreza_extrema,
    round(proporcion_poblacion_total_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_poblacion_total_en_riesgo_pobreza_extrema,
    round(igualdad_poblacion_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_poblacion_en_riesgo_pobreza_extrema,
    round(proporcion_mayores_65_anyos_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_mayores_65_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_poblacion_mayor_65_anyos_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_poblacion_mayor_65_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_en_la_formacion_profesional::numeric, 1) as igualdad_en_la_formacion_profesional,
    round(igualdad_25_con_estudios_secundarios_y_superiores::numeric, 1) as igualdad_25_con_estudios_secundarios_y_superiores,
    round(nivel_educativo::numeric, 1) as nivel_educativo,
    round(igualdad_en_nivel_educativo_estudios_primarios::numeric, 1) as igualdad_en_nivel_educativo_estudios_primarios,
    round(igualdad_poblacion_ocupada::numeric, 1) as igualdad_poblacion_ocupada,
    round(tiempo_de_ocupacion::numeric, 1) as tiempo_de_ocupacion,
    round(igualdad_en_el_tiempo_de_ocupacion::numeric, 1) as igualdad_en_el_tiempo_de_ocupacion,
    round(igualdad_en_el_empleo_en_el_sector_industrial::numeric, 1) as igualdad_en_el_empleo_en_el_sector_industrial,
    round(igualdad_en_el_empleo_en_el_sector_de_la_construccion::numeric, 1) as igualdad_en_el_empleo_en_el_sector_de_la_construccion,
    round(igualdad_en_el_empleo_en_el_sector_servicios::numeric, 1) as igualdad_en_el_empleo_en_el_sector_servicios,
    round(proporcion_poblacion_activa::numeric, 1) as proporcion_poblacion_activa,
    round(proporcion_desempleo::numeric, 1) as proporcion_desempleo,
    round(igualdad_en_desempleo::numeric, 1) as igualdad_en_desempleo,
    round(proporcion_personas_que_viven_solas::numeric, 1) as proporcion_personas_que_viven_solas,
    round(igualdad_personas_que_viven_solas::numeric, 1) as igualdad_personas_que_viven_solas,
    round(igualdad_en_el_grado_de_participacion_en_las_tareas_domesticas::numeric, 1) as igualdad_en_el_grado_de_participacion_en_las_tareas_domesticas,
    round(igualdad_en_cuidados_a_menores_o_personas_dependientes_dentro_d::numeric, 1) as igualdad_en_cuidados_a_menores_o_personas_dependientes_dentro_d,
    round(proporcion_personas_sin_apoyo_social::numeric, 1) as proporcion_personas_sin_apoyo_social,
    round(igualdad_personas_sin_apoyo_social::numeric, 1) as igualdad_personas_sin_apoyo_social,
    round(proporcion_personas_en_establecimientos_colectivos_residenciale::numeric, 1) as proporcion_personas_en_establecimientos_colectivos_residenciale,
    round(igualdad_personas_en_establecimientos_colectivos_residenciales_::numeric, 1) as igualdad_personas_en_establecimientos_colectivos_residenciales_,
    round(dispositivos_de_atencion_primaria::numeric, 1) as dispositivos_de_atencion_primaria,
    round(dispositivos_de_atencion_especializada_camas::numeric, 1) as dispositivos_de_atencion_especializada_camas,
    round(delitos_por_acoso_sexual::numeric, 1) as delitos_por_acoso_sexual,
    round(proporcion_acceso_a_smartphone::numeric, 1) as proporcion_acceso_a_smartphone,
    round(igualdad_en_el_acceso_a_smartphone::numeric, 1) as igualdad_en_el_acceso_a_smartphone,
    round(igualdad_en_el_acceso_a_internet::numeric, 1) as igualdad_en_el_acceso_a_internet,
    round(proporcion_hogares_que_sufren_contaminacion_y_otros_problemas_a::numeric, 1) as proporcion_hogares_que_sufren_contaminacion_y_otros_problemas_a,
    round(anyo_construccion_vivienda::numeric, 1) as anyo_construccion_vivienda,
    round(personas_convivientes_y_superficie_vivienda::numeric, 1) as personas_convivientes_y_superficie_vivienda,

    -- Datos de datos índice
    round(indice_clima_gen_sin_cambio_climatico::numeric, 1) as indice_clima_gen_sin_cambio_climatico,
    round(icc_2040_4_5::numeric, 1) as icc_2040_4_5,
    round(icc_2070_4_5::numeric, 1) as icc_2070_4_5,
    round(icc_2100_4_5::numeric, 1) as icc_2100_4_5,
    round(icc_2040_8_5::numeric, 1) as icc_2040_8_5,
    round(icc_2070_8_5::numeric, 1) as icc_2070_8_5,
    round(icc_2100_8_5::numeric, 1) as icc_2100_8_5,
    round(clima_gen_cambio_climatico_2040_4_5::numeric, 1) as clima_gen_cambio_climatico_2040_4_5,
    round(clima_gen_cambio_climatico_2070_4_5::numeric, 1) as clima_gen_cambio_climatico_2070_4_5,
    round(clima_gen_cambio_climatico_2100_4_5::numeric, 1) as clima_gen_cambio_climatico_2100_4_5,
    round(clima_gen_cambio_climatico_2040_8_5::numeric, 1) as clima_gen_cambio_climatico_2040_8_5,
    round(clima_gen_cambio_climatico_2070_8_5::numeric, 1) as clima_gen_cambio_climatico_2070_8_5,
    round(clima_gen_cambio_climatico_2100_8_5::numeric, 1) as clima_gen_cambio_climatico_2100_8_5,

    -- Geometría
    geom
from
    temp_etl.autonomia_geom a left join
    temp_etl.autonomia_datos_ponderados b on
        a.unidad_territorial_id = b.unidad_territorial_id left join
    temp_etl.autonomia_datos_indice c on
        a.unidad_territorial_id = c.unidad_territorial_id
order by a.unidad_territorial_id;

create index idx_autonomia_geom_gist
on climagen.autonomia
using gist(geom);

alter table climagen.autonomia
alter column geom
type geometry(MultiPolygon, 3857)
using st_setsrid(geom, 3857);

alter table climagen.autonomia
alter column geom
type geometry(MultiPolygon, 3857)
using st_setsrid(geom, 3857);


drop table if exists climagen.provincia;

create table climagen.provincia as
select
    -- Campos de geometría
    a.unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,

    -- Campos de datos ponderados
    round(riesgo_de_incendios::numeric, 1) as riesgo_de_incendios,
    round(igualdad_jefatura_titular_de_la_explotacion_agricola::numeric, 1) as igualdad_jefatura_titular_de_la_explotacion_agricola,
    round(proporcion_poblacion_infantil::numeric, 1) as proporcion_poblacion_infantil,
    round(igualdad_poblacion_infantil::numeric, 1) as igualdad_poblacion_infantil,
    round(proporcion_poblacion_65::numeric, 1) as proporcion_poblacion_65,
    round(igualdad_poblacion_65::numeric, 1) as igualdad_poblacion_65,
    round(proporcion_mujeres_sobre_la_poblacion_total::numeric, 1) as proporcion_mujeres_sobre_la_poblacion_total,
    round(dependencia::numeric, 1) as dependencia,
    round(discapacidad::numeric, 1) as discapacidad,
    round(igualdad_discapacidad::numeric, 1) as igualdad_discapacidad,
    round(igualdad_en_inmigraciones_procedentes_del_extranjero::numeric, 1) as igualdad_en_inmigraciones_procedentes_del_extranjero,
    round(igualdad_en_emigraciones_con_destino_al_extranjero::numeric, 1) as igualdad_en_emigraciones_con_destino_al_extranjero,
    round(distribucion_de_la_renta_p80_p20::numeric, 1) as distribucion_de_la_renta_p80_p20,
    round(renta_media_neta_por_persona::numeric, 1) as renta_media_neta_por_persona,
    round(renta_media_neta_por_hogar::numeric, 1) as renta_media_neta_por_hogar,
    round(proporcion_menores_18_anyos_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_menores_18_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_menores_18_anyos_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_menores_18_anyos_en_riesgo_pobreza_extrema,
    round(proporcion_poblacion_total_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_poblacion_total_en_riesgo_pobreza_extrema,
    round(igualdad_poblacion_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_poblacion_en_riesgo_pobreza_extrema,
    round(proporcion_mayores_65_anyos_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_mayores_65_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_poblacion_mayor_65_anyos_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_poblacion_mayor_65_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_en_la_formacion_profesional::numeric, 1) as igualdad_en_la_formacion_profesional,
    round(igualdad_25_con_estudios_secundarios_y_superiores::numeric, 1) as igualdad_25_con_estudios_secundarios_y_superiores,
    round(nivel_educativo::numeric, 1) as nivel_educativo,
    round(igualdad_en_nivel_educativo_estudios_primarios::numeric, 1) as igualdad_en_nivel_educativo_estudios_primarios,
    round(igualdad_poblacion_ocupada::numeric, 1) as igualdad_poblacion_ocupada,
    round(proporcion_poblacion_activa::numeric, 1) as proporcion_poblacion_activa,
    round(proporcion_desempleo::numeric, 1) as proporcion_desempleo,
    round(igualdad_en_desempleo::numeric, 1) as igualdad_en_desempleo,
    round(proporcion_personas_que_viven_solas::numeric, 1) as proporcion_personas_que_viven_solas,
    round(igualdad_personas_que_viven_solas::numeric, 1) as igualdad_personas_que_viven_solas,
    round(igualdad_en_el_grado_de_participacion_en_las_tareas_domesticas::numeric, 1) as igualdad_en_el_grado_de_participacion_en_las_tareas_domesticas,
    round(igualdad_en_cuidados_a_menores_o_personas_dependientes_dentro_d::numeric, 1) as igualdad_en_cuidados_a_menores_o_personas_dependientes_dentro_d,
    round(proporcion_personas_sin_apoyo_social::numeric, 1) as proporcion_personas_sin_apoyo_social,
    round(igualdad_personas_sin_apoyo_social::numeric, 1) as igualdad_personas_sin_apoyo_social,
    round(proporcion_personas_en_establecimientos_colectivos_residenciale::numeric, 1) as proporcion_personas_en_establecimientos_colectivos_residenciale,
    round(igualdad_personas_en_establecimientos_colectivos_residenciales_::numeric, 1) as igualdad_personas_en_establecimientos_colectivos_residenciales_,
    round(dispositivos_de_atencion_primaria::numeric, 1) as dispositivos_de_atencion_primaria,
    round(delitos_por_acoso_sexual::numeric, 1) as delitos_por_acoso_sexual,
    round(proporcion_acceso_a_smartphone::numeric, 1) as proporcion_acceso_a_smartphone,
    round(igualdad_en_el_acceso_a_smartphone::numeric, 1) as igualdad_en_el_acceso_a_smartphone,
    round(igualdad_en_el_acceso_a_internet::numeric, 1) as igualdad_en_el_acceso_a_internet,
    round(anyo_construccion_vivienda::numeric, 1) as anyo_construccion_vivienda,
    round(personas_convivientes_y_superficie_vivienda::numeric, 1) as personas_convivientes_y_superficie_vivienda,

    -- Datos de datos índice
    round(indice_clima_gen_sin_cambio_climatico::numeric, 1) as indice_clima_gen_sin_cambio_climatico,
    round(icc_2040_4_5::numeric, 1) as icc_2040_4_5,
    round(icc_2070_4_5::numeric, 1) as icc_2070_4_5,
    round(icc_2100_4_5::numeric, 1) as icc_2100_4_5,
    round(icc_2040_8_5::numeric, 1) as icc_2040_8_5,
    round(icc_2070_8_5::numeric, 1) as icc_2070_8_5,
    round(icc_2100_8_5::numeric, 1) as icc_2100_8_5,
    round(clima_gen_cambio_climatico_2040_4_5::numeric, 1) as clima_gen_cambio_climatico_2040_4_5,
    round(clima_gen_cambio_climatico_2070_4_5::numeric, 1) as clima_gen_cambio_climatico_2070_4_5,
    round(clima_gen_cambio_climatico_2100_4_5::numeric, 1) as clima_gen_cambio_climatico_2100_4_5,
    round(clima_gen_cambio_climatico_2040_8_5::numeric, 1) as clima_gen_cambio_climatico_2040_8_5,
    round(clima_gen_cambio_climatico_2070_8_5::numeric, 1) as clima_gen_cambio_climatico_2070_8_5,
    round(clima_gen_cambio_climatico_2100_8_5::numeric, 1) as clima_gen_cambio_climatico_2100_8_5,

    -- Geometría
    geom
from
    temp_etl.provincia_geom a left join
    temp_etl.provincia_datos_ponderados b on
    a.unidad_territorial_id = b.unidad_territorial_id left join
    temp_etl.provincia_datos_indice c on
    a.unidad_territorial_id = c.unidad_territorial_id
order by a.unidad_territorial_id;

alter table climagen.provincia
add constraint pk_provincia_gid
primary key (unidad_territorial_id);

create index idx_provincia_geom_gist
on climagen.provincia
using gist(geom);

alter table climagen.provincia
alter column geom
type geometry(MultiPolygon, 3857)
using st_setsrid(geom, 3857);


drop table if exists climagen.municipio;

create table climagen.municipio as
select
    -- Campos de geometría
    a.unidad_territorial_id,
    inspireid,
    country,
    natlev,
    natlevname,
    natcode,
    nameunit,
    codnut1,
    codnut2,
    codnut3,

    -- Campos de datos ponderados
    round(riesgo_de_incendios::numeric, 1) as riesgo_de_incendios,
    round(proporcion_poblacion_infantil::numeric, 1) as proporcion_poblacion_infantil,
    round(igualdad_poblacion_infantil::numeric, 1) as igualdad_poblacion_infantil,
    round(proporcion_poblacion_65::numeric, 1) as proporcion_poblacion_65,
    round(igualdad_poblacion_65::numeric, 1) as igualdad_poblacion_65,
    round(proporcion_mujeres_sobre_la_poblacion_total::numeric, 1) as proporcion_mujeres_sobre_la_poblacion_total,
    round(igualdad_en_inmigraciones_procedentes_del_extranjero::numeric, 1) as igualdad_en_inmigraciones_procedentes_del_extranjero,
    round(igualdad_en_emigraciones_con_destino_al_extranjero::numeric, 1) as igualdad_en_emigraciones_con_destino_al_extranjero,
    round(distribucion_de_la_renta_p80_p20::numeric, 1) as distribucion_de_la_renta_p80_p20,
    round(renta_media_neta_por_persona::numeric, 1) as renta_media_neta_por_persona,
    round(renta_media_neta_por_hogar::numeric, 1) as renta_media_neta_por_hogar,
    round(proporcion_menores_18_anyos_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_menores_18_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_menores_18_anyos_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_menores_18_anyos_en_riesgo_pobreza_extrema,
    round(proporcion_poblacion_total_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_poblacion_total_en_riesgo_pobreza_extrema,
    round(igualdad_poblacion_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_poblacion_en_riesgo_pobreza_extrema,
    round(proporcion_mayores_65_anyos_en_riesgo_pobreza_extrema::numeric, 1) as proporcion_mayores_65_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_poblacion_mayor_65_anyos_en_riesgo_pobreza_extrema::numeric, 1) as igualdad_poblacion_mayor_65_anyos_en_riesgo_pobreza_extrema,
    round(igualdad_en_la_formacion_profesional::numeric, 1) as igualdad_en_la_formacion_profesional,
    round(igualdad_25_con_estudios_secundarios_y_superiores::numeric, 1) as igualdad_25_con_estudios_secundarios_y_superiores,
    round(nivel_educativo::numeric, 1) as nivel_educativo,
    round(igualdad_en_nivel_educativo_estudios_primarios::numeric, 1) as igualdad_en_nivel_educativo_estudios_primarios,
    round(igualdad_poblacion_ocupada::numeric, 1) as igualdad_poblacion_ocupada,
    round(tiempo_de_ocupacion::numeric, 1) as tiempo_de_ocupacion,
    round(igualdad_en_el_tiempo_de_ocupacion::numeric, 1) as igualdad_en_el_tiempo_de_ocupacion,
    round(proporcion_poblacion_activa::numeric, 1) as proporcion_poblacion_activa,
    round(proporcion_desempleo::numeric, 1) as proporcion_desempleo,
    round(igualdad_en_desempleo::numeric, 1) as igualdad_en_desempleo,
    round(proporcion_personas_que_viven_solas::numeric, 1) as proporcion_personas_que_viven_solas,
    round(igualdad_personas_que_viven_solas::numeric, 1) as igualdad_personas_que_viven_solas,
    round(igualdad_en_el_grado_de_participacion_en_las_tareas_domesticas::numeric, 1) as igualdad_en_el_grado_de_participacion_en_las_tareas_domesticas,
    round(igualdad_en_cuidados_a_menores_o_personas_dependientes_dentro_d::numeric, 1) as igualdad_en_cuidados_a_menores_o_personas_dependientes_dentro_d,
    round(proporcion_personas_sin_apoyo_social::numeric, 1) as proporcion_personas_sin_apoyo_social,
    round(igualdad_personas_sin_apoyo_social::numeric, 1) as igualdad_personas_sin_apoyo_social,
    round(dispositivos_de_atencion_primaria::numeric, 1) as dispositivos_de_atencion_primaria,
    round(proporcion_acceso_a_smartphone::numeric, 1) as proporcion_acceso_a_smartphone,
    round(igualdad_en_el_acceso_a_smartphone::numeric, 1) as igualdad_en_el_acceso_a_smartphone,
    round(igualdad_en_el_acceso_a_internet::numeric, 1) as igualdad_en_el_acceso_a_internet,
    round(anyo_construccion_vivienda::numeric, 1) as anyo_construccion_vivienda,

    -- Datos de datos índice
    round(indice_clima_gen_sin_cambio_climatico::numeric, 1) as indice_clima_gen_sin_cambio_climatico,
    round(icc_2040_4_5::numeric, 1) as icc_2040_4_5,
    round(icc_2070_4_5::numeric, 1) as icc_2070_4_5,
    round(icc_2100_4_5::numeric, 1) as icc_2100_4_5,
    round(icc_2040_8_5::numeric, 1) as icc_2040_8_5,
    round(icc_2070_8_5::numeric, 1) as icc_2070_8_5,
    round(icc_2100_8_5::numeric, 1) as icc_2100_8_5,
    round(clima_gen_cambio_climatico_2040_4_5::numeric, 1) as clima_gen_cambio_climatico_2040_4_5,
    round(clima_gen_cambio_climatico_2070_4_5::numeric, 1) as clima_gen_cambio_climatico_2070_4_5,
    round(clima_gen_cambio_climatico_2100_4_5::numeric, 1) as clima_gen_cambio_climatico_2100_4_5,
    round(clima_gen_cambio_climatico_2040_8_5::numeric, 1) as clima_gen_cambio_climatico_2040_8_5,
    round(clima_gen_cambio_climatico_2070_8_5::numeric, 1) as clima_gen_cambio_climatico_2070_8_5,
    round(clima_gen_cambio_climatico_2100_8_5::numeric, 1) as clima_gen_cambio_climatico_2100_8_5,

    -- Geometría
    geom
from
    temp_etl.municipio_geom a left join
    temp_etl.municipio_datos_ponderados b on
    a.unidad_territorial_id = b.unidad_territorial_id left join
    temp_etl.municipio_datos_indice c on
    a.unidad_territorial_id = c.unidad_territorial_id
order by a.unidad_territorial_id;

alter table climagen.municipio
add constraint pk_municipio_gid
primary key (unidad_territorial_id);

create index idx_municipio_geom_gist
on climagen.municipio
using gist(geom);

alter table climagen.municipio
alter column geom
type geometry(MultiPolygon, 3857)
using st_setsrid(geom, 3857);


-- Drop etl schema
drop schema if exists temp_etl cascade;


-- Comments

comment on table climagen.autonomia
is 'Datos finales de autonomías (Gold, reproducible).';

comment on table climagen.provincia
is 'Datos finales de provincias (Gold, reproducible).';

comment on table climagen.municipio
is 'Datos finales de municipios (Gold, reproducible).';


commit;

vacuum analyze climagen.autonomia;
vacuum analyze climagen.provincia;
vacuum analyze climagen.municipio;
