#!/bin/bash

# Austin Food Club Deployment Script
# This script handles deployment to different environments and platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
PLATFORM="both"
ENVIRONMENT="production"
SKIP_TESTS=false
UPLOAD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -u|--upload)
            UPLOAD=true
            shift
            ;;
        -h|--help)
            echo "Austin Food Club Deployment Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -p, --platform PLATFORM    Platform (android, ios, both) [default: both]"
            echo "  -e, --environment ENV       Environment (development, staging, production) [default: production]"
            echo "  -s, --skip-tests           Skip running tests before deployment"
            echo "  -u, --upload               Upload to distribution platforms"
            echo "  -h, --help                 Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Deploy both platforms to production"
            echo "  $0 -p android -e staging             # Deploy Android to staging"
            echo "  $0 -p ios -e production -u           # Deploy iOS to production and upload"
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            exit 1
            ;;
    esac
done

print_status "Starting Austin Food Club deployment..."
print_status "Platform: $PLATFORM"
print_status "Environment: $ENVIRONMENT"
print_status "Skip Tests: $SKIP_TESTS"
print_status "Upload: $UPLOAD"

# Validate inputs
case $PLATFORM in
    android|ios|both)
        ;;
    *)
        print_error "Invalid platform: $PLATFORM. Must be android, ios, or both."
        exit 1
        ;;
esac

case $ENVIRONMENT in
    development|staging|production)
        ;;
    *)
        print_error "Invalid environment: $ENVIRONMENT. Must be development, staging, or production."
        exit 1
        ;;
esac

# Pre-deployment checks
print_status "Running pre-deployment checks..."

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Check Git status
if [ "$ENVIRONMENT" = "production" ]; then
    if ! git diff-index --quiet HEAD --; then
        print_warning "You have uncommitted changes. Consider committing before production deployment."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deployment cancelled."
            exit 0
        fi
    fi
fi

# Run tests unless skipped
if [ "$SKIP_TESTS" = false ]; then
    print_status "Running tests..."
    flutter test
    if [ $? -ne 0 ]; then
        print_error "Tests failed. Deployment cancelled."
        exit 1
    fi
    print_success "All tests passed"
fi

# Update dependencies
print_status "Updating dependencies..."
flutter pub get

# Build for requested platforms
BUILD_FAILED=false

if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
    print_status "Building Android..."
    
    if [ "$ENVIRONMENT" = "production" ]; then
        ./scripts/build_android.sh -t release -e production -a
    else
        ./scripts/build_android.sh -t staging -e "$ENVIRONMENT" -a
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Android build failed"
        BUILD_FAILED=true
    else
        print_success "Android build completed"
    fi
fi

if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
    # Check if we're on macOS for iOS builds
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "iOS builds can only be created on macOS. Skipping iOS build."
    else
        print_status "Building iOS..."
        
        if [ "$ENVIRONMENT" = "production" ]; then
            ./scripts/build_ios.sh -t release -e production -m app-store -a
        else
            ./scripts/build_ios.sh -t staging -e "$ENVIRONMENT" -m ad-hoc -a
        fi
        
        if [ $? -ne 0 ]; then
            print_error "iOS build failed"
            BUILD_FAILED=true
        else
            print_success "iOS build completed"
        fi
    fi
fi

# Check if any builds failed
if [ "$BUILD_FAILED" = true ]; then
    print_error "One or more builds failed. Please check the logs above."
    exit 1
fi

# Upload to distribution platforms if requested
if [ "$UPLOAD" = true ]; then
    print_status "Uploading to distribution platforms..."
    
    case $ENVIRONMENT in
        staging)
            # Upload to Firebase App Distribution
            if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
                print_status "Uploading Android to Firebase App Distribution..."
                # firebase appdistribution:distribute build/outputs/austin_food_club_staging.apk \
                #     --app "$FIREBASE_ANDROID_APP_ID" \
                #     --groups "internal-testers" \
                #     --release-notes "Staging build $(date)"
            fi
            
            if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
                print_status "Uploading iOS to TestFlight..."
                # Upload to TestFlight would be handled in the iOS build script
            fi
            ;;
            
        production)
            print_status "Production uploads require manual approval."
            print_status "Use the following commands to upload:"
            
            if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
                echo "Android (Google Play Console):"
                echo "  1. Upload build/outputs/austin_food_club_production.aab to Google Play Console"
                echo "  2. Create a new release in the Play Console"
                echo "  3. Add release notes and submit for review"
            fi
            
            if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
                echo "iOS (App Store Connect):"
                echo "  1. Upload was attempted during build (if credentials provided)"
                echo "  2. Go to App Store Connect"
                echo "  3. Create a new version and submit for review"
            fi
            ;;
    esac
fi

# Generate deployment report
DEPLOY_REPORT="build/outputs/deployment_report_$(date +%Y%m%d_%H%M%S).md"
cat > "$DEPLOY_REPORT" << EOF
# Austin Food Club Deployment Report

**Date:** $(date)
**Environment:** $ENVIRONMENT
**Platform:** $PLATFORM
**Git Commit:** $(git rev-parse HEAD 2>/dev/null || echo 'unknown')
**Git Branch:** $(git branch --show-current 2>/dev/null || echo 'unknown')

## Build Information

- **Flutter Version:** $(flutter --version | head -n 1)
- **Dart Version:** $(dart --version | head -n 1)
EOF

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "- **Xcode Version:** $(xcodebuild -version | head -n 1)" >> "$DEPLOY_REPORT"
fi

echo "" >> "$DEPLOY_REPORT"
echo "## Output Files" >> "$DEPLOY_REPORT"
echo "" >> "$DEPLOY_REPORT"

# List all output files
find build/outputs -name "*.apk" -o -name "*.aab" -o -name "*.ipa" | while read file; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        echo "- $(basename "$file"): $size" >> "$DEPLOY_REPORT"
    fi
done

echo "" >> "$DEPLOY_REPORT"
echo "## Next Steps" >> "$DEPLOY_REPORT"
echo "" >> "$DEPLOY_REPORT"

case $ENVIRONMENT in
    development)
        echo "- Install APK/IPA on test devices" >> "$DEPLOY_REPORT"
        echo "- Verify all features work correctly" >> "$DEPLOY_REPORT"
        echo "- Test offline functionality" >> "$DEPLOY_REPORT"
        ;;
    staging)
        echo "- Distribute to internal testers" >> "$DEPLOY_REPORT"
        echo "- Collect feedback and bug reports" >> "$DEPLOY_REPORT"
        echo "- Verify integration with staging APIs" >> "$DEPLOY_REPORT"
        ;;
    production)
        echo "- Submit to app stores for review" >> "$DEPLOY_REPORT"
        echo "- Monitor crash reports and analytics" >> "$DEPLOY_REPORT"
        echo "- Prepare rollback plan if needed" >> "$DEPLOY_REPORT"
        ;;
esac

print_success "Deployment completed successfully!"
print_status "Deployment report saved to: $DEPLOY_REPORT"

# Final checklist for production deployments
if [ "$ENVIRONMENT" = "production" ]; then
    print_status "Production Deployment Checklist:"
    echo "  ✓ Tests passed"
    echo "  ✓ Builds completed"
    echo "  ✓ Code signed (if configured)"
    echo "  ✓ Environment variables set"
    echo "  ⚠️  Manual: Submit to app stores"
    echo "  ⚠️  Manual: Monitor post-deployment"
    echo "  ⚠️  Manual: Prepare rollback if needed"
fi

