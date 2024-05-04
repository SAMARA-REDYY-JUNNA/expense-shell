#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "please enter DB password:"
read -s mysql_root_password

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2..$R FAILURE $N"
       exit 1
    else
       echo -e "$2...$G SUCCESS $N"
    fi      
}

if [ $USERID -ne 0 ]
then
    echo "please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "you are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "enabling nodeja"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "installing nodejs"

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
useradd expense &>>$LOGFILE
VALIDATE $? "creating expense user"
else 
echo  -e "expense user already created..$Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "downloading backend code"
 
 cd /app &>>$LOGFILE
 unzip /tmp/backend.zip
 VALIDATE $? "extracted backend code"

 npm install &>>$LOGFILE
 VALIDATE $? "installing nodejs dependencies"

 cp /home/ec2-user/expense-shell/backend.service /etc/system/backend.service &>>$LOGFILE
 VALIDATE $? "copied backend service"

 systemctl daemon-reload &>>$LOGFILE
 VALIDATE $? "daemon reload"

 systemctl start backend &>>$LOGFILE
 VALIDATE $? "starting backend"

 systemctl enable backend &>>$LOGFILE
 VALIDATE $? "enabling backend"

 dnf install mysql -y &>>$LOGFILE
 VALIDATE $? "installing mysql client"

 mysql -h db.mydaws.online -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
 VALIDATE $? "schema loading"

 systemctl restart backend &>>$LOGFILE
 VALIDATE $? "restarting backend"
