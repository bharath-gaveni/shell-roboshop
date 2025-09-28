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

dnf module disable nginx -y &>>$log_file
validate $? "disable nginx"

dnf module enable nginx:1.24 -y &>>$log_file
validate $? "enable nginx"

dnf install nginx -y &>>$log_file
validate $? "installing nginx"

systemctl enable nginx &>>$log_file
validate $? "enabled the nginx"

systemctl start nginx &>>$log_file
validate $? "started the nginx"

rm -rf /usr/share/nginx/html/* &>>$log_file
validate $? "removing the existing code"

curl -L -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
validate $? "dowloading the frontend nginx code"

cd /usr/share/nginx/html &>>$log_file
validate $? "changing directory"

unzip /tmp/frontend.zip &>>$log_file
validate $? "unzip the frontend nginx code"

cp $Dir_name/nginx.conf /etc/nginx/nginx.conf &>>$log_file
validate $? "Reverese proxy setup for frontend nginx"

systemctl restart nginx &>>$log_file
validate $? "Re-started the nginx"

end_time=$(date +%s)
Total_time=$(($end_time-$start_time))
    echo "Time taken for script to execute is $Total_time seconds" | tee -a $log_file





