--liquibase formatted sql

--changeset adeel:07_dml_update
create table dml_update (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)
--rollback drop table dml_update