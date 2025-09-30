#!/bin/bash

echo "🧪 Testing AWS Setup..."

# Test AWS CLI configuration
echo "1. Testing AWS CLI configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo "✅ AWS CLI configured successfully"
    aws sts get-caller-identity
else
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Test permissions
echo ""
echo "2. Testing AWS permissions..."
echo "   - Testing S3 access..."
if aws s3 ls > /dev/null 2>&1; then
    echo "   ✅ S3 access confirmed"
else
    echo "   ❌ S3 access denied"
fi

echo "   - Testing ECS access..."
if aws ecs list-clusters > /dev/null 2>&1; then
    echo "   ✅ ECS access confirmed"
else
    echo "   ❌ ECS access denied"
fi

echo "   - Testing RDS access..."
if aws rds describe-db-instances > /dev/null 2>&1; then
    echo "   ✅ RDS access confirmed"
else
    echo "   ❌ RDS access denied"
fi

echo "   - Testing CloudFormation access..."
if aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE > /dev/null 2>&1; then
    echo "   ✅ CloudFormation access confirmed"
else
    echo "   ❌ CloudFormation access denied"
fi

# Get account info
echo ""
echo "3. Account Information:"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
echo "   Account ID: $ACCOUNT_ID"
echo "   Region: $REGION"

echo ""
echo "🎉 AWS setup test completed!"
echo "If you see any ❌ errors above, you may need additional permissions."

