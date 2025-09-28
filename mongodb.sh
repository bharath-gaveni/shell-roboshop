#!/bin/bash
N="\e[0m"
R="\e[0;31m"
G="\e[0;32m"
Y="\e[0;33m"
Dir_name=$PWD

id =$(id -u)
if [ $? -ne 0 ]; then
    echo "Please execute this script as root user"
    exit 1
fi

log_folder=/var/log/roboshop-script
script_name=$(echo $0 | cut -d "." -f1)
log_file=$log_folder/$script_name.log
start_time=$(date +%s)
echo "script execution start time: $(date)"
mkdir -p $log_folder

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R FAILED $N" | tee -a &>>$log_file
        exit 1
    else
        echo -e "$2 is $G SUCCESS $N" | tee -a &>>$log_file
    fi        
}

cp $Dir_name/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copying the mongo.repo"

dnf install mongodb-org -y 
validate $? "installing mongodb"

systemctl enable mongod 
validate $? "enabled the mongodb"

systemctl start mongod
validate $? "start mongodb"

sed -i '/s/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "Allowing the remote connections to mongodb"

systemctl restart mongod
validate $? "Restart mongodb"

end_time=$(date +%s)
Total_time=$(($end_time-$start_time))
echo "Total time taken to execute the script is $Total_time seconds"







