# 🚀 AWS Migration Guide - Austin Food Club

This guide will walk you through migrating your Austin Food Club application to AWS.

## 📋 Prerequisites

### 1. AWS Account Setup
- [ ] Create AWS account at [aws.amazon.com](https://aws.amazon.com)
- [ ] Set up billing alerts to monitor costs
- [ ] Enable MFA on your root account
- [ ] Create IAM user with appropriate permissions

### 2. AWS CLI Configuration
```bash
# Install AWS CLI (if not already installed)
brew install awscli

# Configure AWS CLI
aws configure
# Enter your Access Key ID, Secret Access Key, Region (us-east-1), and output format (json)
```

### 3. Domain Setup
- [ ] Ensure you own `austinfoodclub.com` domain
- [ ] Update domain nameservers to AWS Route 53 (after deployment)

## 🏗️ Infrastructure Overview

Our AWS architecture includes:

- **ECS Fargate**: Containerized Node.js backend
- **RDS PostgreSQL**: Managed database
- **S3 + CloudFront**: Flutter web app hosting with CDN
- **Route 53**: DNS management
- **ACM**: SSL certificates
- **Secrets Manager**: Secure configuration storage
- **CloudWatch**: Monitoring and logging

## 🚀 Deployment Steps

### Step 1: Configure AWS Credentials
```bash
# Verify AWS CLI is configured
aws sts get-caller-identity
```

### Step 2: Update Environment Variables
Update your `.env` file with production values:
```bash
# server/.env
DATABASE_URL="postgresql://username:password@rds-endpoint:5432/austinfoodclub"
YELP_API_KEY="your-real-yelp-api-key"
JWT_SECRET="your-production-jwt-secret"
SUPABASE_URL="your-supabase-url"
SUPABASE_ANON_KEY="your-supabase-anon-key"
```

### Step 3: Deploy Infrastructure
```bash
# Run the deployment script
./deploy.sh
```

This script will:
1. Deploy AWS infrastructure using CDK
2. Build and push Docker image to ECR
3. Build Flutter web app
4. Upload web app to S3
5. Configure CloudFront distribution

### Step 4: Database Migration
```bash
# Connect to RDS and run migrations
cd server
npx prisma migrate deploy
npx prisma db seed
```

### Step 5: Domain Configuration
1. Get the Route 53 hosted zone ID from deployment output
2. Update your domain registrar with AWS nameservers
3. Wait for DNS propagation (up to 48 hours)

## 🔧 Manual Configuration

### Update ECS Task Definition
After deployment, you'll need to update the ECS task definition to use your Docker image:

1. Go to ECS Console → Clusters → austin-food-club
2. Select the service → Update service
3. Change the task definition to use your ECR image
4. Update environment variables as needed

### Configure Secrets Manager
Add your production secrets:
```bash
aws secretsmanager update-secret \
  --secret-id "AustinFoodClubStack-AppSecrets" \
  --secret-string '{
    "JWT_SECRET": "your-production-jwt-secret",
    "YELP_API_KEY": "your-real-yelp-api-key",
    "SUPABASE_URL": "your-supabase-url",
    "SUPABASE_ANON_KEY": "your-supabase-anon-key"
  }'
```

## 📊 Monitoring Setup

### CloudWatch Dashboards
- Monitor ECS service health
- Track RDS performance metrics
- Monitor CloudFront distribution metrics
- Set up alarms for critical metrics

### Log Aggregation
- ECS logs are automatically sent to CloudWatch
- Set up log retention policies
- Configure log-based alerts

## 💰 Cost Optimization

### Estimated Monthly Costs (us-east-1)
- **ECS Fargate**: ~$15-25 (1 vCPU, 512MB RAM)
- **RDS PostgreSQL**: ~$15-20 (db.t3.micro)
- **S3**: ~$1-5 (storage + requests)
- **CloudFront**: ~$1-10 (data transfer)
- **Route 53**: ~$0.50 (hosted zone)
- **Total**: ~$35-60/month

### Cost Optimization Tips
1. Use Spot instances for non-critical workloads
2. Enable RDS automated backups
3. Set up S3 lifecycle policies
4. Monitor CloudWatch costs
5. Use AWS Cost Explorer for detailed analysis

## 🔒 Security Best Practices

### Network Security
- VPC with private subnets for database
- Security groups with minimal required access
- NAT Gateway for outbound internet access

### Data Security
- RDS encryption at rest
- Secrets Manager for sensitive data
- IAM roles with least privilege
- SSL/TLS for all communications

### Application Security
- Regular security updates
- Container image scanning
- Secrets rotation
- Access logging

## 🚨 Troubleshooting

### Common Issues

#### 1. ECS Service Won't Start
- Check task definition logs
- Verify environment variables
- Ensure Docker image exists in ECR
- Check security group rules

#### 2. Database Connection Issues
- Verify RDS security group allows ECS access
- Check database credentials in Secrets Manager
- Ensure VPC configuration is correct

#### 3. CloudFront Not Updating
- Clear browser cache
- Invalidate CloudFront distribution
- Check S3 bucket permissions

#### 4. Domain Not Resolving
- Verify nameserver configuration
- Check Route 53 hosted zone
- Wait for DNS propagation

### Useful Commands
```bash
# Check ECS service status
aws ecs describe-services --cluster austin-food-club --services BackendService

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/ecs/austin-food-club

# Check RDS status
aws rds describe-db-instances --db-instance-identifier AustinFoodClubDatabase

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## 📈 Scaling Considerations

### Horizontal Scaling
- Increase ECS service desired count
- Use Application Load Balancer for traffic distribution
- Implement auto-scaling policies

### Vertical Scaling
- Increase ECS task CPU/memory
- Upgrade RDS instance class
- Optimize application performance

### Database Scaling
- Enable RDS read replicas
- Implement connection pooling
- Consider Aurora for better performance

## 🔄 CI/CD Pipeline (Future)

Consider setting up GitHub Actions or AWS CodePipeline for:
- Automated testing
- Docker image building
- Infrastructure updates
- Application deployments

## 📞 Support

For issues with this migration:
1. Check AWS documentation
2. Review CloudWatch logs
3. Use AWS Support (if you have a support plan)
4. Check the troubleshooting section above

## 🎯 Next Steps

After successful migration:
1. Set up monitoring and alerting
2. Implement backup strategies
3. Configure disaster recovery
4. Set up staging environment
5. Implement CI/CD pipeline
6. Optimize performance and costs

---

**Happy Deploying! 🚀**

