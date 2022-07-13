#클러스터에 접근하거나 관리할때 사용하는 BASTION노드 설정

#BASION에 할당 할 탄력적 ip생성
resource "aws_eip" "bastion-eip" {
  vpc = true
  tags = {
    "Name" = "${var.cluster-name}-bastion-eip"
  }
}

#EC2 인스턴스 생성
resource "aws_instance" "bastion" {
  ami = "ami-0cbec04a61be382d9" //ami2
  instance_type = "t2.medium"
  subnet_id = aws_subnet.public-subnet[0].id //pubilc서브넷 할당
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name = "${var.key_name}" //key name
  tags = {
    Name = "${var.cluster-name}-bastion"
  }

}

#생성된 탄력적ip와 인스턴스 연결
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion-eip.id
}


### Bastion에서 사용할 SG및 rule
resource "aws_security_group" "bastion" {
  name        = "${var.cluster-name}-bastion"
  vpc_id      = aws_vpc.vpc.id
  description = "${var.cluster-name}-bastion-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster-name}-bastion"
  }
}

# 아래 아이피 대역에서 ssh접근을 허용함
resource "aws_security_group_rule" "allowssh" {
  description = "allow andyhome and 10f"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "TCP"
  cidr_blocks= ["220.117.232.147/32"]
  security_group_id = aws_security_group.bastion.id
}

#아래 아이피 대역에서 모든 접근을 허용함(테스트)
resource "aws_security_group_rule" "allowall" {
  description = "allow andyhome"
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks= ["110.117.232.147/32"]
  security_group_id = aws_security_group.bastion.id
}
