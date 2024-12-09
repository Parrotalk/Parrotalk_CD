resource "aws_launch_template" "k8s_worker" {
  name        = "k8s-worker-asg-template"
  description = "Clean k8s worker node template"

  image_id      = "ami-07b18726250e22046" # 기존워커노드에서 템플릿 생성
  instance_type = "t3.medium"
  key_name      = "ptk-k8s-key" # 키 지정

  network_interfaces {
    device_index          = 0
    subnet_id             = "subnet-0ca9c4b041d55bb3a" # 워커노드 서브넷
    security_groups       = ["sg-0b89b960e75405341"] # 보안그룹
    delete_on_termination = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 50
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      NodeGroup                     = "worker-node"
      "kubespray-role"             = "kube_node"
      Environment                   = "dev"
      "kubernetes.io/cluster/ptk"   = "owned"
    }
  }
}

resource "aws_autoscaling_group" "k8s_worker" {
  name                = "k8s-worker-asg"
  desired_capacity    = 1
  max_size           = 3
  min_size           = 0
  vpc_zone_identifier = ["subnet-0ca9c4b041d55bb3a"]

  launch_template {
    id      = aws_launch_template.k8s_worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "k8s-worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubespray-role"
    value               = "kube_node"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/ptk"
    value               = "owned"
    propagate_at_launch = true
  }
}