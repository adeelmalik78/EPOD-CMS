--liquibase formatted sql

--changeset adeel:texas
CREATE TABLE texas
( id int primary key,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL
)
--rollback drop table texas

--changeset adeel:germany
CREATE TABLE germany
( id int primary key,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL
)
--rollback drop table germany

--changeset adeel:europe
CREATE TABLE europe
( id int primary key,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL
);
--rollback drop table europe

--changeset adeel:asia
CREATE TABLE asia
( id int primary key,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL
);
--rollback drop table asia

--changeset adeel:northamerica
CREATE TABLE northamerica
( id int primary key,
  first_name varchar(50) NOT NULL,
  last_name varchar(50) NOT NULL
);
--rollback drop table northamerica

-- GRANT SELECT ON asia to DATICAL_USER;
-- GRANT SELECT ANY TABLE to DATICAL_USER;
