/*

    Procedimiento para obtener la tabla climagen.variable de forma que las variables
    consten en el mismo orden que en los Excel y además se sepa si está en autonómicas,
    provincias y/o municipales.

    Se crean primero tres tablas listas que se cargan de datos a partir de
    1000_digitalizacion/esquemas/x-lista.txt, que se hizo manualmente.

*/

begin;

-- Carga de los datos de listas para los tres niveles territoriales.

create table raw.variables_lista_autonomias (
    variable varchar
);

create table raw.variables_lista_provincias (
    variable varchar
);

create table raw.variables_lista_municipios (
    variable varchar
);


-- Carga de la lista de variables de las pestañas de datos_indice.
-- Son iguales en todos los niveles territoriales.
-- Carga de datos manual.

create table raw.variables_datos_indice (
    variable varchar
);


-- Generación de la tabla final de variables.

create table climagen.variable as
with aut_order as (
    select
        *,
        row_number() over () as variable_order
    from raw.variables_lista_autonomias
), a as (
    select
        a.variable as variable_id,
        a.variable_order * 10 as variable_order,
        'double precision' as data_type,
        null as name,
        null as description_short,
        null as description_long,
        true as autonomia,
        b.variable is not null as provincia,
        c.variable is not null as municipio
    from
        aut_order a left join
        raw.variables_lista_provincias b on
        a.variable = b.variable left join
        raw.variables_lista_municipios c on
        a.variable = c.variable
    order by variable_order
)
select
    row_number() over () as gid,
    *
from a;

alter table climagen.variable
add constraint variable_pkey
primary key(gid);


-- Inserción de las variables de la pestaña de los escenarios de cambio climático.

insert into climagen.variable
select
    9000 + row_number() over () as gid,
    variable as variable_id,
    560 + (row_number() over () * 10) as variable_order,
    'double precision' as data_type,
    null as name,
    null as description_short,
    null as description_long,
    true as autonomia,
    true as provincia,
    true as municipio
from
    raw.variables_datos_indice;

commit;

vacuum analyze climagen.variable;
