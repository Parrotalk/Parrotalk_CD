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

## etcd용 볼륨 추가 ## 

resource "aws_ebs_volume" "master_etcd_volume" {
  availability_zone = data.aws_subnet.public_a.availability_zone
  size              = 10
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

## 로드밸런서 추가 ##

# 로드 밸런서 보안 그룹 설정
module "k8s_lb_sg" {
  source            = "../../modules/security_group"
  sg_name           = "${local.k8s_name_prefix}-lb-sg"
  vpc_id            = data.aws_vpc.main.id  # 네트워크 모듈에서 생성된 VPC ID를 참조
  ingress_rules = [
    { from_port = 80,    to_port = 80,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTP" },
    { from_port = 443,   to_port = 443,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTPS" }
  ]
  tags = merge(local.tags, {
      Name = "${local.k8s_name_prefix}-lb-sg",
      NodeType = "load-balancer"
  })
}

# ALB 리소스
resource "aws_lb" "k8s_alb" {
  name               = "${local.k8s_name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.k8s_lb_sg.security_group_id]
  subnets            = [data.aws_subnet.public_a.id, data.aws_subnet.public_c.id]

  tags = merge(local.tags, {
    Name = "${local.k8s_name_prefix}-alb"
  })
}

# ALB 리스너 설정 (HTTP)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.k8s_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_tg.arn
  }
}

# 타겟 그룹 설정
resource "aws_lb_target_group" "k8s_tg" {
  name     = "${local.k8s_name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    path                = "/healthz"   # Nginx Ingress 컨트롤러의 헬스체크 경로
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = merge(local.tags, {
    Name = "${local.k8s_name_prefix}-tg"
  })
}


# EBS 볼륨 이름을 output으로 저장
output "master_etcd_volume_name" {
  description = "The name of the EBS volume for etcd on the master node"
  value       = "${local.k8s_name_prefix}-master-etcd-volume"
}

# 워커 노드를 타겟 그룹에 등록
resource "aws_lb_target_group_attachment" "worker_node" {
  for_each        = module.k8s_worker_nodes
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = each.value.instance_id
  port             = 80  # 워커 노드로 트래픽 전달
}

# 로드밸런서 이름 출력
output "lb_name" {
  description = "The name of the Application Load Balancer"
  value       = aws_lb.k8s_alb.name
}