#!/bin/bash
N="\e[0m"
R="\e[0;31m"
G="\e[0;32m"
Y="\e[0;33m"
Dir_name=$pwd

id=$(id -u)

if [ $id -ne 0 ]; then
    echo -e "$R Please execute this script as a root user $N"
    exit 1
fi
log_folder=/var/log/roboshop-script
script_name=$(echo $0 | cut -d "." -f1)
log_file=$($log_folder/$script_name.log)
 echo "script execution start at time $(date)"
 mkdir -p $log_folder
Validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is  $R failed $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 is $G success $N" | tee -a $log_file
    fi        
}

cp $Dir_name/mongo.repo /etc/yum.repos.d/mongo.repo
Validate $? "copying the mongo.repo"

dnf install mongodb-org -y
Validate $? "installing mongodb" 

systemctl enable mongod
Validate $? "enabled mongodb"

systemctl start mongod 
Validate $? "started mongodb"

sed 's/127.0.0.1/0.0.0.0' /etc/mongod.conf




