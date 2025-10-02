# AWS Cheat Sheet (Beginner → Expert)

> A practical reference covering AWS CLI, IAM, EC2, S3, VPC, RDS, Lambda, CloudFormation, monitoring, security, and cost management.

---

## Table of Contents

1. Introduction & Setup
2. AWS CLI Basics
3. Identity & Access Management (IAM)
4. EC2 (Compute)
5. S3 (Storage)
6. VPC & Networking
7. RDS & Databases
8. Lambda & Serverless
9. CloudFormation & IaC
10. Monitoring & Logging
11. Security & Encryption
12. Cost Management & Billing
13. Useful CLI Commands

---

# 1. Introduction & Setup

**What is AWS?**

* Amazon Web Services: largest public cloud provider.
* Offers compute, storage, databases, networking, analytics, AI, and DevOps tools.

**Setup CLI**

```bash
# Install AWS CLI
pip install awscli --upgrade --user

# Configure credentials
aws configure
# Enter Access Key, Secret, Region, Output (json/table/text)
```

**Check config**

```bash
aws sts get-caller-identity
aws configure list
```

---

# 2. AWS CLI Basics

**List resources**

```bash
aws ec2 describe-instances
aws s3 ls
```

**Profile management**

```bash
aws configure --profile myprofile
aws s3 ls --profile myprofile
```

**Output formats**

* `json`, `table`, `text`

```bash
aws ec2 describe-instances --output table
```

---

# 3. Identity & Access Management (IAM)

**Users & Groups**

```bash
aws iam create-user --user-name Bob
aws iam create-group --group-name DevOps
aws iam add-user-to-group --user-name Bob --group-name DevOps
```

**Roles & Policies**

```bash
aws iam create-role --role-name LambdaExecRole --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name LambdaExecRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

**Access keys**

```bash
aws iam create-access-key --user-name Bob
```

---

# 4. EC2 (Compute)

**Launch instance**

```bash
aws ec2 run-instances --image-id ami-123456 --count 1 --instance-type t2.micro --key-name myKey --security-group-ids sg-123456 --subnet-id subnet-123456
```

**Manage instance**

```bash
aws ec2 start-instances --instance-ids i-123456
aws ec2 stop-instances --instance-ids i-123456
aws ec2 terminate-instances --instance-ids i-123456
```

**List instances**

```bash
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags]' --output table
```

---

# 5. S3 (Storage)

**Create bucket**

```bash
aws s3 mb s3://mybucket
```

**Upload/download files**

```bash
aws s3 cp file.txt s3://mybucket/
aws s3 cp s3://mybucket/file.txt ./
```

**Sync directories**

```bash
aws s3 sync ./localdir s3://mybucket
```

**List objects**

```bash
aws s3 ls s3://mybucket
```

---

# 6. VPC & Networking

**Create VPC**

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16
```

**Subnets**

```bash
aws ec2 create-subnet --vpc-id vpc-123456 --cidr-block 10.0.1.0/24
```

**Security groups**

```bash
aws ec2 create-security-group --group-name mySG --description "Allow SSH" --vpc-id vpc-123456
aws ec2 authorize-security-group-ingress --group-id sg-123456 --protocol tcp --port 22 --cidr 0.0.0.0/0
```

**Elastic IPs**

```bash
aws ec2 allocate-address
```

---

# 7. RDS & Databases

**Create RDS instance**

```bash
aws rds create-db-instance --db-instance-identifier mydb --db-instance-class db.t2.micro --engine mysql --allocated-storage 20 --master-username admin --master-user-password P@ssw0rd123 --backup-retention-period 7
```

**List DBs**

```bash
aws rds describe-db-instances
```

**Delete DB**

```bash
aws rds delete-db-instance --db-instance-identifier mydb --skip-final-snapshot
```

---

# 8. Lambda & Serverless

**Create function**

```bash
aws lambda create-function --function-name myFunc --runtime python3.9 --role arn:aws:iam::123456:role/LambdaExecRole --handler lambda_function.lambda_handler --zip-file fileb://function.zip
```

**Invoke function**

```bash
aws lambda invoke --function-name myFunc output.txt
```

**List functions**

```bash
aws lambda list-functions
```

---

# 9. CloudFormation & IaC

**Deploy stack**

```bash
aws cloudformation create-stack --stack-name mystack --template-body file://template.json
```

**Update stack**

```bash
aws cloudformation update-stack --stack-name mystack --template-body file://template.json
```

**Delete stack**

```bash
aws cloudformation delete-stack --stack-name mystack
```

---

# 10. Monitoring & Logging

**CloudWatch logs**

```bash
aws logs create-log-group --log-group-name mylogs
aws logs create-log-stream --log-group-name mylogs --log-stream-name mystream
aws logs put-log-events --log-group-name mylogs --log-stream-name mystream --log-events file://events.json
```

**Metrics**

```bash
aws cloudwatch list-metrics
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --start-time 2023-09-01T00:00:00Z --end-time 2023-09-02T00:00:00Z --period 300 --statistics Average
```

---

# 11. Security & Encryption

**KMS (Key Management Service)**

```bash
aws kms create-key --description "My key"
aws kms encrypt --key-id alias/myKey --plaintext fileb://file.txt --output text --query CiphertextBlob
```

**Secrets Manager**

```bash
aws secretsmanager create-secret --name mySecret --secret-string '{"username":"admin","password":"P@ssw0rd"}'
aws secretsmanager get-secret-value --secret-id mySecret
```

---

# 12. Cost Management & Billing

**Get cost and usage**

```bash
aws ce get-cost-and-usage --time-period Start=2023-09-01,End=2023-09-30 --granularity MONTHLY --metrics "UnblendedCost"
```

**Budgets**

```bash
aws budgets create-budget --account-id <AWS_ACCOUNT_ID> --budget file://budget.json
```

---

# 13. Useful CLI Commands

**List services**

```bash
aws help
```

**EC2**

```bash
aws ec2 describe-instances
```

**S3**

```bash
aws s3 ls
```

**IAM**

```bash
aws iam list-users
```

**CloudFormation**

```bash
aws cloudformation list-stacks
```

---

# Quick Reference: One-liners

* List all EC2 instance IDs:

```bash
aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text
```

* Stop all instances in a region:

```bash
aws ec2 stop-instances --instance-ids $(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)
```

* Sync S3 bucket to local:

```bash
aws s3 sync s3://mybucket ./local
```

* List IAM users:

```bash
aws iam list-users --query 'Users[*].UserName' --output table
```

---

*End of cheat sheet — happy cloud building with AWS!*
