#RDS 설정


#RDS INSTANCE배포 설정
resource "aws_db_instance" "rds" {
  allocated_storage    = 20 //스토리지 용량
  engine               = "mariadb"  //db엔진 명시
  engine_version       = "10.6.7" //엔진버전
  instance_class       = "db.t3.medium"
  db_name              = "testdb" // 기본으로 생성할 db이름
  username             = "root"
  password             = "${var.dbpassword}"
  parameter_group_name = "default.mariadb10.6" // db파라메터
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds.name
  identifier           = "${var.cluster-name}-rds"
  vpc_security_group_ids  = [aws_security_group.rds.id]
  storage_encrypted = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  backup_retention_period = "7"
  auto_minor_version_upgrade = false
}


# RDS에서 사용할 서브넷그룹을 private subnet을 이용하여 생성
resource "aws_db_subnet_group" "rds" {
  name       = "${var.cluster-name}-group"
  subnet_ids = aws_subnet.private-subnet[*].id

  tags = {
    Name = "${var.cluster-name}-rds"
  }
}

# RDS에서 사용할 보안그룹 생성
resource "aws_security_group" "rds" {
  name        = "${var.cluster-name}-rds"
  description = "${var.cluster-name}-rds"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  

  tags = {
    Name = "${var.cluster-name}-rds"
  }
}

# bastion과 eks클러스터 내부에서 3306으로 접근 가능하도록 rule설정
resource "aws_security_group_rule" "rds" {
  description       = "${var.cluster-name}-rds allow from basion"
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  source_security_group_id = aws_security_group.bastion.id
  to_port           = 3306
  type              = "ingress"
}
resource "aws_security_group_rule" "cluster-name-rds-cluster" {
  description       = "${var.cluster-name}-rds allow from cluster"
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  source_security_group_id = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  to_port           = 3306
  type              = "ingress"
}
