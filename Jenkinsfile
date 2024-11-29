pipeline {
    agent any
    environment {
        AWS_REGION = "ap-south-1"
        IMAGE_REPO_NAME = "my-repo"
        IMAGE_TAG = "v1"
        REPOSITORY_URI = "381492080822.dkr.ecr.ap-south-1.amazonaws.com/my-repo"
        SONAR_HOME = '/bin/sonar-scanner'
        SONARQUBE_TOKEN = 'sqa_d9ee0d522a025f77d0686e5051466b874bf52cb4'
        sonar_projectKey = 'Jenkins-CI-CD'
    }
    stages {
        stage('Cloning Git') {
            steps {
                git branch: 'main', changelog: false, credentialsId: '9244fb76-aae2-4308-8a87-a5751e040d9c', poll: false, url: 'https://github.com/Nishalaxmi/CICD.git'
            }
        }
        stage('NPM Build') {
            steps {
                script {
                    echo 'Running NPM Build...'
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner';
                    withSonarQubeEnv(SonarQube) {
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${sonar_projectKey} -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONARQUBE_TOKEN}"
                    }
                }
            }
        }
        stage('Quality Gate Check') {
            steps {
                echo 'Checking Quality Gate...'
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Logging into AWS ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-ecr-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}
                    """
                }
            }
        }
        stage('Building Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_REPO_NAME}:${IMAGE_TAG}")
                }
            }
        }
        stage('Pushing to ECR') {
            steps {
                script {
                    docker.withRegistry("https://${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com", 'aws-ecr-credentials') {
                        dockerImage.push("${IMAGE_TAG}")
                    }
                }
            }
        }
        stage('Trivy Scan') {
            steps {
                echo 'Scanning Docker Image with Trivy...'
                sh """
                    trivy image ${REPOSITORY_URI}:${IMAGE_TAG} || exit 1
                """
            }
        }
        stage('Updating the Deployment File') {
            steps {
                echo 'Updating Deployment File...'
                sh """
                    sed -i 's|image: .*|image: ${REPOSITORY_URI}:${IMAGE_TAG}|' k8s/deployment.yaml
                """
            }
        }
    }
    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs.'
        }
    }
}
