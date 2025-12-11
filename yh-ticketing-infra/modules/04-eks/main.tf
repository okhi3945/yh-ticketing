# Module 04-eks : EKS Cluster, Private Subnet에 매치, Public Subnet에는 EKS를 위한 NLB 배치

# vpc/subnet 정보
variable "vpc_id" { }
variable "private_subnet_ids" { }
variable "public_subnet_ids" { }

# EKS 클러스터용 IAM Role
