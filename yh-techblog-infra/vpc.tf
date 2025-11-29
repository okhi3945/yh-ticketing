# VPC (Virtual Private Cloud)
# EKS, Jenkins, RDS

# VPC
resource "aws_vpc" "techblog_vpc" { 
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # DNS 이름 지원 활성화
  enable_dns_hostnames = true # DNS 호스트 이름 지원 활성화
  tags = {Name = "YH-Techblog-VPC"}
}

# Internet Gateway(Public Subnet에 연결하여 VPC와 인터넷 간 통신)
resource "aws_internet_gateway" "techblog_igw" {
  vpc_id = aws_vpc.techblog_vpc.id
  tags = {Name = "YH-Techblog-IGW"}
}

# NAT Gateway을 위한 Elastic IP 정의
# Private Subnet이 외부에 접근할 때 사용할 고정 Public IP
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc" # VPC 내에서 사용할 EIP임을 명시함
  tags = { Name = "YH-Techblog-NAT-EIP"}
}

# NAT Gateway 
# Private Subnet이 외부(ECR, Docker HUb 등)에 나갈 수 있는 출구
# NAT Gateway는 반드시 Public Subnet에 위치해야함!!
resource "aws_nat_gateway" "techblog_nat" {
  allocation_id = aws_eip.nat_gateway_eip.id # NAT Gateway에 위에 만들어둔 EIP 할당
  subnet_id     = aws_subnet.public_subnet_a.id # AZ-A의 Public Subnet에 NAT Gateway 배치함, Private Subnet에서 외부로 통신을 할 때 AZ-A의 Public Subnet으로 이동하여 NAT Gateway로 통신하는데 나갈때 IP 주소는 위에 생성한 EIP가 할당됨!
  tags = {Name = "YH-Techblog-NAT-GW"}

  #NAT GW가 EIP에 할당된 후에만 생성되도록 명시
  depends_on = [aws_internet_gateway.techblog_igw]
}

# Subnets (2개 가용 영역에 Private 2개, Public 2개 총 4개의 서브넷 생성)
# 가용 영역 목록 설정 (Providers.tf에서 Provider "aws"에 region을 이미 설정했기에 Terraform은 이 설정을 기반으로 모든 작업을 수행함)
data "aws_availability_zones" "available" { # data는 리소스를 생성하는 것이 아닌 이미 존재하는 정보를 조회할 때 사용
  state = "available" # 조회한 가용 영역 목록 중 현재 AWS에서 사용 가능한(Available) 상태인 AZ만 필터링해서 가져오라는 조건
}

# Public Subnet A (10.0.1.0/24) - AZ A
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.techblog_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0] # data로 AZ 가져와서 첫번째 값 AZ로 할당
  map_public_ip_on_launch = true # Public Subnet이기 때문에 Public IP 자동 할당 옵션 true
  tags = { Name = "YH-Techblog-Public-A" }
}

# Public Subnet B (10.0.2.0/24) - AZ B
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.techblog_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1] # data로 가져온 AZ 중 2번째 값을 가져와서 할당 AZ B에 위치하는 Public Subnet임
  map_public_ip_on_launch = true
  tags = {
    Name = "YH-Techblog-Public-B"
  }
}

# Private Subnet A (10.0.11.0/24) - AZ A
# Private Subnet은 map_public_ip_on_launch을 사용하지 않음
# Public IP가 없기에 여기는 Private Subnet임
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.techblog_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0] # 첫번째 AZ인 A에 Private Subnet 할당
  tags = {
    Name = "YH-Techblog-Private-A"
  }
}

# Private Subnet B (10.0.12.0/24) - AZ B
resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.techblog_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1] # 두번째 AZ인 B에 Private Subnet 할당
  tags = {
    Name = "YH-Techblog-Private-B"
  }
}


# Route Tables (라우팅 테이블 정의)

# Public Route Table : 외부로 통하는 경로 정의
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.techblog_vpc.id
  tags = {Name = "YH-Techblog-Public-RT"}
}

# Public Route : 0.0.0.0/0 (모든 트래픽)을 IGW로 보냄
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0" # 목적지 cidr block은 외부(인터넷)임
  gateway_id             = aws_internet_gateway.techblog_igw.id # 트래픽을 위에 만들어둔 인터넷 게이트웨이로 보냄
}

# Public Subnet A와 Public Route Table 연결
resource "aws_route_table_association" "public_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id # subnet A
  route_table_id = aws_route_table.public_route_table.id # public route
}

# Public Subnet B와 Public Route Table 연결
resource "aws_route_table_association" "public_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id # subnet B
  route_table_id = aws_route_table.public_route_table.id # public route
}


# Private Route Table은 외부로 나갈 때 NAT Gateway를 사용해서 가야함
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.techblog_vpc.id
  tags = {Name = "YH-Techblog-Private-RT"}
}

# Priavate Route : 0.0.0.0/0 (모든 트래픽)을 NAT Gateway로 보냄 외부로 트래픽을 내보낼 수 있지만 외부에서 Priavate Subnet으로 들어올 수는 없음
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.techblog_nat.id
}

# Private Subnet A와 NAT GW가 연결된 Private Route Table 연결
resource "aws_route_table_association" "private_a_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

# Private Subnet B와 NAT GW가 연결된 Private Route Table 연결
resource "aws_route_table_association" "private_b_association" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
}

# outputs 설정 : 다른 모듈에서 VPC 정보를 쉽게 참조하기 위함
output "vpc_id" {
  description = "메인 VPC의 ID"
  value       = aws_vpc.techblog_vpc.id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷의 아이디들 (a,b)"
  value       = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷의 아이디들 (a,b)"
  value       = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

output "vpc_cidr_block" {
  description = "VPC의 CIDR Block"
  value       = aws_vpc.techblog_vpc.cidr_block
}

