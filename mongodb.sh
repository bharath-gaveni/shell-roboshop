#!/bin/bash
N="\e[0m"
R="\e[0;31m"
G="\e[0;32m"
Y="\e[0;33m"
Dir_name=$PWD

id=$(id -u)
if [ $id -ne 0 ]; then
    echo -e "$R Please execute this script as root user $N"
    exit 1
fi

log_folder=/var/log/roboshop-script
script_name=$(echo $0 | cut -d "." -f1)
log_file=$log_folder/$script_name.log
start_time=$(date +%s)
mkdir -p $log_folder
echo "script execution start time: $(date)" | tee -a $log_file

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R FAILED $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 is $G SUCCESS $N" | tee -a $log_file
    fi        
}

cp $Dir_name/mongo.repo /etc/yum.repos.d/mongo.repo &>>$log_file
validate $? "Copying the mongo.repo" 

dnf install mongodb-org -y &>>$log_file
validate $? "installing mongodb" 

systemctl enable mongod &>>$log_file
validate $? "enabled the mongodb" 

systemctl start mongod &>>$log_file
validate $? "start mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$log_file
validate $? "Allowing the remote connections to mongodb"

systemctl restart mongod &>>$log_file
validate $? "Restart mongodb"

end_time=$(date +%s)
Total_time=$(($end_time-$start_time))
echo "Total time taken to execute the script is $Total_time seconds" | tee -a $log_file







