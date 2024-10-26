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

# 통합된 K8s 노드 보안그룹
module "k8s_node_sg" {
  source            = "../../modules/security_group"
  sg_name           = "${local.k8s_name_prefix}-node-sg"
  vpc_id            = data.aws_vpc.main.id
  
  ingress_rules = [
    # SSH 접속
    { from_port = 22,    to_port = 22,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow SSH" },
    
    # 웹 서비스 포트
    { from_port = 80,    to_port = 80,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTP" },
    { from_port = 443,   to_port = 443,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTPS" },
    { from_port = 8080,  to_port = 8080,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow 8080" },

    # Kubernetes API 및 컴포넌트
    { from_port = 6443,  to_port = 6443,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Kubernetes API" },
    { from_port = 2379,  to_port = 2380,  protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow etcd" },
    { from_port = 10248, to_port = 10248, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow Kubelet API" },
    { from_port = 10250, to_port = 10252, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow kubelet APIs" },
    { from_port = 10254, to_port = 10254, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow Ingress Controller Health Check" },

    # NodePort 서비스
    { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow NodePort Services" },
    
    # 데이터베이스 포트 (내부 통신용)
    { from_port = 3306,  to_port = 3306,  protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow MySQL" },
    { from_port = 6379,  to_port = 6379,  protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow Redis" },
    { from_port = 27017, to_port = 27017, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow MongoDB" },
    
    # AWS 서비스 포트
    { from_port = 8443,  to_port = 8445,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow AWS services" },
    
    # WebRTC
    { from_port = 3478,  to_port = 3478,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow WebRTC" },
    
    # 클러스터 내부 통신
    { from_port = 0,     to_port = 0,     protocol = "-1",  cidr_blocks = ["172.16.0.0/16"], description = "Allow all internal traffic" }
  ]
  
  tags = merge(local.tags, {
    Name = "${local.k8s_name_prefix}-node-sg",
    NodeType = "k8s-node"
  })
}

# k8s 마스터/워커노드 IAM 역할
module "k8s_master_iam" {
  source              = "../../modules/iam"
  role_name           = "${local.k8s_name_prefix}-master-role"
  policy_name         = "${local.k8s_name_prefix}-master-policy"
  policy_description  = "Policy for master node to manage the cluster"
  policy_actions      = [
    "transcribe:*",
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:DescribeLaunchConfigurations",
    "autoscaling:DescribeTags",
    "ec2:DescribeInstances",
    "ec2:DescribeRegions",
    "ec2:DescribeRouteTables",
    "ec2:DescribeSecurityGroups",
    "ec2:DescribeSubnets",
    "ec2:DescribeVolumes",
    "ec2:DescribeAvailabilityZones",
    "ec2:CreateSecurityGroup",
    "ec2:CreateTags",
    "ec2:CreateVolume",
    "ec2:ModifyInstanceAttribute",
    "ec2:ModifyVolume",
    "ec2:AttachVolume",
    "ec2:AuthorizeSecurityGroupIngress",
    "ec2:CreateRoute",
    "ec2:DeleteRoute",
    "ec2:DeleteSecurityGroup",
    "ec2:DeleteVolume",
    "ec2:DetachVolume",
    "ec2:RevokeSecurityGroupIngress",
    "ec2:DescribeVpcs",
    "elasticloadbalancing:AddTags",
    "elasticloadbalancing:AttachLoadBalancerToSubnets",
    "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
    "elasticloadbalancing:CreateLoadBalancer",
    "elasticloadbalancing:CreateLoadBalancerPolicy",
    "elasticloadbalancing:CreateLoadBalancerListeners",
    "elasticloadbalancing:ConfigureHealthCheck",
    "elasticloadbalancing:DeleteLoadBalancer",
    "elasticloadbalancing:DeleteLoadBalancerListeners",
    "elasticloadbalancing:DescribeLoadBalancers",
    "elasticloadbalancing:DescribeLoadBalancerAttributes",
    "elasticloadbalancing:DetachLoadBalancerFromSubnets",
    "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
    "elasticloadbalancing:ModifyLoadBalancerAttributes",
    "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
    "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
    "elasticloadbalancing:AddTags",
    "elasticloadbalancing:CreateListener",
    "elasticloadbalancing:CreateTargetGroup",
    "elasticloadbalancing:DeleteListener",
    "elasticloadbalancing:DeleteTargetGroup",
    "elasticloadbalancing:DescribeListeners",
    "elasticloadbalancing:DescribeLoadBalancerPolicies",
    "elasticloadbalancing:DescribeTargetGroups",
    "elasticloadbalancing:DescribeTargetHealth",
    "elasticloadbalancing:ModifyListener",
    "elasticloadbalancing:ModifyTargetGroup",
    "elasticloadbalancing:RegisterTargets",
    "elasticloadbalancing:DeregisterTargets",
    "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
    "iam:CreateServiceLinkedRole",
    "kms:DescribeKey",
    "cognito-idp:DescribeUserPoolClient",
    "acm:ListCertificates",
    "acm:DescribeCertificate",
    "acm:RequestCertificate",
    "acm:DeleteCertificate",
    "acm:AddTagsToCertificate",
    "acm:RemoveTagsFromCertificate",
    "acm:UpdateCertificateOptions",
    "acm:ValidateCertificate",
    "iam:ListServerCertificates",
    "iam:GetServerCertificate",
    "waf-regional:GetWebACL",
    "waf-regional:GetWebACLForResource",
    "waf-regional:AssociateWebACL",
    "waf-regional:DisassociateWebACL",
    "wafv2:GetWebACL",
    "wafv2:GetWebACLForResource",
    "wafv2:AssociateWebACL",
    "wafv2:DisassociateWebACL",
    "shield:GetSubscriptionState",
    "shield:DescribeProtection",
    "shield:CreateProtection",
    "shield:DeleteProtection",
    "ec2:DescribeNetworkInterfaces",
    "ec2:DescribeTags",
    "ec2:GetCoipPoolUsage",
    "ec2:DescribeCoipPools",
    "elasticloadbalancing:SetWebAcl",
    "elasticloadbalancing:ModifyRule",
    "elasticloadbalancing:CreateRule",
    "elasticloadbalancing:DeleteRule",
    "elasticloadbalancing:AddListenerCertificates",
    "elasticloadbalancing:RemoveListenerCertificates",
    "iam:ListAttachedRolePolicies",
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:GetRepositoryPolicy",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:BatchGetImage"
  ]

  tags = merge(local.tags, {
      Name = "${local.service_name}-master-iam"
  })
}

# k8s 마스터/워커노드 IAM 역할
module "k8s_worker_iam" {
  source              = "../../modules/iam"
  role_name           = "${local.k8s_name_prefix}-worker-role"
  policy_name         = "${local.k8s_name_prefix}-worker-policy"
  policy_description  = "Policy for worker node to manage the cluster"
  policy_actions      = [
    "ec2:DescribeInstances",
    "ec2:DescribeRegions",
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:GetRepositoryPolicy",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
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
  volume_size                 = 40
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.public_a.id
  security_group_ids          = [module.k8s_node_sg.security_group_id]
  iam_instance_profile        = module.k8s_master_iam.instance_profile_name
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")

  tags = merge(local.tags, {
    Name      = "${local.k8s_name_prefix}-master-node",
    NodeGroup = "master-node",
    NodeType  = "master",
    Role      = "master",
    "kubernetes.io/cluster/${local.service_name}" = "owned"
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
  security_group_ids          = [module.k8s_node_sg.security_group_id]
  iam_instance_profile        = module.k8s_master_iam.instance_profile_name
  user_data                   = filebase64("${path.module}/scripts/user_data.sh")

  tags = merge(local.tags, {
    Name      = "${local.k8s_name_prefix}-${each.key}",
    NodeGroup = "worker-node",
    NodeType  = "worker",
    Role      = "worker",
    "kubernetes.io/cluster/${local.service_name}" = "owned"
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