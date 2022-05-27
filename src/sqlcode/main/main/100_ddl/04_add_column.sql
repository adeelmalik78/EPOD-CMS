--liquibase formatted sql

--changeset adeel:04
create table add_column (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)

--rollback drop table add_column