--liquibase formatted sql

--changeset adeel:01
CREATE TABLE person
( id int primary key,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL
)
--rollback drop table person
