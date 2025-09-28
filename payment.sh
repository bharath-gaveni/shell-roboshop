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

dnf install python3 gcc python3-devel -y $log_file
validate $? "installing python"

mkdir -p /app &>>$log_file
validate $? "created the app directory" 

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$log_file
validate $? "dowloading the payment code"

cd /app &>>$log_file
validate $? "changing to app directory"

rm -rf /app/* &>>$log_file
validate $? "removing the existing code in app directory"

unzip /tmp/payment.zip &>>$log_file
validate $? "unzip the payment code in app directory"

cd /app &>>$log_file
validate $? "changing to app directory"

pip3 install -r requirements.txt &>>$log_file
validate $? "installing dependencies"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo -e "User already exists so $Y SKIPPING.. $N"
fi

cp $Dir_name/payment.service /etc/systemd/system/payment.service &>>$log_file
validate $? "Setting the systemd service for payment"

systemctl daemon-reload &>>$log_file
validate $? "Deamon reload of payment to recognise the newly created service"

systemctl enable payment &>>$log_file
validate $? "enabled the payment"

systemctl start payment &>>$log_file
validate $? "started the payment"

end_time=$(date +%s)
Total_time=$(($end_time-$start_time))
    echo "Time taken for script to execute is $Total_time seconds" | tee -a $log_file





