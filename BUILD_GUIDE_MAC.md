# Tunee App - Mac mini 构建指南

## 环境要求

- macOS 12.0 或更高版本
- 约 10GB 磁盘空间

---

## 第一步：安装 Homebrew

如果还没装，打开终端运行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## 第二步：安装 Flutter

```bash
# 使用 Homebrew 安装 Flutter
brew install flutter

# 验证安装
flutter doctor
```

---

## 第三步：安装 Android SDK

```bash
# 安装 Android Command Line Tools
brew install android-commandlinetools

# 设置环境变量（添加到 ~/.zshrc）
echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >> ~/.zshrc
echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="$ANDROID_HOME/platform-tools:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 安装必要组件
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

---

## 第四步：接受许可证

```bash
flutter doctor --android-licenses
```
按提示全部输入 `y` 接受。

---

## 第五步：构建 APK

```bash
# 进入项目目录
cd tunee_app

# 获取依赖
flutter pub get

# 构建 Release APK
flutter build apk --release
```

构建完成后，APK 位置：
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 常见问题

### 1. Flutter doctor 显示 Android toolchain 未安装
```bash
sdkmanager "platforms;android-34" "build-tools;34.0.0"
```

### 2. 构建时报 Java 版本错误
确保安装了 Java 17：
```bash
brew install openjdk@17
```

### 3. 找不到 Android SDK
检查环境变量：
```bash
echo $ANDROID_HOME
```
应该输出 `/Users/你的用户名/Library/Android/sdk`

---

## 验证环境

运行以下命令，确保都显示版本号：

```bash
flutter --version
java -version
adb --version
```

---

## 安装到手机

构建完成后，用 USB 连接手机（开启开发者模式），运行：

```bash
flutter install
```

或者把 `app-release.apk` 传到手机手动安装。
