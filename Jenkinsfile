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
                    // ⭐️ AWS_CREDS를 환경변수로 주입
                    withCredentials([usernamePassword(credentialsId: 'AWS_CREDS', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                        
                        // 1. ECR 로그인
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                        
                        // 2. 이미지 빌드 및 푸시
                        sh "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
                        sh "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_URL}:${IMAGE_TAG}"
                        sh "docker push ${ECR_URL}:${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'AWS_CREDS', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'RDS_PASSWORD', variable: 'DB_PWD')
                    ]) {
                        def rdsHost = ""
                        dir('yh-ticketing-infra') {
                            sh "terraform init -input=false -no-color"
                            rdsHost = sh(script: "terraform output -raw rds_endpoint", returnStdout: true).trim()
                            rdsHost = rdsHost.split(':')[0]
                        }

                        sh "sed -i 's|IMAGE_TAG_PLACEHOLDER|${IMAGE_TAG}|g' k8s/deployment.yaml"
                        sh "sed -i 's|DB_HOST_PLACEHOLDER|${rdsHost}|g' k8s/deployment.yaml"
                        sh "sed -i 's|DB_PASS_PLACEHOLDER|${DB_PWD}|g' k8s/deployment.yaml"

                        sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME} --kubeconfig ./my-kubeconfig.yaml"

                        sh "kubectl apply -f k8s/deployment.yaml --kubeconfig ./my-kubeconfig.yaml --validate=false"
    

                        sh "kubectl rollout status deployment/${APP_NAME} --kubeconfig ./my-kubeconfig.yaml"
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

