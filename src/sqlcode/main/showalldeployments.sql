--liquibase formatted sql

--changeset adeel:showalldeployments runAlways:true
select * from DATABASECHANGELOG;
--rollback select * from DATABASECHANGELOG

