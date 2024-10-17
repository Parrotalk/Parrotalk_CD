# 공통 리전 설정
provider "aws" {
  region = var.region
}

locals {
  service_name  = var.service_name
  environment   = var.environment
  name_prefix   = "${var.service_name}-${var.environment}"
}

# 네트워킹 설정 (VPC 등 네트워크 관련 설정)
module "networking" {
  source      = "./modules/networking"
  service_name = local.service_name
}

# transcribe 테스트용
module "test_transcribe" {
  source = "./modules/test_transcribe"
  service_name = local.service_name
  environment = local.environment
}

# 마스터노드 보안그룹 설정
module "master_sg" {
  source            = "./modules/security_group"
  sg_name           = "${local.service_name}-master-sg"
  vpc_id            = module.networking.vpc_id  # 네트워크 모듈에서 생성된 VPC ID를 참조
  ingress_rules = [
    { from_port = 22,    to_port = 22,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow SSH" },
    { from_port = 8080,  to_port = 8080,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow 8080" },
    { from_port = 6443,  to_port = 6443,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Kubernetes API" },
    { from_port = 2379,  to_port = 2380,  protocol = "tcp", cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow etcd from VPC and Pod Network" },
    { from_port = 10250, to_port = 10252, protocol = "tcp", cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow kubelet, controller manager, and scheduler from VPC and Pod Network" },
    { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow NodePort" },
    { from_port = 53,    to_port = 53,    protocol = "tcp", cidr_blocks = ["172.16.0.0/16"], description = "Allow DNS (CoreDNS) TCP from Pod Network" },
    { from_port = 53,    to_port = 53,    protocol = "udp", cidr_blocks = ["172.16.0.0/16"], description = "Allow DNS (CoreDNS) UDP from Pod Network" },
    { from_port = 0,     to_port = 0,     protocol = "-1",  cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow all traffic from VPC and Pod Network" }
  ]
  tags = merge(var.tags, {
      Name = "${local.service_name}-master-sg",
      NodeType = "master"
  })
}

# 워커노드 보안그룹 설정
module "worker_sg" {
  source            = "./modules/security_group"
  sg_name           = "${local.service_name}-worker-sg"
  vpc_id            = module.networking.vpc_id  # 네트워크 모듈에서 생성된 VPC ID를 참조
  ingress_rules = [
    { from_port = 22,    to_port = 22,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow SSH" },
    { from_port = 80,    to_port = 80,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTP" },
    { from_port = 443,   to_port = 443,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTPS" },
    { from_port = 8080,  to_port = 8080,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Tomcat" },
    { from_port = 8443,  to_port = 8445,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow AWS services" },
    { from_port = 3478,  to_port = 3478,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow WebRTC (STUN/TURN)" },
    { from_port = 6379,  to_port = 6379,  protocol = "tcp", cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow Redis" },
    { from_port = 27017, to_port = 27017, protocol = "tcp", cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow MongoDB" },
    { from_port = 3306,  to_port = 3306,  protocol = "tcp", cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow MySQL" },
    { from_port = 10248, to_port = 10248, protocol = "tcp", cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow Kubelet API" },
    { from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow Kubelet API" },
    { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow NodePort Services" },
    { from_port = 0,     to_port = 0,     protocol = "-1",  cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16"], description = "Allow all traffic from VPC and Pod Network" }
  ]

  tags = merge(var.tags, {
      Name = "${local.service_name}-sg",
      NodeType = "worker"
  })
}

# 마스터/워커노드 IAM 역할 
module "master_iam" {
  source              = "./modules/iam"
  role_name           = "${local.service_name}-master-role"
  policy_name         = "${local.service_name}-master-policy"
  policy_description  = "Policy for master node to manage the cluster"
  policy_actions      = [
    "ec2:DescribeInstances",
    "autoscaling:*",
    "elasticloadbalancing:*",
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage"
  ]

  tags = merge(var.tags, {
      Name = "${local.service_name}-master-iam",
      NodeType = "master"
  })
}

module "worker_iam" {
  source              = "./modules/iam"
  role_name           = "${local.service_name}-worker-role"
  policy_name         = "${local.service_name}-worker-policy"
  policy_description  = "Policy for worker node to access necessary AWS services"
  policy_actions      = [
    "s3:GetObject",
    "s3:PutObject",
    "cloudwatch:PutMetricData",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage"
  ]

  tags = merge(var.tags, {
      Name = "${local.service_name}-worker-iam",
      NodeType = "worker"
  })
}

# 기존에 만들어둔 subnet 가져오기
data "aws_subnets" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${local.service_name}-subnet-*"]
  }
}

# 마스터 노드 생성 (단일)
# terraform plan -target=module.master_node -var-file="environments/test.tfvars"
module "master_node" {
  service_name                = local.service_name
  environment                 = local.environment
  source                      = "./modules/ec2"

  key_name                    = var.key_name
  instance_type               = var.master_instance_type
  volume_size                 = var.master_volume_size
  associate_public_ip_address = var.master_use_public_ip
  subnet_id                   = module.networking.subnet_public_a_id # 기본 영역
  security_group_ids          = [module.master_sg.security_group_id]
  iam_instance_profile        = module.master_iam.instance_profile_name

  user_data                   = filebase64(var.user_data_file)

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-node-master",
    NodeGroup = "master-node",
    NodeType  = "master",
    Role      = "master"
  })
}

# 워커노드 생성
module "worker_nodes" {
  service_name                = local.service_name
  environment                 = local.environment
  source                      = "./modules/ec2"

   # 워커노드는 리스트로 돌림
  for_each                    = var.node_groups

  key_name                    = var.key_name
  instance_type               = each.value.instance_type
  volume_size                 = each.value.volume_size
  associate_public_ip_address = each.value.use_public_ip
  subnet_id = try(
    data.aws_subnets.selected.ids[lookup(each.value, "subnet_tag_name", null)],
    module.networking.subnet_public_a_id  # 기본 서브넷 ID
  )
  security_group_ids          = [module.worker_sg.security_group_id]
  iam_instance_profile        = module.worker_iam.instance_profile_name
  user_data                   = filebase64(var.user_data_file)

  tags = merge(var.tags, {
    Name      = "${local.name_prefix}-node-${each.key}",
    NodeGroup = "worker-node",
    NodeType  = "worker",
    Role      = "worker"
  })
}

# 마스터 노드 출력
output "master_node" {
  description = "Master node details"
  value = {
    instance_name = "${local.name_prefix}-node-master"
    public_ip     = module.master_node.public_ip
    private_ip    = module.master_node.private_ip
  }
}

# 워커 노드 출력
output "worker_nodes" {
  description = "Worker nodes details"
  value = {
    for key, node in module.worker_nodes : key => {
      instance_name = "${local.name_prefix}-node-${key}"
      public_ip     = node.public_ip
      private_ip    = node.private_ip
    }
  }
}