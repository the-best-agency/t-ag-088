resource "aws_autoscaling_group" "ASG" {
  vpc_zone_identifier = [aws_subnet.PublicSubnet1.id]

  desired_capacity   = 1
  max_size           = 3
  min_size           = 1

  target_group_arns = [ aws_lb_target_group.LBTargetGroup.arn ]
  launch_template {
    id      = aws_launch_template.LaunchTemplate.id
    version = aws_launch_template.LaunchTemplate.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.EnvironmentName}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Group"
    value               = "${var.GroupStaff}"
    propagate_at_launch = true
  }
  tag {
    key                 = "ResourceOwner"
    value               = "Oleksandr"
    propagate_at_launch = false
  }


}

  # ================== Scaling Policy =================
resource "aws_autoscaling_policy" "myALBRequestCountPolicy" {
  name                   = "myALBRequestCountPolicy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.ASG.name
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${aws_lb.ApplicationLoadBalancer.arn_suffix}/${aws_lb_target_group.LBTargetGroup.arn_suffix}"
    }
    target_value = 10
  }

}

# ======== Key pair =======
resource "tls_private_key" "simplekeypair" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "ghost_ec2_pool_tf" {
  key_name   = "simplekeypair"
  public_key = tls_private_key.simplekeypair.public_key_openssh
}

  # ================== Launch Template =================
resource "aws_launch_template" "LaunchTemplate" {
  name = "${var.EnvironmentName}-launch-template"

  image_id = var.ImageId
  instance_type = "t2.micro"
  key_name = aws_key_pair.ghost_ec2_pool_tf.key_name
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ aws_security_group.ec2poolSG.id ]
    device_index = 0
  }

  user_data = "${base64encode(data.template_file.lt_asg.rendered)}"


}

data "template_file" "lt_asg" {
  template = <<EOF
  #!/bin/bash -xe
  sudo yum update -y
  
  export AWS_ACCESS_KEY_ID=#
  export AWS_SECRET_ACCESS_KEY=#
  export AWS_DEFAULT_REGION=#
  
  # Install php
  sudo amazon-linux-extras install php8.0
  # MySQL Installation
  sudo wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
  sudo rpm -Uvh mysql80-community-release-el7-3.noarch.rpm
  sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
  sudo yum --enablerepo=mysql80-community install -y mysql-community-server
  sudo systemctl start mysqld
  
  sudo yum install -y httpd
  sudo systemctl start httpd
  sudo systemctl enable httpd
  sudo service httpd start
  sudo chkconfig httpd on
  sudo usermod -a -G apache ec2-user
  
  sudo chown -R ec2-user:apache /var/www
  sudo chmod 2775 /var/www
  find /var/www -type d -exec sudo chmod 2775 {} \;
  find /var/www -type f -exec sudo chmod 0664 {} \;
  
  cd /var/www/html
  aws s3 cp --recursive s3://sanpaolo .
  mkdir inc && cd $_
  >dbinfo.inc
  EOF
  vars = {
    #DBInstanceEndpoint = 
    #DBUsername = var.DBUser
    #DBPassword = var.DBPassword
    DBDatabase = "datadb"
    #AccAccessKeyID = var.AccAccessKeyID
    #AccSecretAccessKeyID = var.SecretAccAccessKeyID
    #AccDefaultRegion = var.AccDefaultRegion
  }
}
