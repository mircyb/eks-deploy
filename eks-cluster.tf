#EKS 클러스터 구성


# eks 에서 사용할 role 생성
resource "aws_iam_role" "eks" {
  name = "${var.cluster-name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
#role에 policy add
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

#클러스터에 추가할 SG설정 bastion에서 모든 포트로 ingress허용 정책 rule을 추가한 sg를 추가하여 클러스터 생성시 ADD함
resource "aws_security_group" "cluster-bastion" {
  name        = "${var.cluster-name}-cluster-bastion"
  description = "Cluster communication with bastion nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster-name}-cluster"
  }
}
#bastion에서 오는 모든 트래픽 허용 정책
resource "aws_security_group_rule" "ingress-bastion" {
  description       = "Allow bastion to communicate with the cluster"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster-bastion.id
  source_security_group_id = aws_security_group.bastion.id
  to_port           = 0
  type              = "ingress"
}

#애드온 변수 선언
variable "addons" {
  type = list(object({
    name    = string
  }))

  default = [
    {
      name    = "kube-proxy"
    },
    {
      name    = "vpc-cni"
    },
    {
      name    = "coredns"
    }
  ]
}
#선언된 애드온 변수 이용하여 애드온 설치
resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name = aws_eks_cluster.eks.name
  addon_name        = each.value.name
  resolve_conflicts = "OVERWRITE"
}
# 클러스터 로그 cloud watch 보관주기 30일 설정
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster-name}/cluster"
  retention_in_days = 30
}
# 클러스터 기본 설정
resource "aws_eks_cluster" "eks" {
  name     = var.cluster-name
  role_arn = aws_iam_role.eks.arn
  version = "1.22" //클러스터 버전 명시
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"] //로깅
  
#클러스터 네트워크 설정
  vpc_config {
    security_group_ids = [aws_security_group.cluster-bastion.id] //클러스터 기본 보안그룹 외 추가할 보안그룹 설정(위에서 만든 BASTION허용 정책을 추가)
    subnet_ids         = concat(aws_subnet.public-subnet[*].id, aws_subnet.private-subnet[*].id)
    endpoint_private_access = true
    endpoint_public_access = true
#api access의 cidr제한을 검 허용할 ip외 nat gateway도 허용하여야 exec,logs 등의 명령어를 쓸수 있음
    public_access_cidrs       = ["110.117.232.147/32", "${aws_eip.eip.public_ip}/32"]
  }
  
# policy의 dependency를 검
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]
}
