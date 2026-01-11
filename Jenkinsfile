pipeline {
    agent any

    environment {
        AWS_REGION     = 'ap-northeast-2'
        ECR_URL        = '601559288376.dkr.ecr.ap-northeast-2.amazonaws.com/ticketing-api-repo' //
        CLUSTER_NAME   = 'ticketing-eks-cluster' //
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    stages {
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
                container('kubectl') {
                    script {
                        sh "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}" //

                        dir('yh-ticketing-infra') {
                            sh "terraform init -no-color"
                            env.DB_HOST_RAW = sh(script: "terraform output -raw rds_endpoint", returnStdout: true).trim() //
                            env.DB_PASS_RAW = sh(script: "terraform output -raw rds_password", returnStdout: true).trim() //
                        }

                        sh """
                            export DB_HOST=${env.DB_HOST_RAW}
                            export DB_PASS=${env.DB_PASS_RAW}
                            export IMAGE_TAG=${env.IMAGE_TAG}
                            envsubst < k8s/deployment.yaml > k8s/deployment.yaml
                        """

                        sh "kubectl apply -f k8s/deployment_final.yaml" //
                        sh "kubectl apply -f k8s/redis.yaml" //
                    }
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