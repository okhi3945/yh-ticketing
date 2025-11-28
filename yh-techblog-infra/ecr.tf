# ECR(Elastic Container Registry) for Docker Images

# ECR 레지스트리 생성
# 저장된 Docker 이미지를 추후 EKS 클러스터가 가져가서 실행
resource "aws_ecr_repository" "techblog_api" {
  name			= "yh-techblog-api-repo"

  # 푸시될 때마다 취약점 자동 스캔 설정
  image_scanning_configuration {
    scan_on_push = true
  }

  # 같은 태그로 이미지 덮어쓰는 것 방지
  image_tag_mutability = "MUTABLE"

  tags = {
    Name	= "TechBlog-API-Repository"
    Environment = "Dev"
  }
}

resource "aws_ecr_lifecycle_policy" "api_policy" {
  repository = aws_ecr_repository.techblog_api.name

  # ECR 정책 문서
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "최근 5개의 이미지만 유지, 나머지는 삭제",
        selection = {
          tagStatus   = "untagged", # 태그가 없는 이미지 대상
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 30 # 30일이 지난 이미지 삭제
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "7일이 지난 태그되지 않은 이미지 삭제",
        selection = {
          tagStatus   = "any", # 모든 이미지 대상 (태그가 있든 없든)
          countType   = "imageCountMoreThan",
          countNumber = 5  # 최신 5개 이미지 제외하고 삭제
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR 레지스트리 URL을 다른 모듈에서 사용하기 위한 Output 설정
output "ecr_repository_url" {
  description = "다른 모듈에서 사용하기 위한 ECR 레지스트리 URL 아웃풋"
  value       = aws_ecr_repository.techblog_api.repository_url
}
