# Austin Food Club - Deployment Guide

This guide covers the complete deployment process for the Austin Food Club Flutter application.

## 📋 Prerequisites

### Development Environment
- **Flutter SDK**: 3.0.0 or later
- **Dart SDK**: 3.0.0 or later
- **Android Studio**: Latest stable version
- **Xcode**: 14.0 or later (for iOS builds, macOS only)
- **Git**: For version control

### Platform Requirements

#### Android
- **Android SDK**: API level 21 (Android 5.0) minimum
- **Java**: JDK 11 or later
- **Gradle**: 7.5 or later
- **Keystore**: For release signing

#### iOS
- **macOS**: Required for iOS builds
- **Xcode**: 14.0 or later
- **iOS Deployment Target**: 12.0 minimum
- **Apple Developer Account**: For distribution
- **Provisioning Profiles**: For code signing

## 🔧 Environment Setup

### 1. Clone and Setup
```bash
git clone https://github.com/your-org/austin-food-club-flutter.git
cd austin-food-club-flutter
flutter pub get
```

### 2. Environment Configuration
The app uses different configurations for different environments:

- **Development**: Local development with debug features
- **Staging**: Pre-production testing environment
- **Production**: Live production environment

Environment settings are configured in `lib/config/environment.dart`.

### 3. API Keys and Secrets
Create the following files with your actual keys:

#### Android Signing (`android/key.properties`)
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../keystore/austin_food_club_release.jks
```

#### Environment Variables
Update `lib/config/environment.dart` with your actual:
- Supabase URLs and keys
- Firebase configuration
- Google Maps API keys
- Analytics tokens

## 🏗️ Building the App

### Android Builds

#### Debug Build
```bash
# Quick debug build
flutter build apk --debug

# Using build script
./scripts/build_android.sh -t debug -e development
```

#### Staging Build
```bash
# Staging APK
flutter build apk --release --flavor staging

# Using build script
./scripts/build_android.sh -t staging -e staging
```

#### Production Build
```bash
# Production APK
flutter build apk --release

# Production App Bundle (for Play Store)
flutter build appbundle --release

# Using build script (builds both APK and AAB)
./scripts/build_android.sh -t release -e production
```

### iOS Builds

#### Debug Build
```bash
# Debug build
flutter build ios --debug --no-codesign

# Using build script
./scripts/build_ios.sh -t debug -e development -m development
```

#### Staging Build
```bash
# Staging build for TestFlight
flutter build ios --release

# Using build script
./scripts/build_ios.sh -t staging -e staging -m ad-hoc
```

#### Production Build
```bash
# Production build for App Store
flutter build ios --release

# Using build script
./scripts/build_ios.sh -t release -e production -m app-store
```

### Universal Deployment Script
```bash
# Deploy both platforms to production
./scripts/deploy.sh

# Deploy specific platform and environment
./scripts/deploy.sh -p android -e staging
./scripts/deploy.sh -p ios -e production -u
```

## 📱 Platform-Specific Configuration

### Android Configuration

#### 1. Permissions (`android/app/src/main/AndroidManifest.xml`)
- ✅ Internet and network access
- ✅ Camera and photo library
- ✅ Location services
- ✅ Push notifications
- ✅ Biometric authentication
- ✅ File access for photo sharing

#### 2. ProGuard Rules (`android/app/proguard-rules.pro`)
- ✅ Flutter and Dart obfuscation protection
- ✅ Firebase and Google services
- ✅ Image processing libraries
- ✅ Database and networking libraries
- ✅ Model class preservation

#### 3. Build Configuration (`android/app/build.gradle`)
- ✅ Multi-environment support (debug, staging, release)
- ✅ Signing configuration
- ✅ ProGuard optimization
- ✅ App bundle configuration
- ✅ Firebase integration

#### 4. App Icons
Place app icons in:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

### iOS Configuration

#### 1. Permissions (`ios/Runner/Info.plist`)
- ✅ Camera usage description
- ✅ Photo library access
- ✅ Location services
- ✅ Face ID / Touch ID
- ✅ Calendar access for reminders
- ✅ Background modes for notifications

#### 2. Code Signing
- **Development**: Automatic signing with development team
- **Staging**: Ad-hoc distribution profile
- **Production**: App Store distribution profile

#### 3. Export Options
- `ExportOptions-AppStore.plist`: App Store distribution
- `ExportOptions-AdHoc.plist`: TestFlight and internal distribution
- `ExportOptions-Development.plist`: Development builds

#### 4. App Icons
Place app icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:
- Icon-App-20x20@1x.png through Icon-App-1024x1024@1x.png
- All required sizes for iPhone and iPad

## 🚀 Deployment Process

### Development Deployment
1. **Build**: `./scripts/deploy.sh -e development`
2. **Test**: Install on test devices
3. **Verify**: Check all features work offline/online

### Staging Deployment
1. **Build**: `./scripts/deploy.sh -e staging -u`
2. **Distribute**: Firebase App Distribution (Android) / TestFlight (iOS)
3. **Test**: Internal testing with real users
4. **Collect**: Feedback and crash reports

### Production Deployment

#### Pre-deployment Checklist
- [ ] All tests passing
- [ ] Code review completed
- [ ] Staging testing completed
- [ ] Release notes prepared
- [ ] Rollback plan ready
- [ ] App store metadata updated

#### Android (Google Play Store)
1. **Build**: `./scripts/deploy.sh -p android -e production`
2. **Upload**: Upload `.aab` file to Google Play Console
3. **Release**: Create new release with release notes
4. **Submit**: Submit for review
5. **Monitor**: Track deployment and user feedback

#### iOS (App Store)
1. **Build**: `./scripts/deploy.sh -p ios -e production -u`
2. **TestFlight**: Upload automatically goes to TestFlight
3. **App Store**: Submit for App Store review
4. **Monitor**: Track review status and user feedback

## 🔐 Security Configuration

### Code Signing

#### Android
1. **Generate Keystore**:
   ```bash
   keytool -genkey -v -keystore austin_food_club_release.jks \
           -keyalg RSA -keysize 2048 -validity 10000 \
           -alias austin_food_club
   ```

2. **Configure Signing**:
   - Copy keystore to `android/keystore/`
   - Update `android/key.properties`
   - Ensure `build.gradle` references keystore

#### iOS
1. **Apple Developer Account**: Required for distribution
2. **Certificates**: Development and distribution certificates
3. **Provisioning Profiles**: App-specific profiles
4. **Automatic Signing**: Recommended for simplicity

### Security Features
- ✅ Certificate pinning (production only)
- ✅ Root detection (production only)
- ✅ Code obfuscation (ProGuard/R8)
- ✅ API key protection
- ✅ Secure storage for sensitive data

## 📊 Monitoring and Analytics

### Crash Reporting
- **Firebase Crashlytics**: Automatic crash reporting
- **Sentry**: Advanced error tracking (optional)

### Analytics
- **Firebase Analytics**: User behavior tracking
- **Google Analytics**: Web analytics integration

### Performance Monitoring
- **Firebase Performance**: App performance metrics
- **Custom Metrics**: Business-specific tracking

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Build and Deploy
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: ./scripts/build_android.sh -t release -e production

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: ./scripts/build_ios.sh -t release -e production
```

## 📋 Build Commands Reference

### Quick Commands
```bash
# Android
flutter build apk --release                    # Release APK
flutter build appbundle --release              # Release App Bundle
flutter build apk --debug                      # Debug APK

# iOS
flutter build ios --release                    # Release iOS
flutter build ios --debug --no-codesign        # Debug iOS

# Both platforms
./scripts/deploy.sh                            # Production build both
./scripts/deploy.sh -e staging                 # Staging build both
```

### Advanced Commands
```bash
# Clean builds
./scripts/build_android.sh -c -a               # Clean + analyze Android
./scripts/build_ios.sh -c -a                   # Clean + analyze iOS

# Specific configurations
flutter build apk --release --target-platform android-arm64
flutter build ios --release --no-tree-shake-icons

# With custom build number
flutter build apk --release --build-number=1001
flutter build ios --release --build-number=1001
```

## 🐛 Troubleshooting

### Common Android Issues

#### Build Failures
- **Gradle Issues**: Run `./gradlew clean` in `android/` directory
- **Dependency Conflicts**: Check `android/app/build.gradle` dependencies
- **ProGuard Issues**: Review `android/app/proguard-rules.pro`

#### Signing Issues
- **Keystore Not Found**: Verify `android/key.properties` path
- **Wrong Passwords**: Double-check keystore passwords
- **Missing Alias**: Verify key alias in properties file

### Common iOS Issues

#### Build Failures
- **Pod Issues**: Run `cd ios && pod install && cd ..`
- **Xcode Version**: Ensure Xcode is up to date
- **Provisioning**: Check provisioning profiles in Xcode

#### Code Signing Issues
- **Certificate Expired**: Renew certificates in Apple Developer
- **Profile Mismatch**: Ensure bundle ID matches provisioning profile
- **Team Issues**: Verify development team in Xcode

### Environment Issues
- **API Keys**: Verify all API keys are set correctly
- **Network Issues**: Check firewall and proxy settings
- **Permissions**: Ensure all required permissions are granted

## 📈 Post-Deployment

### Monitoring
1. **Crash Reports**: Monitor Firebase Crashlytics
2. **Performance**: Check app performance metrics
3. **User Feedback**: Monitor app store reviews
4. **Analytics**: Track user engagement and retention

### Updates
1. **Hotfixes**: Critical bug fixes
2. **Feature Updates**: New features and improvements
3. **Security Updates**: Security patches and updates

### Rollback Plan
1. **Identify Issue**: Monitor metrics and user reports
2. **Assess Impact**: Determine if rollback is necessary
3. **Execute Rollback**: Revert to previous stable version
4. **Communicate**: Notify users of the issue and resolution

## 📞 Support

### Build Support
- Check build logs in `build/outputs/`
- Review deployment reports
- Contact development team for build issues

### Production Support
- Monitor crash reports and analytics
- Respond to user feedback promptly
- Maintain regular update schedule

---

**Last Updated**: December 2023
**Version**: 1.0.0
**Contact**: dev-team@austinfoodclub.com

