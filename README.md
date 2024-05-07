Deploy an End-to-End Solution in AWS by Terraform

Today we are going to deploy an End-to-End Solution on AWS by setting up an environment using Amazon EC2, Amazon VPC, Amazon Auto Scaling, Amazon S3, AWS Cloud 9, Amazon RDS, AWS IAM, Amazon Load Balancing.

Create a Virtual Private Cloud (VPC) environment:

* Go to the VPC console in the AWS Management Console and click on “Create VPC”.
* Enter the required details such as VPC name, CIDR block, and Tenancy.
* Create two subnets within the VPC, one for the public-facing EC2 instance and the other for the private database instance.
* Create an Internet Gateway and attach it to the VPC to allow incoming and outgoing traffic.

<h1 align="center">Project Architecture</h1>
<a target="_blank" rel="noreferrer"> <img src="https://github.com/girobh/AWS_IaC_Metro_College/blob/main/Terraform%20Projects_AWS-rev01-01.png" alt="metroc"/> </a>
<a target="_blank" rel="noreferrer"> <img src="https://github.com/girobh/AWS_IaC_Metro_College/blob/main/Terraform%20Projects_AWS-rev01-02.png" alt="metroc"/> </a>
