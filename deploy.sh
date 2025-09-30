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

# Navigate to infrastructure directory
cd aws-infrastructure

# Install dependencies
echo "📦 Installing CDK dependencies..."
npm install

# Bootstrap CDK (if needed)
echo "🔧 Bootstrapping CDK..."
npx cdk bootstrap

# Deploy infrastructure
echo "🏗️ Deploying infrastructure..."
npx cdk deploy --require-approval never

# Get outputs
echo "📊 Getting deployment outputs..."
LOAD_BALANCER_DNS=$(aws cloudformation describe-stacks --stack-name AustinFoodClubStack --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' --output text)
WEB_APP_BUCKET=$(aws cloudformation describe-stacks --stack-name AustinFoodClubStack --query 'Stacks[0].Outputs[?OutputKey==`WebAppBucketName`].OutputValue' --output text)
CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks --stack-name AustinFoodClubStack --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomainName`].OutputValue' --output text)

echo "✅ Infrastructure deployed successfully!"
echo "🌐 Load Balancer DNS: $LOAD_BALANCER_DNS"
echo "🪣 Web App Bucket: $WEB_APP_BUCKET"
echo "☁️ CloudFront Domain: $CLOUDFRONT_DOMAIN"

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
CLOUDFRONT_ID=$(aws cloudformation describe-stacks --stack-name AustinFoodClubStack --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' --output text)
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"

echo "🎉 Deployment completed successfully!"
echo "🌐 Your app will be available at: https://$CLOUDFRONT_DOMAIN"
echo "🔗 Backend API: http://$LOAD_BALANCER_DNS"

