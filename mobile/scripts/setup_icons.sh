#!/bin/bash

# Austin Food Club App Icon Setup Script
# This script helps set up app icons for both Android and iOS

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
SOURCE_ICON=""
GENERATE_ANDROID=true
GENERATE_IOS=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE_ICON="$2"
            shift 2
            ;;
        --android-only)
            GENERATE_ANDROID=true
            GENERATE_IOS=false
            shift
            ;;
        --ios-only)
            GENERATE_ANDROID=false
            GENERATE_IOS=true
            shift
            ;;
        -h|--help)
            echo "Austin Food Club App Icon Setup Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --source FILE      Source icon file (1024x1024 PNG recommended)"
            echo "  --android-only         Generate Android icons only"
            echo "  --ios-only             Generate iOS icons only"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Requirements:"
            echo "  - Source icon should be 1024x1024 pixels"
            echo "  - PNG format recommended"
            echo "  - ImageMagick or sips (macOS) for resizing"
            echo ""
            echo "Examples:"
            echo "  $0 -s assets/icon/app_icon.png"
            echo "  $0 -s icon.png --android-only"
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            exit 1
            ;;
    esac
done

# Check if source icon is provided
if [ -z "$SOURCE_ICON" ]; then
    print_error "Source icon file is required. Use -s option."
    echo "Example: $0 -s assets/icon/app_icon.png"
    exit 1
fi

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    print_error "Source icon file not found: $SOURCE_ICON"
    exit 1
fi

print_status "Setting up app icons from: $SOURCE_ICON"

# Check for image processing tools
RESIZE_TOOL=""
if command -v convert &> /dev/null; then
    RESIZE_TOOL="imagemagick"
    print_status "Using ImageMagick for image processing"
elif command -v sips &> /dev/null; then
    RESIZE_TOOL="sips"
    print_status "Using sips for image processing"
else
    print_error "No image processing tool found. Please install ImageMagick or use macOS with sips."
    exit 1
fi

# Function to resize image
resize_image() {
    local source="$1"
    local output="$2"
    local size="$3"
    
    mkdir -p "$(dirname "$output")"
    
    case $RESIZE_TOOL in
        imagemagick)
            convert "$source" -resize "${size}x${size}" "$output"
            ;;
        sips)
            sips -z "$size" "$size" "$source" --out "$output" > /dev/null
            ;;
    esac
}

# Android icon generation
if [ "$GENERATE_ANDROID" = true ]; then
    print_status "Generating Android icons..."
    
    # Android launcher icons
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" 48
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" 72
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png" 96
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png" 144
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" 192
    
    # Android notification icon (should be white/transparent)
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-mdpi/ic_notification.png" 24
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-hdpi/ic_notification.png" 36
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-xhdpi/ic_notification.png" 48
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-xxhdpi/ic_notification.png" 72
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-xxxhdpi/ic_notification.png" 96
    
    print_success "Android icons generated"
fi

# iOS icon generation
if [ "$GENERATE_IOS" = true ]; then
    print_status "Generating iOS icons..."
    
    # Create iOS icon directory
    IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
    mkdir -p "$IOS_ICON_DIR"
    
    # iOS app icons
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-20x20@1x.png" 20
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-20x20@2x.png" 40
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-20x20@3x.png" 60
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-29x29@1x.png" 29
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-29x29@2x.png" 58
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-29x29@3x.png" 87
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-40x40@1x.png" 40
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-40x40@2x.png" 80
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-40x40@3x.png" 120
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-60x60@2x.png" 120
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-60x60@3x.png" 180
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-76x76@1x.png" 76
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-76x76@2x.png" 152
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-83.5x83.5@2x.png" 167
    resize_image "$SOURCE_ICON" "$IOS_ICON_DIR/Icon-App-1024x1024@1x.png" 1024
    
    # Create Contents.json for iOS
    cat > "$IOS_ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    
    print_success "iOS icons generated"
fi

# Generate splash screen assets
print_status "Generating splash screen assets..."

# Android splash screen
if [ "$GENERATE_ANDROID" = true ]; then
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-mdpi/splash_icon.png" 96
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-hdpi/splash_icon.png" 144
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-xhdpi/splash_icon.png" 192
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-xxhdpi/splash_icon.png" 288
    resize_image "$SOURCE_ICON" "android/app/src/main/res/drawable-xxxhdpi/splash_icon.png" 384
fi

# iOS splash screen
if [ "$GENERATE_IOS" = true ]; then
    resize_image "$SOURCE_ICON" "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png" 200
    resize_image "$SOURCE_ICON" "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png" 400
    resize_image "$SOURCE_ICON" "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png" 600
fi

# Create adaptive icon for Android (API 26+)
if [ "$GENERATE_ANDROID" = true ]; then
    print_status "Creating adaptive icon..."
    
    # Foreground (icon)
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png" 108
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png" 162
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png" 216
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png" 324
    resize_image "$SOURCE_ICON" "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png" 432
    
    # Background (solid color - will be created as XML)
    mkdir -p android/app/src/main/res/drawable
    cat > android/app/src/main/res/drawable/ic_launcher_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
  <path
      android:fillColor="#000000"
      android:pathData="M0,0h108v108h-108z" />
</vector>
EOF

    # Adaptive icon XML
    cat > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
EOF

    cat > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
EOF
fi

# Verify generated icons
print_status "Verifying generated icons..."

if [ "$GENERATE_ANDROID" = true ]; then
    ANDROID_ICONS=(
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
    )
    
    for icon in "${ANDROID_ICONS[@]}"; do
        if [ -f "$icon" ]; then
            print_success "✓ $(basename "$icon")"
        else
            print_error "✗ $(basename "$icon") - Failed to generate"
        fi
    done
fi

if [ "$GENERATE_IOS" = true ]; then
    IOS_ICONS=(
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
    )
    
    for icon in "${IOS_ICONS[@]}"; do
        if [ -f "$icon" ]; then
            print_success "✓ $(basename "$icon")"
        else
            print_error "✗ $(basename "$icon") - Failed to generate"
        fi
    done
fi

print_success "App icon setup completed!"

# Instructions for manual steps
echo ""
print_status "Manual steps required:"
echo ""

if [ "$GENERATE_ANDROID" = true ]; then
    echo "Android:"
    echo "  1. Review generated icons in android/app/src/main/res/mipmap-*/"
    echo "  2. Consider creating a custom notification icon (white/transparent)"
    echo "  3. Test adaptive icon on Android 8.0+ devices"
    echo ""
fi

if [ "$GENERATE_IOS" = true ]; then
    echo "iOS:"
    echo "  1. Open ios/Runner.xcworkspace in Xcode"
    echo "  2. Verify app icons in Assets.xcassets/AppIcon.appiconset"
    echo "  3. Update launch screen if needed"
    echo "  4. Test on different device sizes"
    echo ""
fi

echo "General:"
echo "  1. Test app icon on various devices and OS versions"
echo "  2. Verify icon appears correctly in app stores"
echo "  3. Consider creating app store screenshots"
echo "  4. Update app store metadata with new icon"

print_warning "Note: Notification icons should be white/transparent for Android"
print_warning "Consider using a tool like https://appicon.co for professional icon generation"

