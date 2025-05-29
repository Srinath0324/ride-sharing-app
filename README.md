# ryde

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 🔧 Setup Instructions

### Firebase Configuration

1. **Copy the Firebase template files:**
   ```bash
   cp lib/firebase_options.template.dart lib/firebase_options.dart
   cp android/app/google-services.template.json android/app/google-services.json
   ```

2. **Get your Firebase configuration:**
   - Go to your [Firebase Console](https://console.firebase.google.com/)
   - Select your project (or create a new one)
   - Go to Project Settings > Your apps
   - Download the configuration files for each platform

3. **Replace the placeholder values:**
   - In `lib/firebase_options.dart` - Replace all `YOUR_*_HERE` placeholders with your actual Firebase values
   - In `android/app/google-services.json` - Replace with your actual Android configuration
   - For iOS: Add `ios/Runner/GoogleService-Info.plist` from Firebase Console

### Environment Variables

1. **Copy the environment template:**
   ```bash
   cp env.template .env
   ```

2. **Fill in your API keys:**
   - Add your Mapbox public token
   - Add any other required API keys

### Security Notice

⚠️ **IMPORTANT**: Never commit the following files to git:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `.env`

These files contain sensitive API keys and should be kept local only.

## Running the App

After completing the setup above, you can run the app normally:

```bash
flutter run
```
