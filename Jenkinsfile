// Jenkinsfile
pipeline {
    agent {
        kubernetes {
            // Jenkins Agent가 실행될 Pod 정의 (Gradle, Docker, Kubectl 포함)
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: gradle
    image: gradle:8.4-jdk17
    command: ['sleep']
    args: ['99d']
  - name: docker
    image: docker:dind
    securityContext:
      privileged: true
  - name: kubectl
    image: lachlanevenson/k8s-kubectl:v1.25.4
    command: ['sleep']
    args: ['99d']
"""
        }
    }

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
                        // EKS 접속 설정
                        sh "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}" //

                        // [핵심] Terraform Output에서 DB 정보를 가져와 환경변수로 설정
                        // Jenkins Pod가 IRSA 권한을 가지고 있으므로 S3 백엔드에 접근 가능해야 함
                        dir('yh-ticketing-infra') {
                            sh "terraform init -no-color"
                            env.DB_HOST_RAW = sh(script: "terraform output -raw rds_endpoint", returnStdout: true).trim() //
                            env.DB_PASS_RAW = sh(script: "terraform output -raw rds_password", returnStdout: true).trim() //
                        }

                        // [핵심] envsubst를 사용하여 k8s/deployment.yaml의 변수를 실제 값으로 치환
                        // DB_HOST, DB_PASS, IMAGE_TAG가 치환된 deployment_final.yaml 생성
                        sh """
                            export DB_HOST=${env.DB_HOST_RAW}
                            export DB_PASS=${env.DB_PASS_RAW}
                            export IMAGE_TAG=${env.IMAGE_TAG}
                            envsubst < k8s/deployment.yaml > k8s/deployment_final.yaml
                        """

                        // 최종 파일 배포
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