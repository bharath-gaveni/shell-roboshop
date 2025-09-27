#!/bin/bash

AMI_ID=ami-09c813fb71547fc4f
SG_ID=sg-0e84bdd3fbd61aac4
DNS=bharathgaveni.fun
Host_zone=Z00567342XXYQ4M01AREL

for instance in $*
do

instance_id=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$instance}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

    if [ $instance != frontned ]; then
       IP=$(aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)
        Record_name=$instance.$DNS
    else
        IP=$(aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)
    Record_name=$DNS
    fi

    echo "$instance :$IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $Host_zone \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$Record_name",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [{ "Value": "$IP" }]
            }
        }]
    }'
done
