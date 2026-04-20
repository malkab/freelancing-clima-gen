-- ------------------------
--
-- Inicialización de la base de datos
--
-- ------------------------

\c postgres

-- Creación de la base de datos

create database climagen;

\c climagen

create extension postgis;

create schema climagen;