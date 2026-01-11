pipeline {
    agent any

    environment {
        AWS_REGION     = 'ap-northeast-2'
        ECR_URL        = '601559288376.dkr.ecr.ap-northeast-2.amazonaws.com/ticketing-api-repo' //
        CLUSTER_NAME   = 'ticketing-eks-cluster' //
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    stages {
        // 0. 단계 스크립트 실행 권한 부여
        stage('Prepare') {
            steps {
                echo 'Preparing workspace...'
                // 빌드 스크립트 실행 권한 부여
                sh 'chmod +x gradlew'
            }
        }

        // 1. 소스코드 가져오기
        stage('Checkout') {
            steps {
                checkout scm //
            }
        }

        // 2. Spring Boot 빌드 (JAR 생성)
        stage('Build Artifact') {
            steps {
                container('gradle') {
                    sh 'chmod +x gradlew'
                    sh './gradlew clean build -x test -Dorg.gradle.jvmargs="-Xmx512m"' //
                }
            }
        }

        // 3. Docker 이미지 빌드 및 태그
        stage('Docker Build & Tag') {
            steps {
                container('docker') {
                    sh "docker build -t ${ECR_URL}:${IMAGE_TAG} ." //
                    sh "docker tag ${ECR_URL}:${IMAGE_TAG} ${ECR_URL}:latest" //
                }
            }
        }

        // 4. AWS ECR에 이미지 푸시
        stage('Push to ECR') {
            steps {
                container('docker') {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}" //
                    sh "docker push ${ECR_URL}:${IMAGE_TAG}"
                    sh "docker push ${ECR_URL}:latest"
                }
            }
        }

        // 5. EKS 배포 (환경 변수 치환 로직 포함)
        stage('Deploy to EKS') {
            steps {
                echo 'Deploying to AWS EKS...'
                script {
                    sh "kubectl apply -f k8s/deployment.yml"
                    
                    sh "kubectl rollout status deployment/yh-ticketing"
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

