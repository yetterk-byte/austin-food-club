# 🚀 Austin Food Club - Deployment Guide

## 📋 Overview

Your Austin Food Club application is now deployed to AWS with the following architecture:

- **Frontend**: Flutter web app served via S3 + CloudFront
- **Backend**: Node.js API running on ECS Fargate
- **Database**: PostgreSQL on RDS
- **Domain**: https://austinfoodclub.com
- **Monitoring**: CloudWatch dashboards and alerts

## 🔄 Update Methods

### Method 1: Manual Updates (Quick & Simple)

Use the provided update script:

```bash
./update-app.sh
```

This script will:
- Ask what you want to update (frontend, backend, or both)
- Handle the build and deployment process
- Provide status updates

### Method 2: Individual Component Updates

#### Frontend Updates
```bash
# 1. Make your changes to Flutter code
cd mobile

# 2. Build the app
flutter build web --release

# 3. Upload to S3
aws s3 sync build/web/ s3://austinfoodclub-frontend --region us-east-1

# 4. Invalidate CloudFront cache (for immediate updates)
aws cloudfront create-invalidation --distribution-id ES2T3ZG4KAC0C --paths '/*' --region us-east-1
```

#### Backend Updates
```bash
# 1. Make your changes to server code
cd server

# 2. Trigger CodeBuild (rebuilds Docker image)
aws codebuild start-build --project-name austin-food-club-backend-build --region us-east-1

# 3. Update ECS service
aws ecs update-service --cluster austin-food-club-cluster --service austin-food-club-backend --force-new-deployment --region us-east-1
```

### Method 3: Automated CI/CD (Recommended for Production)

Set up GitHub Actions for automatic deployments:

1. **Add AWS credentials to GitHub Secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. **Push changes to main branch**:
   ```bash
   git add .
   git commit -m "Your update message"
   git push origin main
   ```

3. **GitHub Actions will automatically**:
   - Build and deploy the backend
   - Build and deploy the frontend
   - Update both services

## 📊 Monitoring Your Deployments

### CloudWatch Dashboard
- **URL**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Austin-Food-Club-Production
- **Monitors**: CPU, Memory, Request counts, Error rates

### ECS Console
- **URL**: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/austin-food-club-cluster
- **Monitors**: Service health, task status, logs

### CloudFront Console
- **URL**: https://console.aws.amazon.com/cloudfront/home?region=us-east-1
- **Monitors**: Cache performance, distribution status

## 🔧 Common Update Scenarios

### Scenario 1: UI Changes
```bash
# Make changes to Flutter code
# Then run:
./update-app.sh
# Select option 1 (Frontend only)
```

### Scenario 2: API Changes
```bash
# Make changes to server code
# Then run:
./update-app.sh
# Select option 2 (Backend only)
```

### Scenario 3: Full Stack Update
```bash
# Make changes to both frontend and backend
# Then run:
./update-app.sh
# Select option 3 (Both)
```

## 🚨 Troubleshooting

### Frontend Not Updating
1. Check CloudFront invalidation status
2. Wait 5-15 minutes for global propagation
3. Clear browser cache

### Backend Not Updating
1. Check ECS service status
2. View ECS service logs
3. Verify CodeBuild completed successfully

### Database Issues
1. Check RDS instance status
2. Verify connection strings
3. Check security groups

## 📱 Current URLs

- **Production Frontend**: https://austinfoodclub.com
- **Production Backend**: http://ECSAus-Backe-9BcJbVFKkgWJ-1172628832.us-east-1.elb.amazonaws.com
- **S3 Website**: http://austinfoodclub-frontend.s3-website-us-east-1.amazonaws.com

## 🔐 Security Notes

- All traffic is encrypted (HTTPS)
- Database is in private subnet
- ECS tasks have minimal IAM permissions
- CloudFront provides DDoS protection

## 📈 Performance Tips

1. **Frontend**: CloudFront caches static assets globally
2. **Backend**: ECS auto-scales based on demand
3. **Database**: RDS handles connection pooling
4. **Monitoring**: Set up alerts for performance issues

## 🆘 Support

If you encounter issues:

1. Check CloudWatch logs first
2. Verify all AWS services are running
3. Test individual components
4. Review the monitoring dashboard

---

**Happy Deploying! 🎉**

Your Austin Food Club app is now running in the cloud with professional-grade infrastructure!

