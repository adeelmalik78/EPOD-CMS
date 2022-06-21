export LIQUIBASE_HOME=~/Desktop/LiquibaseHub/liquibase-4.11.0
export LIQUIBASE_COMMAND_URL=jdbc:postgresql://localhost:5432/postgres
export LIQUIBASE_COMMAND_USERNAME=postgres
export LIQUIBASE_COMMAND_PASSWORD=secret
export LIQUIBASE_COMMAND_CHANGELOG_FILE=masterchangelog.xml
export LIQUIBASE_PRO_LICENSE_KEY=<Your Liquibase Pro license key>
# export LIQUIBASE_HUB_MODE=off
# export LIQUIBASE_HUB_API_KEY=02HcmDJzX_tg0YfTL9ecAE2M0PNbdnjbiNV1dWgbphU



liquibase checks show
liquibase checks bulk-set --disable
liquibase checks delete --check-name=SqlGrantAlterWarn
liquibase checks enable --check-name=SqlGrantSpecificPrivsWarn
SqlGrantAlterWarn
2
"ALTER SESSION","ALTER SYSTEM",EXP_FULL_DATABASE,IMP_FULL_DATABASE,"CREATE ANY TABLE","DROP ANY TABLE","ALTER ANY TABLE","SELECT ANY TABLE","COMMENT ANY TABLE","EXECUTE ANY PROCEDURE"


#liquibase data run --name=myrepos --env=POSTGRES_PASSWORD=secret --image=postgres
