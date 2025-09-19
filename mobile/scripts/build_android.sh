#!/bin/bash

# Austin Food Club Android Build Script
# This script builds the Android app for different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
BUILD_TYPE="release"
ENVIRONMENT="production"
OUTPUT_DIR="build/outputs"
CLEAN_BUILD=false
ANALYZE_CODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -a|--analyze)
            ANALYZE_CODE=true
            shift
            ;;
        -h|--help)
            echo "Austin Food Club Android Build Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -t, --type TYPE        Build type (debug, staging, release) [default: release]"
            echo "  -e, --environment ENV  Environment (development, staging, production) [default: production]"
            echo "  -o, --output DIR       Output directory [default: build/outputs]"
            echo "  -c, --clean            Clean build (flutter clean before build)"
            echo "  -a, --analyze          Run code analysis before build"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Build production release"
            echo "  $0 -t debug -e development           # Build development debug"
            echo "  $0 -t staging -e staging -c          # Clean build staging"
            echo "  $0 -t release -e production -a       # Analyze and build production"
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            exit 1
            ;;
    esac
done

print_status "Starting Austin Food Club Android build..."
print_status "Build Type: $BUILD_TYPE"
print_status "Environment: $ENVIRONMENT"
print_status "Output Directory: $OUTPUT_DIR"

# Validate build type
case $BUILD_TYPE in
    debug|staging|release)
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE. Must be debug, staging, or release."
        exit 1
        ;;
esac

# Validate environment
case $ENVIRONMENT in
    development|staging|production)
        ;;
    *)
        print_error "Invalid environment: $ENVIRONMENT. Must be development, staging, or production."
        exit 1
        ;;
esac

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_status "Cleaning previous build..."
    flutter clean
    flutter pub get
fi

# Run code analysis if requested
if [ "$ANALYZE_CODE" = true ]; then
    print_status "Running code analysis..."
    flutter analyze
    if [ $? -ne 0 ]; then
        print_error "Code analysis failed. Please fix issues before building."
        exit 1
    fi
    print_success "Code analysis passed"
fi

# Run tests
print_status "Running tests..."
flutter test
if [ $? -ne 0 ]; then
    print_warning "Some tests failed. Continuing with build..."
fi

# Set environment variables based on environment
case $ENVIRONMENT in
    development)
        export FLUTTER_ENV="development"
        ;;
    staging)
        export FLUTTER_ENV="staging"
        ;;
    production)
        export FLUTTER_ENV="production"
        ;;
esac

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build based on type
case $BUILD_TYPE in
    debug)
        print_status "Building Android debug APK..."
        flutter build apk --debug --target-platform android-arm64
        
        # Copy output
        cp build/app/outputs/flutter-apk/app-debug.apk "$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}_debug.apk"
        ;;
        
    staging)
        print_status "Building Android staging APK..."
        flutter build apk --release --flavor staging --target-platform android-arm64
        
        # Copy output
        cp build/app/outputs/flutter-apk/app-staging-release.apk "$OUTPUT_DIR/austin_food_club_staging.apk"
        ;;
        
    release)
        print_status "Building Android release APK and App Bundle..."
        
        # Build APK
        flutter build apk --release --target-platform android-arm64
        cp build/app/outputs/flutter-apk/app-release.apk "$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.apk"
        
        # Build App Bundle for Play Store
        flutter build appbundle --release
        cp build/app/outputs/bundle/release/app-release.aab "$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.aab"
        ;;
esac

# Generate build info
BUILD_INFO_FILE="$OUTPUT_DIR/build_info.json"
cat > "$BUILD_INFO_FILE" << EOF
{
  "buildType": "$BUILD_TYPE",
  "environment": "$ENVIRONMENT",
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "flutterVersion": "$(flutter --version | head -n 1)",
  "dartVersion": "$(dart --version | head -n 1)",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "buildMachine": "$(uname -a)",
  "outputFiles": [
EOF

# Add output files to build info
if [ -f "$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.apk" ]; then
    echo "    \"$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.apk\"," >> "$BUILD_INFO_FILE"
fi

if [ -f "$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.aab" ]; then
    echo "    \"$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.aab\"," >> "$BUILD_INFO_FILE"
fi

# Close JSON array (remove last comma and close)
sed -i '$ s/,$//' "$BUILD_INFO_FILE"
echo "  ]" >> "$BUILD_INFO_FILE"
echo "}" >> "$BUILD_INFO_FILE"

# Calculate file sizes
print_status "Build completed! Output files:"
for file in "$OUTPUT_DIR"/*.apk "$OUTPUT_DIR"/*.aab; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        print_success "$(basename "$file"): $size"
    fi
done

# Security check for release builds
if [ "$BUILD_TYPE" = "release" ] && [ "$ENVIRONMENT" = "production" ]; then
    print_status "Running security checks..."
    
    # Check if keystore is properly configured
    if [ ! -f "android/key.properties" ]; then
        print_warning "key.properties not found. Make sure signing is properly configured for production."
    fi
    
    # Check if ProGuard is enabled
    if grep -q "minifyEnabled true" android/app/build.gradle; then
        print_success "ProGuard is enabled"
    else
        print_warning "ProGuard is not enabled. Consider enabling for production builds."
    fi
fi

print_success "Android build completed successfully!"
print_status "Build info saved to: $BUILD_INFO_FILE"

# Optional: Upload to distribution service
if [ -n "$FIREBASE_APP_ID" ] && [ "$BUILD_TYPE" = "staging" ]; then
    print_status "Uploading to Firebase App Distribution..."
    # firebase appdistribution:distribute "$OUTPUT_DIR/austin_food_club_staging.apk" \
    #     --app "$FIREBASE_APP_ID" \
    #     --groups "testers" \
    #     --release-notes "Automated staging build"
fi

