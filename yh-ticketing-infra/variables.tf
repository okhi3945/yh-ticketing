# Root Variables for SSH Key (보안 관리)
variable "public_ssh_key_content" {
  description = "EC2 접속을 위한 Public SSH Key"
  type        = string
  sensitive   = true # GitHub에 올릴 수 없도록 민감 정보로 표시
}

# RDS DB 비밀번호 변수
variable "rds_db_password" {
  description = "RDS PostgreSQL 마스터 사용자 비밀번호"
  type        = string
  sensitive   = true
}
