<h1 align="center">Deploy an End-to-End Solution in AWS by Terraform</h1>

Today we are going to deploy an End-to-End Solution on AWS by setting up an environment using Amazon EC2, Amazon VPC, Amazon Auto Scaling, Amazon S3, AWS Cloud 9, Amazon RDS, AWS IAM, Amazon Load Balancing.

Resources:

* VPC with 2 Subnets (public), IGW, Route-Table-with-Route (IGW), Subnet-Association-with-route-table
* 1 SG for EC2 (22, 80 for all)
* 1 SG for ALB (80 for all)
* 1 SG for RDS (3306 for all)
* 1 ASG launch Template
* 1 AutoScal
* Ing Group with 2 EC2 Min
* ALB-Target-Group
* ALB (2 Public Subnet)
* S3 Bucket-Priv
* ate [Override- Pass -var]
* IAM Role (Assumed by EC2)
* IAM Policy (S3:* FullAccess)
  
<a target="_blank" rel="noreferrer"> <img src="https://github.com/girobh/AWS_IaC_Metro_College/blob/main/Terraform%20Projects_AWS-rev01-01.png" alt="metroc"/> </a>
<a target="_blank" rel="noreferrer"> <img src="https://github.com/girobh/AWS_IaC_Metro_College/blob/main/Terraform%20Projects_AWS-rev01-02.png" alt="metroc"/> </a>
