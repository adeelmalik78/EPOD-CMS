--liquibase formatted sql

--changeset adeel:07_dml_insert
create table dml_insert (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)
--rollback drop table dml_insert