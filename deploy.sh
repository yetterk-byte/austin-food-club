#!/bin/bash

# Austin Food Club AWS Deployment Script
set -e

echo "🚀 Starting Austin Food Club AWS Deployment..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Get AWS account info
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")

echo "📋 AWS Account: $AWS_ACCOUNT"
echo "🌍 AWS Region: $AWS_REGION"

# Set environment variables
export CDK_DEFAULT_ACCOUNT=$AWS_ACCOUNT
export CDK_DEFAULT_REGION=$AWS_REGION

# Known resources
WEB_APP_BUCKET="austinfoodclub-frontend"

# Navigate to infrastructure directory
cd aws-infrastructure

# Install dependencies
echo "📦 Installing CDK dependencies..."
npm install

# Bootstrap CDK (if needed)
echo "🔧 Bootstrapping CDK..."
npx cdk bootstrap

# Deploy infrastructure (all stacks)
echo "🏗️ Deploying infrastructure..."
npx cdk deploy --all --require-approval never || npx cdk deploy DomainAustinFoodClubStack ECSAustinFoodClubStack MonitoringAustinFoodClubStack --require-approval never

echo "✅ Infrastructure deploy command executed"

# Build and push Docker image
echo "🐳 Building and pushing Docker image..."
cd ../server

# Create ECR repository (if it doesn't exist)
aws ecr describe-repositories --repository-name austin-food-club-backend --region $AWS_REGION > /dev/null 2>&1 || \
aws ecr create-repository --repository-name austin-food-club-backend --region $AWS_REGION

# Get ECR login token
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and tag image
docker build -t austin-food-club-backend .
docker tag austin-food-club-backend:latest $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/austin-food-club-backend:latest

# Push image
docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/austin-food-club-backend:latest

echo "✅ Docker image pushed successfully!"

# Force new ECS deployment to pick up latest image
echo "🔁 Forcing ECS service deployment..."
aws ecs update-service --cluster austin-food-club-cluster --service austin-food-club-backend --force-new-deployment --region $AWS_REGION || true
echo "✅ ECS service update requested"

# Build Flutter web app
echo "📱 Building Flutter web app..."
cd ../mobile

# Build for web
flutter build web --release

# Sync to S3
echo "📤 Uploading Flutter web app to S3..."
aws s3 sync build/web/ s3://$WEB_APP_BUCKET --delete

# Invalidate CloudFront cache
echo "🔄 Invalidating CloudFront cache..."
# Discover distributions by alias and invalidate
CF_IDS=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && contains(join(',',Aliases.Items),'austinfoodclub.com')].Id" --output text)
for ID in $CF_IDS; do
  echo "Invalidating CloudFront distribution: $ID"
  aws cloudfront create-invalidation --distribution-id $ID --paths "/*" || true
done

echo "🎉 Deployment completed successfully!"
echo "🌐 Frontend updated on CloudFront aliases for austinfoodclub.com"
echo "🔗 Backend ECS service redeploy requested (cluster: austin-food-club-cluster, service: austin-food-club-backend)"

