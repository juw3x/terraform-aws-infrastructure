# Terraform AWS Infrastructure

A comprehensive Infrastructure as Code (IaC) project using Terraform to deploy a production-ready AWS infrastructure with VPC, EC2 Auto Scaling, RDS PostgreSQL, Application Load Balancer, and S3 storage.

![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue)
![AWS](https://img.shields.io/badge/AWS-Provider-5.0+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Modules](#modules)
- [Configuration](#configuration)
- [Outputs](#outputs)
- [Cost Estimation](#cost-estimation)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This Terraform project automates the deployment of a complete AWS infrastructure suitable for web applications. It follows DevOps best practices including:

- **Modular Architecture**: Reusable Terraform modules for each component
- **Multi-Environment Support**: Separate configurations for dev and prod
- **Remote State Management**: S3 backend with DynamoDB locking
- **Auto Scaling**: Dynamic scaling based on CPU utilization
- **High Availability**: Multi-AZ deployment for production
- **Monitoring**: CloudWatch alarms for critical metrics
- **Security**: Security groups, encryption, and network isolation

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS (443) / HTTP (80)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Application Load Balancer                   │
│                     (Public Subnets)                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTP (80)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              EC2 Auto Scaling Group                          │
│                  (Private Subnets)                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │  EC2 #1  │  │  EC2 #2  │  │  EC2 #3  │                   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                   │
└───────┼──────────────┼──────────────┼──────────────────────┘
        │              │              │
        │              │              │
        │ PostgreSQL (5432)          │
        │              │              │
        ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│                  RDS PostgreSQL                              │
│                 (Database Subnets)                          │
│              (Multi-AZ for Production)                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     S3 Bucket                                │
│              (Static Files Storage)                          │
└─────────────────────────────────────────────────────────────┘
```

### Network Architecture

- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (ALB, NAT Gateway)
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24 (EC2 instances)
- **Database Subnets**: 10.0.20.0/24, 10.0.21.0/24 (RDS)
- **Internet Gateway**: Public internet access
- **NAT Gateways**: Outbound internet access for private subnets

## ✨ Features

### Infrastructure Components

- **VPC Module**: Complete network setup with public, private, and database subnets
- **EC2 Module**: Auto Scaling Group with launch templates and scaling policies
- **RDS Module**: PostgreSQL database with enhanced monitoring
- **ALB Module**: Application Load Balancer with HTTPS support
- **S3 Module**: Encrypted storage with lifecycle policies

### Auto Scaling & Monitoring

- **Dynamic Scaling**: Automatic scale up/down based on CPU utilization
- **CloudWatch Alarms**: Monitoring for EC2, RDS, ALB, and S3
- **Health Checks**: Instance and application health monitoring
- **Enhanced Monitoring**: RDS performance insights

### Security

- **Security Groups**: Network-level access control
- **Encryption**: S3 and RDS encryption at rest
- **Network Isolation**: Private subnets for application and database
- **IAM Roles**: Least privilege access for RDS monitoring

## 📦 Prerequisites

### Required Tools

- **Terraform**: >= 1.5.0
  ```bash
  terraform --version
  ```

- **AWS CLI**: Latest version
  ```bash
  aws --version
  ```

- **Git**: For version control
  ```bash
  git --version
  ```

### AWS Requirements

- **AWS Account** with appropriate permissions
- **AWS Credentials** configured locally
  ```bash
  aws configure
  ```

- **S3 Bucket** for Terraform state (create manually first)
  ```bash
  aws s3 mb s3://terraform-state-bucket-devops
  aws s3api put-bucket-versioning --bucket terraform-state-bucket-devops --versioning-configuration Status=Enabled
  ```

- **DynamoDB Table** for state locking
  ```bash
  aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
  ```

- **SSH Key Pair** for EC2 access
  ```bash
  aws ec2 create-key-pair --key-name devops-key --query 'KeyMaterial' --output text > devops-key.pem
  chmod 400 devops-key.pem
  ```

## 📁 Project Structure

```
terraform-aws-infrastructure/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars        # Default variables (optional)
├── modules/
│   ├── vpc/                # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/                # EC2 Auto Scaling module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user-data.sh
│   ├── rds/                # RDS PostgreSQL module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/                # Application Load Balancer module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── s3/                 # S3 storage module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev.tfvars          # Development environment variables
│   └── prod.tfvars         # Production environment variables
├── scripts/                # Helper scripts
└── README.md               # This file
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/qqqqqwwerty/terraform-aws-infrastructure.git
cd terraform-aws-infrastructure
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID and Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### 3. Update Backend Configuration

Edit `main.tf` to update the S3 backend configuration with your bucket details:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "devops-infrastructure/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Select Environment

For development:
```bash
terraform plan -var-file=environments/dev.tfvars
```

For production:
```bash
terraform plan -var-file=environments/prod.tfvars
```

### 6. Review the Plan

Review the Terraform plan to ensure it matches your expectations.

### 7. Apply Changes

```bash
terraform apply -var-file=environments/dev.tfvars
```

Type `yes` when prompted to confirm.

### 8. Verify Deployment

```bash
terraform output
```

This will display important outputs like ALB DNS name, RDS endpoint, etc.

### 9. Access Your Application

The application will be accessible via the ALB DNS name:
```bash
terraform output alb_dns_name
```

Open the URL in your browser.

## 📦 Modules

### VPC Module

Creates a complete VPC with public, private, and database subnets.

**Resources:**
- VPC
- Internet Gateway
- Public Subnets
- Private Subnets
- Database Subnets
- NAT Gateways
- Route Tables
- Security Groups

**Usage:**
```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name          = "devops-infrastructure"
  environment           = "dev"
  vpc_cidr              = "10.0.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]
}
```

### EC2 Module

Creates an Auto Scaling Group with launch templates and scaling policies.

**Resources:**
- Launch Template
- Auto Scaling Group
- Scaling Policies
- CloudWatch Alarms

**Usage:**
```hcl
module "ec2" {
  source = "./modules/ec2"

  instance_type    = "t3.micro"
  ami_id           = "ami-0c55b159cbfafe1f0"
  key_name         = "devops-key"
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
}
```

### RDS Module

Creates a PostgreSQL database with enhanced monitoring.

**Resources:**
- RDS Instance
- DB Subnet Group
- IAM Role for Monitoring
- CloudWatch Alarms

**Usage:**
```hcl
module "rds" {
  source = "./modules/rds"

  db_instance_class = "db.t3.micro"
  db_engine         = "postgres"
  db_engine_version = "14.10"
  db_name           = "devopsdb"
  db_username       = "admin"
  db_password       = "ChangeMe123!"
  allocated_storage = 20
  multi_az          = false
}
```

### ALB Module

Creates an Application Load Balancer with target groups and listeners.

**Resources:**
- Application Load Balancer
- Target Group
- Listeners (HTTP/HTTPS)
- Security Group
- CloudWatch Alarms

**Usage:**
```hcl
module "alb" {
  source = "./modules/alb"

  certificate_arn   = ""  # Leave empty for HTTP only
  alb_internal      = false
  health_check_path = "/health"
}
```

### S3 Module

Creates an encrypted S3 bucket with lifecycle policies.

**Resources:**
- S3 Bucket
- Versioning
- Server-Side Encryption
- Public Access Block
- Lifecycle Configuration
- CloudWatch Alarms

**Usage:**
```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name   = "devops-static-files"
  versioning    = true
}
```

## ⚙️ Configuration

### Environment Variables

Each environment has its own configuration file in the `environments/` directory:

- `dev.tfvars` - Development environment
- `prod.tfvars` - Production environment

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Project name | `devops-infrastructure` |
| `environment` | Environment name | `dev` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `db_instance_class` | RDS instance class | `db.t3.micro` |
| `multi_az` | Enable Multi-AZ for RDS | `false` |

### Custom Configuration

To customize the infrastructure for your needs:

1. Copy the appropriate environment file:
   ```bash
   cp environments/dev.tfvars environments/custom.tfvars
   ```

2. Edit the variables in your custom file:
   ```bash
   nano environments/custom.tfvars
   ```

3. Apply with your custom configuration:
   ```bash
   terraform apply -var-file=environments/custom.tfvars
   ```

## 📊 Outputs

After successful deployment, Terraform will output the following:

- `vpc_id` - VPC ID
- `alb_dns_name` - Load Balancer DNS name (application URL)
- `rds_endpoint` - Database endpoint
- `s3_bucket_name` - S3 bucket name
- `asg_name` - Auto Scaling Group name

View outputs:
```bash
terraform output
```

Or view a specific output:
```bash
terraform output alb_dns_name
```

## 💰 Cost Estimation

### Development Environment (us-east-1)

- **VPC**: Free
- **EC2 (t3.micro)**: ~$8.50/month × 1 instance = $8.50
- **RDS (db.t3.micro)**: ~$15/month
- **ALB**: ~$0.0225/hour × 730 hours = $16.43/month
- **NAT Gateway**: ~$0.045/hour × 730 hours = $32.85/month
- **S3**: Minimal (usage-based)
- **Data Transfer**: Minimal

**Total (estimated)**: ~$73/month

### Production Environment (us-east-1)

- **VPC**: Free
- **EC2 (t3.medium)**: ~$34/month × 3 instances = $102
- **RDS (db.t3.medium, Multi-AZ)**: ~$52/month
- **ALB**: ~$0.0225/hour × 730 hours = $16.43/month
- **NAT Gateway**: ~$0.045/hour × 730 hours × 2 = $65.70/month
- **S3**: Minimal (usage-based)
- **Data Transfer**: Variable

**Total (estimated)**: ~$236/month

> **Note**: These are estimates. Actual costs may vary based on usage. Use the [AWS Pricing Calculator](https://calculator.aws/) for accurate estimates.

## 🔒 Security Best Practices

This project implements several security best practices:

1. **Network Isolation**
   - Database in private subnets
   - Application in private subnets
   - Only ALB in public subnets

2. **Encryption**
   - S3 bucket encryption enabled
   - RDS encryption at rest
   - TLS for ALB (when certificate provided)

3. **Access Control**
   - Security groups with minimal required ports
   - IAM roles with least privilege
   - Public access blocked on S3

4. **State Management**
   - Remote state in S3 with encryption
   - DynamoDB for state locking
   - No secrets in state files

5. **Monitoring**
   - CloudWatch alarms for security events
   - Enhanced monitoring for RDS
   - Audit logging

## 🛠️ Troubleshooting

### Terraform Init Fails

**Problem**: `Error: Error configuring Terraform AWS Backend`

**Solution**:
- Ensure S3 bucket exists
- Check AWS credentials
- Verify bucket region matches configuration

### Module Not Found

**Problem**: `Error: Module not found`

**Solution**:
- Run `terraform init` to download modules
- Check module paths in configuration

### Resource Creation Timeout

**Problem**: AWS resource creation times out

**Solution**:
- Check AWS service health status
- Verify IAM permissions
- Try again after a few minutes

### SSH Access to EC2

**Problem**: Cannot SSH into EC2 instances

**Solution**:
- Verify key pair exists
- Check security group allows SSH (port 22)
- Ensure you're using the correct key file

### RDS Connection Issues

**Problem**: Cannot connect to RDS from EC2

**Solution**:
- Verify security group allows PostgreSQL (port 5432)
- Check RDS is in the same VPC
- Ensure database is in "available" state

## 📝 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

**qqqqqwwerty** - Junior DevOps Engineer

---

**Note**: This is a demonstration project for educational purposes. Always review and customize the infrastructure for your specific requirements before deploying to production.
