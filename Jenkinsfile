pipeline {
    agent any

    tools {
        jdk 'JDK 17' 
    }

    environment {
        AWS_REGION     = 'ap-northeast-2'
        ECR_URL        = '601559288376.dkr.ecr.ap-northeast-2.amazonaws.com/ticketing-api-repo' //
        CLUSTER_NAME   = 'ticketing-eks-cluster' //
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
        APP_NAME = "yh-ticketing"
    }

    stages {
        stage('Prepare') {
            steps {
                echo 'Preparing workspace...'
                // 빌드 스크립트 실행 권한 부여
                sh 'chmod +x gradlew'
            }
        }

        stage('Build') {
            steps {
                echo 'Building Spring Boot Application...'
                // 테스트를 제외하고 빌드 수행
                sh './gradlew clean build -x test'
            }
        }

        stage('Docker Build & Push') {
            steps {
                echo 'Building and Pushing Docker Image...'
                script {
                    // 1. ECR 로그인
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                    
                    // 2. 이미지 빌드
                    // 젠킨스 컨테이너가 호스트의 docker.sock을 공유하므로 로컬 도커 엔진을 사용합니다.
                    sh "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
                    
                    // 3. 태그 및 푸시
                    sh "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_URL}:${IMAGE_TAG}"
                    sh "docker push ${ECR_URL}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo 'Deploying to AWS EKS...'
                script {
                    sh "kubectl apply -f k8s/deployment.yaml"
                    
                    sh "kubectl rollout status deployment/${APP_NAME}"
                }
            }
        }
    }

    post {
        success {
            echo "티켓팅 서비스 배포 성공 (Build #${env.BUILD_NUMBER})"
        }
        failure {
            echo "배포 실패. 젠킨스 콘솔 로그를 확인해 주세요."
        }
    }
}

