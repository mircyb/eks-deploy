##VPC 구성


## VPC 대역 설정
resource "aws_vpc" "vpc" {
  cidr_block = "10.120.0.0/16"

  tags = {
    "Name" = "${var.cluster-name}-vpc"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }

}


#Private 서브넷에서 외부로 나갈때 사용하는 NAT-gateway에 할당할 탄력적 ip 생성
resource "aws_eip" "eip" {
  vpc = true
  tags = {
    "Name" = "${var.cluster-name}-public-nat-gateway"
  }
}


# nat gateway생성
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.public-subnet[0].id

  tags = {
    "Name" = "${var.cluster-name}-nat-gateway"
  }
}

# AZ설정
variable "zones" {
  default = ["a", "b", "c"]
}


# public subnet 생성
resource "aws_subnet" "public-subnet" {
  count = length(var.zones)

  availability_zone       = "ap-northeast-2${var.zones[count.index]}" // 위에서 설정한 AZ만큼 수행
  cidr_block              = "10.120.${count.index+1}.0/24" // 설정된 AZ 갯수만큼 1씩 증가되어 수행
  map_public_ip_on_launch = false //public ip자동 할당 옵션
  vpc_id                  = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.cluster-name}-public-${var.zones[count.index]}"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

# private subnet 생성
resource "aws_subnet" "private-subnet" {
  count = length(var.zones)

  availability_zone       = "ap-northeast-2${var.zones[count.index]}"
  cidr_block              = "10.120.1${count.index+1}.0/24"
  vpc_id                  = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.cluster-name}-private-${var.zones[count.index]}"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# 퍼블릭 서브넷에서 사용할 igw 설정
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.cluster-name}-igw"
  }
}



# public route table
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "${var.cluster-name}-public"
  }
}

# private route table
resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    "Name" = "${var.cluster-name}-private"
  }
}



# public route table association
resource "aws_route_table_association" "public-routing" {
  count = 3

  subnet_id      = aws_subnet.public-subnet.*.id[count.index]
  route_table_id = aws_route_table.public-route.id
}

# private route table association
resource "aws_route_table_association" "private-routing" {
  count = 3

  subnet_id      = aws_subnet.private-subnet.*.id[count.index]
  route_table_id = aws_route_table.private-route.id
}

