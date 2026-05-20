# Android + Flutter Commands

## Shell setup

```bash
source ~/.profile
```

## Flutter basics

```bash
flutter doctor -v
flutter devices
flutter run
flutter run -d <device_id>
flutter build apk --debug
flutter build apk --release
flutter build appbundle
flutter test
flutter analyze
flutter clean
flutter pub get
flutter pub upgrade
```

## Project navigation

```bash
cd ~/flutter-apps/starter_app
flutter create .
```

## ADB basics

```bash
adb kill-server
adb start-server
adb devices
adb logcat
adb shell getprop ro.product.model
adb shell wm size
adb install -r ~/flutter-apps/starter_app/build/app/outputs/flutter-apk/app-debug.apk
```

## Android SDK tools

```bash
sdkmanager --list
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
```

## USB phone workflow

```bash
source ~/.profile
adb devices
flutter devices
cd ~/flutter-apps/starter_app
flutter run
```

## Wireless debugging

```bash
adb tcpip 5555
adb shell ip addr show wlan0
adb connect <phone_ip>:5555
adb devices
```

## Useful file paths

```bash
~/flutter-apps/starter_app/lib/main.dart
~/flutter-apps/starter_app/build/app/outputs/flutter-apk/app-debug.apk
~/tools/flutter
~/tools/jdk-21
~/Android/Sdk
```

## Troubleshooting

```bash
adb kill-server && adb start-server
flutter clean
flutter pub get
flutter doctor -v
```

If the phone does not appear:

- unlock the phone
- enable Developer options
- enable USB debugging
- set USB mode to File Transfer
- accept the USB debugging prompt
- reconnect the cable
