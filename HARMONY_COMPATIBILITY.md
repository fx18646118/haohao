# Tunee App - 鸿蒙系统兼容说明

## 系统要求

- **鸿蒙 OS 2.0+** (兼容 Android 10+)
- **最低 SDK**: API 21 (Android 5.0)
- **目标 SDK**: API 33 (Android 13)

## 鸿蒙兼容性配置

### 1. 已配置的兼容选项

在 `android/app/build.gradle` 中：
```gradle
minSdkVersion 21  // 支持鸿蒙10/Android 5.0+
targetSdkVersion 33
```

在 `AndroidManifest.xml` 中：
```xml
android:requestLegacyExternalStorage="true"  // 兼容旧版存储
android:usesCleartextTraffic="true"          // 允许明文传输
```

### 2. 权限说明

鸿蒙系统可能需要额外授权：

| 权限 | 用途 | 鸿蒙注意事项 |
|------|------|-------------|
| 存储权限 | 保存/读取音乐文件 | 鸿蒙10需手动开启"允许访问所有文件" |
| 录音权限 | 音频输入参考 | 首次使用需授权 |
| 相机权限 | 拍照/视频输入 | 可选权限 |
| 网络权限 | API 调用 | 必需权限 |

### 3. 鸿蒙系统设置

安装后如遇到权限问题，请手动设置：

1. **设置 → 应用 → Tunee → 权限**
2. 开启以下权限：
   - 存储（选择"允许"）
   - 麦克风（如需要使用音频输入）
   - 相机（如需要使用图片/视频）

3. **电池优化**（避免后台被杀）：
   - 设置 → 电池 → 应用启动管理
   - 找到 Tunee，选择"手动管理"
   - 开启"允许后台活动"

## 构建 APK

### 方法1：本地构建

```bash
# 1. 安装 Flutter
https://flutter.dev/docs/get-started/install

# 2. 进入项目目录
cd tunee_app

# 3. 获取依赖
flutter pub get

# 4. 构建 APK（兼容鸿蒙）
flutter build apk --release --target-platform android-arm64

# 5. APK 位置
build/app/outputs/flutter-apk/app-release.apk
```

### 方法2：GitHub Actions 自动构建

1. 推送代码到 GitHub
2. 进入 Actions 页面
3. 运行 "Build Android APK" workflow
4. 下载 artifacts 中的 APK

## 安装到鸿蒙手机

### 方式1：直接安装
```bash
# 通过 ADB 安装
adb install app-release.apk
```

### 方式2：文件传输
1. 将 APK 复制到手机
2. 文件管理器中找到 APK
3. 点击安装（可能需要允许"未知来源"）

### 方式3：华为应用市场（如需上架）
需申请华为开发者账号，提交审核

## 常见问题

### Q: 鸿蒙系统提示"此应用专为旧版Android打造"？
A: 这是正常现象，Flutter 应用完全兼容鸿蒙。点击"仍要安装"即可。

### Q: 无法访问存储/无法保存音乐？
A: 手动开启存储权限：设置 → 应用 → Tunee → 权限 → 存储 → 允许

### Q: 后台播放被中断？
A: 关闭电池优化：设置 → 电池 → 应用启动管理 → Tunee → 手动管理 → 允许后台活动

### Q: 网络请求失败？
A: 检查网络权限和防火墙设置，确保可以访问配置的 API 地址

## 测试设备

已在以下环境测试：
- ✅ 鸿蒙 OS 2.0 (Android 10)
- ✅ 鸿蒙 OS 3.0 (Android 12)
- ✅ 鸿蒙 OS 4.0 (Android 13)
- ✅ Android 10/11/12/13

## 技术支持

如遇到鸿蒙系统兼容性问题，请提供：
1. 手机型号
2. 鸿蒙版本号
3. 问题描述
4. 截图或录屏
