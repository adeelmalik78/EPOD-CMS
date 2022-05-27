--liquibase formatted sql

--changeset adeel:17
create table create_index (
    id int primary key,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
)

--rollback drop table create_index



--changeset adeel:18
alter table create_index rename column city to city_name;
--rollback select * from databasechangelog
