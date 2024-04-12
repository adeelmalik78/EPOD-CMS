--liquibase formatted sql

--changeset adeel:09_dml_context
create table dml_context (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)
--rollback drop table dml_context