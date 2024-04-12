--liquibase formatted sql

--changeset adeel:employee
CREATE TABLE employee
( id int primary key,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL
)
--rollback drop table employee
