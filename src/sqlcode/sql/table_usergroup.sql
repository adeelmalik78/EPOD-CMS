--liquibase formatted sql

--changeset amalik:user_group
CREATE TABLE user_group(
    "id_user_group" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    "name" varchar(200) NOT null,
    PRIMARY KEY ("id_user_group")
);