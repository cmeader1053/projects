# This bash script can be ran in the aws cli to add a tag key and value to ALL ec2 instances

aws ec2 create-tags \
  --resources $(aws ec2 describe-instances \
    --query "Reservations[].Instances[].InstanceId" \
    --output text) \
  --tags Key=<enter_tag_key>r,Value=<enter_tag_value>
