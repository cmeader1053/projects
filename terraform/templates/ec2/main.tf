/*
Title = EC2 Terraform Main
Description = Main Terraform document for EC2 instance deployment
*/

# EC2 Instance
resource aws_instance "" {
	ami							= var.os_type == "linux" ? data.aws_ami.linux.id : data.aws_ami.windows.id
	instance_type 				= var.instance_type
	subnet_id					= var.subnet_id
	vpc_security_group_ids		= var.sec_grp_id
	key_name					= var.key_name
	iam_instance_profile		= var.iam_profile
}

# Root EBS Volume 
root_block_device {
	volume_size				= var.root_vol_size
	volume_type				= var.root_vol_type
	encrypted				= true
	delete_on_termination	= true
}

# Tags
tags = merge(var.tags, {
	Name = var.name
	})
}
