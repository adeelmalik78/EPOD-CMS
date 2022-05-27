--liquibase formatted sql

--changeset adeel:07_dml_delete
create table dml_delete (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)
--rollback drop table dml_delete