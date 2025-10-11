#!/bin/bash

# Austin Food Club - App Update Script
# This script helps you update your deployed application

set -e

echo "🚀 Austin Food Club - App Update Script"
echo "========================================"

# Function to update frontend
update_frontend() {
    echo "📱 Updating Frontend (Flutter Web App)..."
    
    # Build the Flutter app
    echo "Building Flutter web app..."
    cd /Users/kennyyetter/Desktop/austin-food-club/mobile
    flutter build web --release
    
    # Upload to S3
    echo "Uploading to S3..."
    aws s3 sync build/web/ s3://austinfoodclub-frontend --region us-east-1

    # Force fresh loads for critical files (avoid stale SW)
    echo "Setting no-cache headers for critical files..."
    aws s3 cp build/web/index.html s3://austinfoodclub-frontend/index.html \
      --region us-east-1 \
      --cache-control "no-cache, no-store, must-revalidate" \
      --content-type "text/html" \
      --metadata-directive REPLACE

    if [ -f build/web/flutter_service_worker.js ]; then
      aws s3 cp build/web/flutter_service_worker.js s3://austinfoodclub-frontend/flutter_service_worker.js \
        --region us-east-1 \
        --cache-control "no-cache, no-store, must-revalidate" \
        --content-type "application/javascript" \
        --metadata-directive REPLACE
    fi

    if [ -f build/web/version.json ]; then
      aws s3 cp build/web/version.json s3://austinfoodclub-frontend/version.json \
        --region us-east-1 \
        --cache-control "no-cache, no-store, must-revalidate" \
        --content-type "application/json" \
        --metadata-directive REPLACE
    fi
    
    # Invalidate CloudFront cache
    echo "Invalidating CloudFront cache..."
    aws cloudfront create-invalidation --distribution-id ES2T3ZG4KAC0C --paths '/*' --region us-east-1
    
    echo "✅ Frontend updated successfully!"
    echo "🌐 Your changes will be live at https://austinfoodclub.com in a few minutes"
}

# Function to update backend
update_backend() {
    echo "🔧 Updating Backend (Node.js API)..."
    
    # Trigger CodeBuild
    echo "Triggering CodeBuild..."
    aws codebuild start-build --project-name austin-food-club-backend-build --region us-east-1
    
    echo "⏳ Waiting for build to complete..."
    sleep 30
    
    # Update ECS service
    echo "Updating ECS service..."
    aws ecs update-service --cluster austin-food-club-cluster --service austin-food-club-backend --force-new-deployment --region us-east-1
    
    echo "✅ Backend updated successfully!"
    echo "🔗 API will be available at http://ECSAus-Backe-9BcJbVFKkgWJ-1172628832.us-east-1.elb.amazonaws.com"
}

# Function to update both
update_all() {
    echo "🔄 Updating Both Frontend and Backend..."
    update_frontend
    echo ""
    update_backend
}

# Main menu
echo "What would you like to update?"
echo "1) Frontend only (Flutter web app)"
echo "2) Backend only (Node.js API)"
echo "3) Both frontend and backend"
echo "4) Exit"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        update_frontend
        ;;
    2)
        update_backend
        ;;
    3)
        update_all
        ;;
    4)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "🎉 Update process completed!"
echo ""
echo "📊 Current URLs:"
echo "  Frontend: https://austinfoodclub.com"
echo "  Backend:  http://ECSAus-Backe-9BcJbVFKkgWJ-1172628832.us-east-1.elb.amazonaws.com"
echo ""
echo "📈 Monitor your deployment:"
echo "  CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Austin-Food-Club-Production"
echo "  ECS:        https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/austin-food-club-cluster"

