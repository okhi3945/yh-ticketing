# Jenkins Module에 넣을 SSH 공개키

# Network 모듈에서 vpc랑 서브넷 아이디 받아옴
variable "vpc_id" {}
variable "public_subnet_ids" {}

variable "ssh_public_key" {
  description = "jenkins ec2 인스턴스에 연결하기 위한 퍼블릭 SSH 키 변수"
  type = string
  sensitive = true # terraform plan, output에 값이 직접 표시 X
}
