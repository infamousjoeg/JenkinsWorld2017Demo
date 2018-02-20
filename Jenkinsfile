pipeline {
    agent any

    triggers {
        pollSCM('H * * * *')
    }

    stages {
        stage ('Check Health of Conjur server') {
			steps {
				sh 'curl -s -k -i -X GET https://jenkins/health'
			}
		}
        //stage ('Post Secrets to AWS SQS') {
        //    steps {
        //        sh 'summon python sqsPost.py'
        //    }
        //}
        stage ('Set Secret Variable via Shell') {
			steps {
				sh 'conjur variable values add jenkins/github/username USER-$(date +"%H-%M")'
			}
		}
        stage ('Pull Secret Using Shell') {
			steps {
				sh 'echo `conjur variable value jenkins/github/username`'
			}
		}
        stage ('Pull secret using script') {
			steps {
				sh 'chmod +x ./pull_secret.sh && ./pull_secret.sh'
			}
		}
        stage ('Pull secret using REST API and logged in user\'s API key') {
			steps {
				sh 'chmod +x variable_pull.sh && ./variable_pull.sh'
			}
		}
        stage ('Create hostfactory token, grab new machine identity, and pull secret') {
			steps {
				sh 'chmod +x hostfactory_pull.sh && ./hostfactory_pull.sh'
			}
		}
    }
}
