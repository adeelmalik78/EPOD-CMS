#!/usr/bin/env groovy
// Liquibase declarative pipeline
//
//
pipeline {
agent any
  environment {
    GITURL="${params.REPO_URL}"
    PROJECT="${params.PROJECT}"
    BRANCH="${params.BRANCH}"
    ENVIRONMENT_STEP="${params.ENVIRONMENT}"
    CHANGELOGFILE="${params.CHANGELOGFILE}"
    CLASSPATH="${params.CLASSPATH}"
    BASEDIR="${params.BASEDIR}"
    PATH="/opt/liquibase/liquibase-4.26.0:$PATH"
    LIQUIBASE_PRO_LICENSE_KEY="<Your Liquibase Pro license key>"

  }
  stages {

    stage ('Precheck') {
		steps {
			sh '''
        { set +x; } 2>/dev/null
        echo "Git repository: "${GITURL}
        echo "Current project: "${PROJECT}
        echo "Current branch: "${BRANCH}
        echo "Current environment: "$ENVIRONMENT_STEP
        echo "Current changelog file: "${CHANGELOGFILE}
        echo "Current classpath: "${CLASSPATH}
        echo "Current base directory: "${BASEDIR}
        echo "Current path: "${PATH}
			'''
			cleanWs()
		} // steps
	} // stage 'precheck'

    stage ('Checkout') {
      steps {
        // checkout Liquibase project from repo
        sh '''
          { set +x; } 2>/dev/null
          echo "git clone ${GITURL}/${PROJECT}.git"
          git clone ${GITURL}/${PROJECT}.git
          cd ${PROJECT}
          git checkout $BRANCH
          git status
          '''
      } // steps for checkout stages
    } // stage 'checkout'

   stage ('liquibase commands'){
      steps {
        sh '''
          { set +x; } 2>/dev/null
          export LB_ARGS="--defaultsFile=${ENVIRONMENT}/liquibase.properties --changelogFile=${CHANGELOGFILE} --classpath=${CLASSPATH}"
          cd ${PROJECT}/${BASEDIR}
          liquibase --version
          liquibase $LB_ARGS status --verbose
          #liquibase --url=${URL} --password=${PASSWORD} --contexts=$ENVIRONMENT_STEP rollbackCount 2
          liquibase $LB_ARGS updateSQL
	  
          #liquibase $LB_ARGS tag 123_START
          #liquibase $LB_ARGS update
          #liquibase $LB_ARGS tag 123_END
	
          liquibase $LB_ARGS history
	  
        '''
      } // steps
    }   // Environment stage

        stage ('Deleting project workspace'){
           steps {
             sh '''
               { set +x; } 2>/dev/null
               echo "Deleting project workspace..."
               pwd
               rm -rf ${PROJ}
             '''
           } // steps
         }   // Deleting project workspace
  } // stages
}  // pipeline
