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
                echo 'Building and Pushing Docker Image for ARM64...'
                script {
                    // 1. ECR 로그인
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                    
                    // 2. buildx 빌더 생성 및 활성화 (처음 1회만 필요, 이미 있으면 무시)
                    sh "docker buildx create --use || true"
                    
                    // 3. ARM64 전용 이미지 빌드 및 ECR 푸시를 한 번에 처리
                    // 로컬에 이미지를 남기지 않고 ECR로 바로 푸시(--push) 하므로 기존의 tag, push 명령어가 필요 없습니다.
                    sh "docker buildx build --platform linux/arm64 -t ${ECR_URL}:${IMAGE_TAG} --push ."
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // 1. Terraform 폴더로 이동하여 RDS 엔드포인트 가져오기
                    def rdsHost = ""
                    dir('yh-ticketing-infra') {
                        sh "terraform init -input=false -no-color"
                        rdsHost = sh(script: "terraform output -raw rds_endpoint", returnStdout: true).trim()
                        rdsHost = rdsHost.split(':')[0]
                    }

                    // 2. 젠킨스 Credentials에서 DB 비밀번호 가져오기 (미리 등록해둔 ID: 'RDS_PASSWORD')
                    withCredentials([string(credentialsId: 'RDS_PASSWORD', variable: 'DB_PWD')]) {
                        
                        // 3. sed 명령어로 k8s/deployment.yaml의 플레이스홀더 치환
                        sh "sed -i 's|IMAGE_TAG_PLACEHOLDER|${IMAGE_TAG}|g' k8s/deployment.yaml"
                        sh "sed -i 's|DB_HOST_PLACEHOLDER|${rdsHost}|g' k8s/deployment.yaml"
                        sh "sed -i 's|DB_PASS_PLACEHOLDER|${DB_PWD}|g' k8s/deployment.yaml"

                        // 4. 쿠버네티스 배포 실행
                        sh "kubectl apply -f k8s/deployment.yaml --validate=false"
                    }
                    
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

