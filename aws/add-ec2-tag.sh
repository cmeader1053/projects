aws ec2 create-tags \
  --resources $(aws ec2 describe-instances \
    --query "Reservations[].Instances[].InstanceId" \
    --output text) \
  --tags Key=<enter_tag_key>r,Value=<enter_tag_value>
