begin;

-- Autonomías

create table climagen.autonomia as
with a as (
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
    from raw.autonomias_regcan
)
select *
from a
order by unidad_territorial_id;

alter table climagen.autonomia
add constraint pk_autonomia_gid
primary key (unidad_territorial_id);

create index idx_autonomia_geom_gist
on climagen.autonomia
using gist(geom);

alter table climagen.autonomia
alter column geom
type geometry(MultiPolygon, 3857)
using st_setsrid(geom, 3857);


-- Provincias

create table climagen.provincia as
with a as (
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
    from raw.provincias_regcan
)
select *
from a
order by unidad_territorial_id;

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


-- Municipios

create table climagen.municipio as
with a as (
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
    from raw.municipios_regcan
)
select *
from a
order by unidad_territorial_id;

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

commit;