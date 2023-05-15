resource "aws_autoscaling_group" "ASG" {
  vpc_zone_identifier = [aws_subnet.PublicSubnet1.id, aws_subnet.PublicSubnet2.id]

  desired_capacity    = 1
  max_size            = 2
  min_size            = 1


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
  #!/bin/bash

  sudo yum update -y
  sudo yum install -y httpd php git
  
  cd /var/www/html
  sudo mkdir -p .ssh
  sudo chmod 700 .ssh
  sudo echo "${PrivateSSHKey}" > .ssh/id_rsa
  sudo chmod 400 .ssh/id_rsa

  sudo ssh-keyscan github.com >> .ssh/known_hosts
  sudo chown -R ec2-user:ec2-user .ssh
  cd /home/ec2-user
  sudo git clone ${SourceCodeMLink}
  cd YOUR_PRIVATE_REPO

  sudo mv about.php book.php home.php package.php /var/www/html/
  sudo mv images/ /var/www/html/
  sudo chown -R apache:apache /var/www/html /var/www/html/images
  sudo chmod -R 755 /var/www/html /var/www/html/images

  sudo systemctl start httpd
  sudo systemctl enable httpd
  EOF
  vars = {
    PrivateSSHKey = var.PrivateSSHKey
    SourceCodeMLink = var.SourceCodeMLink
  }
}
