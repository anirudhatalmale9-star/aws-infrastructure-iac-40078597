# AWS Infrastructure as Code - Multi-Module Application

This repository contains CloudFormation templates for deploying a complete AWS infrastructure for a multi-module application with staging and production environments.

## Architecture Overview

```
                                    ┌─────────────────────────────────────────┐
                                    │           AWS Cloud                      │
                                    │                                          │
    Internet ──────────────────────►│  ┌─────────────────────────────────┐   │
                                    │  │     Application Load Balancer    │   │
                                    │  │         (Public Subnets)         │   │
                                    │  └──────────────┬──────────────────┘   │
                                    │                 │                       │
                                    │  ┌──────────────▼──────────────────┐   │
                                    │  │         ECS Cluster              │   │
                                    │  │      (Private Subnets)           │   │
                                    │  │  ┌─────────────────────────────┐ │   │
                                    │  │  │ Module1 │ Module2 │ Module3 │ │   │
                                    │  │  │ Module4 │         │         │ │   │
                                    │  │  └─────────────────────────────┘ │   │
                                    │  └──────────────┬──────────────────┘   │
                                    │                 │                       │
                                    │  ┌──────────────▼──────────────────┐   │
                                    │  │    Database & Cache Layer        │   │
                                    │  │      (Database Subnets)          │   │
                                    │  │  ┌───────────┐  ┌─────────────┐ │   │
                                    │  │  │    RDS    │  │ ElastiCache │ │   │
                                    │  │  │ PostgreSQL│  │    Redis    │ │   │
                                    │  │  └───────────┘  └─────────────┘ │   │
                                    │  └─────────────────────────────────┘   │
                                    │                                          │
                                    └─────────────────────────────────────────┘
```

## Directory Structure

```
.
├── cloudformation/
│   ├── networking/
│   │   ├── vpc.yaml              # VPC, subnets, route tables, NAT gateways
│   │   └── security-groups.yaml  # Security groups for all components
│   ├── database/
│   │   └── rds.yaml              # RDS PostgreSQL database
│   ├── cache/
│   │   └── elasticache.yaml      # ElastiCache Redis cluster
│   ├── compute/
│   │   ├── ecs-cluster.yaml      # ECS cluster, ECR repos, IAM roles
│   │   └── ecs-service.yaml      # ECS service template (reusable)
│   ├── loadbalancer/
│   │   └── alb.yaml              # Application Load Balancer, target groups
│   ├── cicd/
│   │   ├── codepipeline.yaml     # CI/CD pipeline template (reusable)
│   │   └── buildspec.yaml        # CodeBuild build specification
│   └── monitoring/
│       └── cloudwatch-alarms.yaml # CloudWatch alarms and dashboard
├── environments/
│   ├── staging/
│   │   ├── main.yaml             # Master stack for staging
│   │   └── parameters.json       # Parameter values (with placeholders)
│   └── production/
│       ├── main.yaml             # Master stack for production
│       └── parameters.json       # Parameter values (with placeholders)
└── docs/
    ├── README.md                 # This file
    ├── DEPLOYMENT.md             # Deployment instructions
    └── PLACEHOLDERS.md           # List of all placeholders to replace
```

## Components

### Networking
- **VPC**: Isolated network with CIDR 10.0.0.0/16 (staging) or 10.1.0.0/16 (production)
- **Subnets**: Public (ALB), Private (ECS), Database (RDS/ElastiCache)
- **NAT Gateways**: Dual NAT for high availability
- **Security Groups**: Strict rules for ALB, ECS, RDS, and Redis

### Database
- **RDS PostgreSQL 15**: Single-AZ (staging) or Multi-AZ (production)
- **Encryption**: At-rest encryption enabled
- **Backups**: Automated daily backups

### Cache
- **ElastiCache Redis 7**: Single node (staging) or cluster (production)
- **Encryption**: In-transit and at-rest encryption enabled

### Compute
- **ECS Fargate**: Serverless container orchestration
- **4 ECR Repositories**: One per module
- **Auto Scaling**: CPU and memory-based scaling policies
- **Task Roles**: Least-privilege IAM roles

### Load Balancer
- **Application Load Balancer**: Internet-facing
- **Path-based routing**: Routes to different modules based on URL path
- **HTTPS**: TLS 1.3 support (when certificate provided)

### CI/CD
- **CodePipeline**: Source -> Build -> Deploy
- **CodeBuild**: Docker image building
- **GitHub Integration**: Via CodeStar Connections

### Monitoring & Alarms
- **CloudWatch Dashboard**: Consolidated view of all infrastructure metrics
- **SNS Topic**: Alarm notifications (email subscription optional)
- **ECS Alarms**: CPU and memory utilization alerts
- **ALB Alarms**: Response time, 5XX errors, unhealthy hosts
- **RDS Alarms**: CPU, storage, connections, read latency
- **Redis Alarms**: CPU, memory usage, evictions

## Environment Differences

| Feature | Staging | Production |
|---------|---------|------------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| RDS Instance | db.t3.micro | db.t3.small |
| RDS Multi-AZ | No | Yes |
| RDS Storage | 20 GB | 50 GB |
| ElastiCache Node | cache.t3.micro | cache.t3.small |
| ElastiCache HA | No | Yes |
| ECS Task CPU | 256 | 512 |
| ECS Task Memory | 512 MB | 1024 MB |
| ECS Desired Count | 1 | 2 |
| Auto Scale Max | 4 | 10 |
| GitHub Branch | develop | main |
| Deletion Protection | No | Yes |

## Quick Start

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

### Prerequisites
1. AWS CLI configured with appropriate credentials
2. S3 bucket for CloudFormation templates
3. GitHub CodeStar Connection created in AWS Console
4. (Production) ACM certificate for HTTPS

### Basic Steps
1. Replace placeholders in parameter files
2. Upload templates to S3
3. Deploy master stack
4. Push initial Docker images

## Support

For issues or questions, please contact the project maintainer.
