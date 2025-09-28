#!/bin/bash
N="\e[0m"
R="\e[0;31m"
G="\e[0;32m"
Y="\e[0;33m"
Dir_name=$PWD
Host_name=mongodb.bharathgaveni.fun

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

dnf module disable nodejs -y &>>$log_file
validate $? "Disabled the nodejs"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "Enabled the nodejs 20"

mkdir -p /app &>>$log_file
validate $? "created the app directory" 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
validate $? "dowloading the catalogue code"

cd /app &>>$log_file
validate $? "changing to app directory"

rm -rf /app/* &>>$log_file
validate $? "removing the existing code in app directory"

unzip /tmp/catalogue.zip &>>$log_file
validate $? "unzip the catalogue code in app directory"

cd /app &>>$log_file
validate $? "changing to app directory"

npm install &>>$log_file
validate $? "installing the dependencies for node"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo -e "User already exists so $Y SKIPPING.. $N"
fi

cp $Dir_name/catalogue.service /etc/systemd/system/catalogue.service &>>$log_file
validate $? "Setting the systemd service for catalogue"

systemctl daemon-reload &>>$log_file
validate $? "Deamon reload of catalogue to recognise the newly created service"

systemctl enable catalogue &>>$log_file
validate $? "enabled the catalogue"

systemctl start catalogue &>>$log_file
validate $? "started the catalogue"

cp $Dir_name/mongo.repo /etc/yum.repos.d/mongo.repo &>>$log_file
validate $? "copying the mongo.repo"

dnf install mongodb-mongosh -y &>>$log_file
validate $? "installing mongodb cilent to connect with mongodb DB"

index=$(mongosh $Host_name --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $index -le 0 ]; then
mongosh --host $Host_name </app/db/master-data.js
else
    echo "Database is already loaded with Catalogue DB products"
fi

end_time=$(date +%s)
Total_time=$(($end_time-$start_time))
    echo "Time taken for script to execute is $Total_time seconds" | tee -a $log_file





