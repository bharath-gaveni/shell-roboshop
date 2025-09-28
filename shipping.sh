#!/bin/bash
N="\e[0m"
R="\e[0;31m"
G="\e[0;32m"
Y="\e[0;33m"
Dir_name=$PWD
Host_name=mysql.bharathgaveni.fun

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

dnf install maven -y
validate $? "installing maven which also install java"

mkdir -p /app &>>$log_file
validate $? "created the app directory" 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
validate $? "dowloading the shipping code"

cd /app &>>$log_file
validate $? "changing to app directory"

rm -rf /app/* &>>$log_file
validate $? "removing the existing code in app directory"

unzip /tmp/shipping.zip &>>$log_file
validate $? "unzip the shipping code in app directory"

cd /app &>>$log_file
validate $? "changing to app directory"

mvn clean package &>>$log_file
validate $? "install dependecies and package application in to .jar file"

mv target/shipping-1.0.jar shipping.jar &>>$log_file
validate $? "moving the .jar file to current directory means /app"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo -e "User already exists so $Y SKIPPING.. $N"
fi

cp $Dir_name/shipping.service /etc/systemd/system/shipping.service &>>$log_file
validate $? "Setting the systemd service for shipping"

systemctl daemon-reload &>>$log_file
validate $? "Deamon reload of shipping to recognise the newly created service"

systemctl enable shipping &>>$log_file
validate $? "enabled the shipping"

systemctl start shipping &>>$log_file
validate $? "started the shipping"

dnf install mysql -y &>>$log_file
validate $? "installing mysql client to load data to mysql DB"

mysql -h $Host_name -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $Host_name -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $Host_name -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $Host_name -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo "Shipping data is already loaded"
fi       

systemctl restart shipping &>>$log_file
validate $? "Restarting the shipping"

end_time=$(date +%s)
Total_time=$(($end_time-$start_time))
    echo "Time taken for script to execute is $Total_time seconds" | tee -a $log_file





