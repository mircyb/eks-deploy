#EKS에서 사용할 기본 보안그룹 설정


#public http/https open정책이며 public open서비스 ingress에 할당 될 보안그룹
resource "aws_security_group" "allow-all-ip" {
  name        = "allow-all-ip"
  description = "Allow All http/https Traffic Into LB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "HTTPS from Any"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP from Any"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow-all-ip"
  }
}

#지정된 ip만 http/https 오픈 정책이며 private service alb에 할당 될 보안그룹
resource "aws_security_group" "allow-defined-ip" {
  name        = "allow-defined-ip"
  description = "Allow defined ip http/https Traffic Into LB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["110.117.232.147/32"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["110.117.232.147/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow-defined-ip"
  }
}
resource "aws_security_group" "shared-backend" {
  name        = "shared-backend-${var.cluster-name}"
  description = "[k8s] Shared Backend SecurityGroup for LoadBalancer"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "shared-backend-sg"
  }
}
