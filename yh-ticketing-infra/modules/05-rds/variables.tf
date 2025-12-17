# RDS DB 인스턴스에 필요한 입력 변수 정의

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "RDS가 위치할 Private Subnet ID 리스트"
  type        = list(string)
}

variable "rds_password" {
  description = "RDS 마스터 계정 비밀번호"
  type        = string
  sensitive   = true
}

# EKS 워커 노드 보안 그룹 ID를 받아서 RDS 접속을 허용
variable "eks_node_security_group_id" {
  description = "EKS Worker Node Security Group ID"
  type        = string
}
