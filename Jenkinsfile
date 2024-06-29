pipeline {
    agent any

    stages {
        stage('Checkout git') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], 
                                extensions: [cleanBeforeCheckout(deleteUntrackedNestedRepositories: true)],
                                userRemoteConfigs: [[credentialsId: '[github-ssh-key]', url: 'git@github.com:ky3ow/logseq-notes.git']])
            }
        }
    }
}