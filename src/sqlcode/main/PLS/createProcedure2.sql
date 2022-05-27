--liquibase formatted sql

--changeset adeel:createProcedure2
create table createProcedure2 (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)
