--liquibase formatted sql

--changeset adeel:01
create table create_table2 (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)
--rollback drop table create_table2
