pipeline {
    agent any

    stages {
        stage('Checkout git') {
            steps {
                deleteDir()
                dir('notes') {
                    checkout scm: scmGit(branches: [[name: '*/publish']], 
                                  extensions: [cleanBeforeCheckout(deleteUntrackedNestedRepositories: true)],
                                  userRemoteConfigs: [[credentialsId: '[github-ssh-key]', url: 'git@github.com:ky3ow/logseq-notes.git']]),
                             poll: false
                }
            }
        }
    }

    triggers {
        githubPush()
    }
}
