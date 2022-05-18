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
    PATH="/opt/liquibase/liquibase-4.8.0:$PATH"
    LIQUIBASE_PRO_LICENSE_KEY="ABwwGgQUjxKd8KQ1fa7HHI4P0Qsq3L22wOICAgQAjkB2jF6k42cSkAOMPPHgsp+e269W6eQeasbDCM6ks26gap8UcqOJnnGmC1REO0wyJmeH6kEg9RXXdsOLpwP0ieB0m+L0qX5V312gnWEs2srdn4y2MQa00f7rkvlIGFIITA5PytTg8VOaelFuwgOG3hl9qxIG3FPFLcvWd6LZvqt4+tSil8FJ6a8kfWPyrxG73ELEtWgGuIlH7+u9DKyMMWCGELuM3+YcHNDgfac3lri30+Dz0qB2xjm5VG5ikiiG/Hikvcbm4k/mJZEDimSRR7uMjLs/MFkcRqCCmhLUareSb2TWsfrOXaZbZ/1vNjbC5Mw3P6i4jxzzSDbVUMtQ8bZiPJsmF9QzOc180sytVZI1HkBTPUVx2GVmzCHYevTY7WSenIvzHGwv6KBspZL8ZHxRSU+2foW3y1aYmEDxRaxqUKplhidWE69InLidVKVbDN2XHpSsNZVOICoY5ggBN6HL6AazokZZr/ut35oVqvwBocsbVFDmh7l4OxlUHnQjxunywLL8leZztcOA9ZDVEGWzK+0KIUmMNYc3WRJYutMFgU10oGXpNA4PWjhlzNUzbOt2roNejsmqpY5n9S9aYQ0xzsevYnvx05tYF4E/blOhE41YWfEQKZnqXRj0MDVO7p1r+SCfCL/OvejvvcuHidU4zP0DwiY3gFZHTnNAjXk="

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
