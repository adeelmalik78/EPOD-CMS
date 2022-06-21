--liquibase formatted sql

--changeset SteveZ:createTable_product labels:tenant1
--comment: This is my comment for product table
CREATE TABLE product (
    id INTEGER PRIMARY KEY,
    sku VARCHAR(256),
    name VARCHAR(256),
    price DECIMAL(20, 2)
);
--rollback DROP TABLE product;
