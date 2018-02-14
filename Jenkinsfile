pipeline {
    agent any

    triggers {
        pollSCM('H * * * *')
    }

    stages {
        stage ('Post Secrets to AWS SQS') {
            steps {
                sh 'summon python sqsPost.py'
            }
        }
    }
}
