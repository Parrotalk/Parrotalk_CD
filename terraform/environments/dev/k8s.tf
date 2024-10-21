locals {
  k8s_name_prefix = "${local.service_name}-${local.environment}-k8s"
  k8s_node_group = {
    worker-node-1 = {
      instance_type = "t3.medium"
      volume_size   = 50
      use_public_ip = true
      subnet_id = data.aws_subnet.public_a.id
    },
    worker-node-2 = {
      instance_type = "t3.medium"
      volume_size   = 50
      use_public_ip = true
      subnet_id = data.aws_subnet.public_c.id
    }
  }
}

# 마스터노드 보안그룹 설정
module "k8s_master_sg" {
  source            = "../../modules/security_group"
  sg_name           = "${local.k8s_name_prefix}-master-sg"
  vpc_id            = data.aws_vpc.main.id  # 네트워크 모듈에서 생성된 VPC ID를 참조
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
  tags = merge(local.tags, {
    Name = "${local.k8s_name_prefix}-master-sg"
    NodeType = "master"
  })
}

# 워커노드 보안그룹 설정
module "k8s_worker_sg" {
  source            = "../../modules/security_group"
  sg_name           = "${local.k8s_name_prefix}-worker-sg"
  vpc_id            = data.aws_vpc.main.id  # 네트워크 모듈에서 생성된 VPC ID를 참조
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
  tags = merge(local.tags, {
      Name = "${local.k8s_name_prefix}-worker-sg",
      NodeType = "worker"
  })
}

# k8s 마스터/워커노드 IAM 역할 
module "k8s_master_iam" {
  source              = "../../modules/iam"
  role_name           = "${local.k8s_name_prefix}-master-role"
  policy_name         = "${local.k8s_name_prefix}-master-policy"
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

  tags = merge(local.tags, {
      Name = "${local.service_name}-master-iam"
  })
}

module "k8s_worker_iam" {
  source              = "../../modules/iam"
  role_name           = "${local.k8s_name_prefix}-worker-role"
  policy_name         = "${local.k8s_name_prefix}-worker-policy"
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

  tags = merge(local.tags, {
      Name = "${local.service_name}-worker-iam"
  })
}

# 마스터노드 생성
module "k8s_master_node" {
  service_name                = local.service_name
  environment                 = local.environment
  source                      = "../../modules/ec2"

  key_name                    = "ptk-k8s-key"
  instance_type               = "t3.medium"
  volume_size                 = 50
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.public_a.id
  security_group_ids          = [module.k8s_master_sg.security_group_id]
  iam_instance_profile        = module.k8s_master_iam.instance_profile_name
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")

  tags = merge(local.tags, {
    Name      = "${local.k8s_name_prefix}-master-node",
    NodeGroup = "master-node",
    NodeType  = "master",
    Role      = "master"
  })
}

resource "aws_ebs_volume" "master_etcd_volume" {
  availability_zone = data.aws_subnet.public_a.availability_zone
  size              = 20
  type              = "gp3"
  
  tags = merge(local.tags, {
    Name = "${local.k8s_name_prefix}-master-etcd-volume"
  })
}

resource "aws_volume_attachment" "master_etcd_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.master_etcd_volume.id
  instance_id = module.k8s_master_node.instance_id
}

# 워커노드 생성
module "k8s_worker_nodes" {
  service_name                = local.service_name
  environment                 = local.environment
  source                      = "../../modules/ec2"

  for_each                    = local.k8s_node_group
  
  key_name                    = "ptk-k8s-key"
  instance_type               = each.value.instance_type
  volume_size                 = each.value.volume_size
  associate_public_ip_address = each.value.use_public_ip
  subnet_id                   = each.value.subnet_id
  security_group_ids          = [module.k8s_worker_sg.security_group_id]
  iam_instance_profile        = module.k8s_master_iam.instance_profile_name
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")

  tags = merge(local.tags, {
    Name      = "${local.k8s_name_prefix}-${each.key}",
    NodeGroup = "worker-node",
    NodeType  = "worker",
    Role      = "worker"
  })
}

# 마스터 노드 출력
output k8s_master_node {
  description = "Master node details"
  value = {
    instance_name = "${local.k8s_name_prefix}-master"
    public_ip     = module.k8s_master_node.public_ip
    private_ip    = module.k8s_master_node.private_ip
  }
}

# 워커 노드 출력
output k8s_worker_nodes {
  description = "Worker nodes details"
  value = {
    for key, node in module.k8s_worker_nodes : key => {
      instance_name = "${local.k8s_name_prefix}-${key}"
      public_ip     = node.public_ip
      private_ip    = node.private_ip
    }
  }
}
