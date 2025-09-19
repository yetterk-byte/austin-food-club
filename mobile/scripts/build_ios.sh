#!/bin/bash

# Austin Food Club iOS Build Script
# This script builds the iOS app for different environments

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
EXPORT_METHOD="app-store"

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
        -m|--method)
            EXPORT_METHOD="$2"
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
            echo "Austin Food Club iOS Build Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -t, --type TYPE        Build type (debug, staging, release) [default: release]"
            echo "  -e, --environment ENV  Environment (development, staging, production) [default: production]"
            echo "  -m, --method METHOD    Export method (app-store, ad-hoc, development, enterprise) [default: app-store]"
            echo "  -o, --output DIR       Output directory [default: build/outputs]"
            echo "  -c, --clean            Clean build (flutter clean before build)"
            echo "  -a, --analyze          Run code analysis before build"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                           # Build production for App Store"
            echo "  $0 -t debug -e development -m development   # Build development debug"
            echo "  $0 -t staging -e staging -m ad-hoc          # Build staging for TestFlight"
            echo "  $0 -t release -e production -c              # Clean build production"
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            exit 1
            ;;
    esac
done

print_status "Starting Austin Food Club iOS build..."
print_status "Build Type: $BUILD_TYPE"
print_status "Environment: $ENVIRONMENT"
print_status "Export Method: $EXPORT_METHOD"
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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "iOS builds can only be created on macOS"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or command line tools are not available"
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
    cd ios && pod install && cd ..
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

# Set environment variables
case $ENVIRONMENT in
    development)
        export FLUTTER_ENV="development"
        SCHEME="Runner"
        CONFIGURATION="Debug"
        ;;
    staging)
        export FLUTTER_ENV="staging"
        SCHEME="Runner"
        CONFIGURATION="Release"
        ;;
    production)
        export FLUTTER_ENV="production"
        SCHEME="Runner"
        CONFIGURATION="Release"
        ;;
esac

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build based on type
case $BUILD_TYPE in
    debug)
        print_status "Building iOS debug app..."
        flutter build ios --debug --no-codesign
        
        # Create debug IPA (simulator)
        print_status "Creating debug IPA for simulator..."
        cd ios
        xcodebuild -workspace Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Debug \
                   -destination 'generic/platform=iOS Simulator' \
                   -archivePath "../$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}_debug.xcarchive" \
                   archive
        cd ..
        ;;
        
    staging)
        print_status "Building iOS staging app..."
        flutter build ios --release --no-codesign
        
        # Create staging archive
        print_status "Creating staging archive..."
        cd ios
        xcodebuild -workspace Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -destination 'generic/platform=iOS' \
                   -archivePath "../$OUTPUT_DIR/austin_food_club_staging.xcarchive" \
                   archive
        
        # Export IPA for ad-hoc distribution
        print_status "Exporting staging IPA..."
        xcodebuild -exportArchive \
                   -archivePath "../$OUTPUT_DIR/austin_food_club_staging.xcarchive" \
                   -exportPath "../$OUTPUT_DIR/staging" \
                   -exportOptionsPlist "ExportOptions-AdHoc.plist"
        cd ..
        ;;
        
    release)
        print_status "Building iOS release app..."
        flutter build ios --release
        
        # Create release archive
        print_status "Creating release archive..."
        cd ios
        xcodebuild -workspace Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -destination 'generic/platform=iOS' \
                   -archivePath "../$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.xcarchive" \
                   archive
        
        # Export IPA based on method
        print_status "Exporting release IPA for $EXPORT_METHOD..."
        case $EXPORT_METHOD in
            app-store)
                xcodebuild -exportArchive \
                           -archivePath "../$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.xcarchive" \
                           -exportPath "../$OUTPUT_DIR/app-store" \
                           -exportOptionsPlist "ExportOptions-AppStore.plist"
                ;;
            ad-hoc)
                xcodebuild -exportArchive \
                           -archivePath "../$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.xcarchive" \
                           -exportPath "../$OUTPUT_DIR/ad-hoc" \
                           -exportOptionsPlist "ExportOptions-AdHoc.plist"
                ;;
            development)
                xcodebuild -exportArchive \
                           -archivePath "../$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.xcarchive" \
                           -exportPath "../$OUTPUT_DIR/development" \
                           -exportOptionsPlist "ExportOptions-Development.plist"
                ;;
            enterprise)
                xcodebuild -exportArchive \
                           -archivePath "../$OUTPUT_DIR/austin_food_club_${ENVIRONMENT}.xcarchive" \
                           -exportPath "../$OUTPUT_DIR/enterprise" \
                           -exportOptionsPlist "ExportOptions-Enterprise.plist"
                ;;
        esac
        cd ..
        ;;
esac

# Generate build info
BUILD_INFO_FILE="$OUTPUT_DIR/ios_build_info.json"
cat > "$BUILD_INFO_FILE" << EOF
{
  "platform": "ios",
  "buildType": "$BUILD_TYPE",
  "environment": "$ENVIRONMENT",
  "exportMethod": "$EXPORT_METHOD",
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "flutterVersion": "$(flutter --version | head -n 1)",
  "xcodeVersion": "$(xcodebuild -version | head -n 1)",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "buildMachine": "$(uname -a)"
}
EOF

# List output files
print_status "Build completed! Output files:"
find "$OUTPUT_DIR" -name "*.ipa" -o -name "*.xcarchive" | while read file; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        print_success "$(basename "$file"): $size"
    fi
done

# Validation for App Store builds
if [ "$EXPORT_METHOD" = "app-store" ] && [ "$BUILD_TYPE" = "release" ]; then
    print_status "Running App Store validation..."
    
    IPA_FILE=$(find "$OUTPUT_DIR/app-store" -name "*.ipa" | head -n 1)
    if [ -n "$IPA_FILE" ]; then
        # Validate with App Store Connect
        xcrun altool --validate-app \
                     --file "$IPA_FILE" \
                     --type ios \
                     --username "$APPLE_ID" \
                     --password "$APP_SPECIFIC_PASSWORD" 2>/dev/null || {
            print_warning "App Store validation failed or credentials not set"
            print_status "Set APPLE_ID and APP_SPECIFIC_PASSWORD environment variables for validation"
        }
    fi
fi

print_success "iOS build completed successfully!"
print_status "Build info saved to: $BUILD_INFO_FILE"

# Optional: Upload to TestFlight
if [ "$EXPORT_METHOD" = "app-store" ] && [ -n "$UPLOAD_TO_TESTFLIGHT" ]; then
    print_status "Uploading to TestFlight..."
    IPA_FILE=$(find "$OUTPUT_DIR/app-store" -name "*.ipa" | head -n 1)
    if [ -n "$IPA_FILE" ]; then
        xcrun altool --upload-app \
                     --file "$IPA_FILE" \
                     --type ios \
                     --username "$APPLE_ID" \
                     --password "$APP_SPECIFIC_PASSWORD"
    fi
fi

