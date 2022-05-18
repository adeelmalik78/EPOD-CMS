--liquibase formatted sql

--changeset amalik:table2
CREATE TABLE table2 (
    "id_user_group" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    "name" varchar(200) NOT null,
    PRIMARY KEY ("id_user_group")
);
