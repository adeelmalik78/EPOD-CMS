--liquibase formatted sql

--changeset amalik:insert_index runOnChange:true
CREATE OR REPLACE FUNCTION insert_indexes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
                BEGIN
                  UPDATE "SaleLots"
                  SET "lotMainIndex" = CAST(substring(NEW."lotNumber", '([0-9]+)') AS INTEGER), "lotSubIndex" = substring(NEW."lotNumber", '([A-Za-z]+)') WHERE "saleLotID" = NEW."saleLotID";
                  RETURN NEW;
                END; $function$
