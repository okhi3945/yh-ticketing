# Root Variables for SSH Key (보안 관리)
variable "public_ssh_key_content" {
  description = "EC2 접속을 위한 Public SSH Key"
  type        = string
  sensitive   = true # GitHub에 올릴 수 없도록 민감 정보로 표시
}
