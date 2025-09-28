#!/bin/bash
N="\e[0m"
R="\e[0;31m"
G="\e[0;32m"
Y="\e[0;33m"
Dir_name=$PWD

id=$(id -u)
if [ $id -ne 0 ]; then
    echo -e "$R please run this script with root user $N"
    exit 1
fi

log_folder=/var/log/roboshop-script
script_name=$(echo $0 | cut -d "." -f1)
log_file=$log_folder/$script_name.log
start_time=$(date +%s)

echo "execution of script starts at $(date)"

mkdir -p $log_folder

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R FAILED $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 is $G SUCCESS $N" | tee -a $log_file
    fi        
}

cp $Dir_name/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$log_file
validate $? "copying the repo"

dnf install rabbitmq-server -y &>>$log_file
validate $? "installing the rabbitmq"

systemctl enable rabbitmq-server &>>$log_file
validate $? "enabling the rabbitmq"

systemctl start rabbitmq-server &>>$log_file
validate $? "start the rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>>$log_file
validate $? "setting user and password"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" 
validate $? "setting up permissions to take que message from all components"

end_time=$(date +%s)
Total_time=$(($end_time-$start_time))
    echo "Time taken for script to execute is $Total_time seconds" | tee -a $log_file