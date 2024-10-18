locals {
  jenkins_name_prefix = "${local.service_name}-${local.environment}-jenkins"
  user_data_file = "../../modules/ec2/user_data.sh"
  jenkins_node_group = {
    worker-node-1 = {
      instance_type = "t2.medium"
      volume_size   = 50
      use_public_ip = true
      subnet_id = data.aws_subnet.public_a.id
    },
    worker-node-2 = {
      instance_type = "t2.medium"
      volume_size   = 50
      use_public_ip = true
      subnet_id = data.aws_subnet.public_c.id
    }
  }
}

# 마스터노드 보안그룹 설정
module "jenkins_master_sg" {
  source            = "../../modules/security_group"
  sg_name           = "${local.jenkins_name_prefix}-master-sg"
  vpc_id            = data.aws_vpc.main.id  # 네트워크 모듈에서 생성된 VPC ID를 참조
  ingress_rules = [
    { from_port = 22,    to_port = 22,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow SSH" },
    { from_port = 8080,  to_port = 8080,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow 8080" },
    { from_port = 50000, to_port = 50000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Jenkins agent communication on port 50000" }
  ]
  tags = merge(local.tags, {
    Name = "${local.jenkins_name_prefix}-master-sg"
  })
}

# 워커노드 보안그룹 설정
module "jenkins_worker_sg" {
  source            = "../../modules/security_group"
  sg_name           = "${local.jenkins_name_prefix}-worker-sg"
  vpc_id            = data.aws_vpc.main.id  # 네트워크 모듈에서 생성된 VPC ID를 참조
  ingress_rules = [
    { from_port = 22,    to_port = 22,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow SSH" },
    { from_port = 50000, to_port = 50000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Jenkins agent communication on port 50000" }
  ]
  tags = merge(local.tags, {
    Name = "${local.jenkins_name_prefix}-worker-sg"
  })
}

# jenkins Policy
module "jenkins_user_policy" {
  source                = "../../modules/iam"
  role_name             = "${local.jenkins_name_prefix}-user-role"
  policy_name           = "${local.jenkins_name_prefix}-user-policy"
  policy_description    = "Policy for jenkins access to AWS services"
  policy_actions        = [
    "ec2:DescribeInstances",
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:UpdateAutoScalingGroup",
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",
    "iam:PassRole",
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage"
  ]

  tags = merge(local.tags, {
    Name = "${local.jenkins_name_prefix}-user-iam"
  })
}

# 마스터노드 생성
module "jenkins_master_node" {
  service_name                = local.service_name
  environment                 = local.environment
  source                      = "../../modules/ec2"

  key_name                    = "ptk-jenkins-key"
  instance_type               = "t2.medium"
  volume_size                 = 30
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.public_a.id
  security_group_ids          = [module.jenkins_master_sg.security_group_id]
  iam_instance_profile        = null
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")

  tags = merge(local.tags, {
    Name      = "${local.jenkins_name_prefix}-master-node",
    NodeGroup = "master-node",
    NodeType  = "master",
    Role      = "master"
  })
}

# 워커노드 생성
module "jenkins_worker_nodes" {
  service_name                = local.service_name
  environment                 = local.environment
  source                      = "../../modules/ec2"

  for_each                    = local.jenkins_node_group

  key_name                    = "ptk-jenkins-key"
  instance_type               = each.value.instance_type
  volume_size                 = each.value.volume_size
  associate_public_ip_address = each.value.use_public_ip
  subnet_id                   = each.value.subnet_id
  security_group_ids          = [module.jenkins_worker_sg.security_group_id]
  iam_instance_profile        = null
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")

  tags = merge(local.tags, {
    Name      = "${local.jenkins_name_prefix}-${each.key}",
    NodeGroup = "worker-node",
    NodeType  = "worker",
    Role      = "worker"
  })
}

# 마스터 노드 출력
output jenkins_master_node {
  description = "Master node details"
  value = {
    instance_name = "${local.jenkins_name_prefix}-master"
    public_ip     = module.jenkins_master_node.public_ip
    private_ip    = module.jenkins_master_node.private_ip
  }
}

# 워커 노드 출력
output jenkins_worker_nodes {
  description = "Worker nodes details"
  value = {
    for key, node in module.jenkins_worker_nodes : key => {
      instance_name = "${local.jenkins_name_prefix}-${key}"
      public_ip     = node.public_ip
      private_ip    = node.private_ip
    }
  }
}
