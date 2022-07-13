#EKS WORKER 노드 설정


# 워커노드에서 사용할 role 생성
resource "aws_iam_role" "node" {
  name = "${var.cluster-name}-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


#생성한 role에 policy 할당
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}


#asg는 nodegroup으로 인해 자동으로 생성되나 name을 설정해주기 위해 tag만 지정하여줌
resource "aws_autoscaling_group_tag" "c6i-2xlarge" {

  autoscaling_group_name = aws_eks_node_group.c6i-2xlarge.resources[0].autoscaling_groups[0].name

  tag {
    key   = "Name"
    value = "${var.cluster-name}-node"
    propagate_at_launch = true
  }
}


# c6i 2xlarge node group
resource "aws_eks_node_group" "c6i-2xlarge" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster-name}-c6i-2xlarge"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private-subnet[*].id
  instance_types = ["c6i.2xlarge"]
  disk_size = 50

  labels = {
    "role" = "${var.cluster-name}-c6i-2xlarge"
  }

  scaling_config {
    desired_size = 3
    min_size     = 3
    max_size     = 10
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "Name" = "${var.cluster-name}-c6i-2xlarge-Node",
    "Names" = "${var.cluster-name}-c6i-2xlarge-Node"
  }
}

