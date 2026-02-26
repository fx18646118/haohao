import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

// 文件工具类
class FileUtils {
  static final ImagePicker _imagePicker = ImagePicker();
  
  /// 请求存储权限
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }
  
  /// 请求相机权限
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  /// 请求麦克风权限
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  /// 从相册选择图片
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('选择图片失败: $e');
    }
    return null;
  }
  
  /// 从相机拍照
  static Future<File?> pickImageFromCamera() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) return null;
      
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('拍照失败: $e');
    }
    return null;
  }
  
  /// 选择视频
  static Future<File?> pickVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('选择视频失败: $e');
    }
    return null;
  }
  
  /// 选择音频文件
  static Future<File?> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return File(file.path!);
        }
      }
    } catch (e) {
      print('选择音频失败: $e');
    }
    return null;
  }
  
  /// 选择任意文件
  static Future<File?> pickFile({List<String>? allowedExtensions}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return File(file.path!);
        }
      }
    } catch (e) {
      print('选择文件失败: $e');
    }
    return null;
  }
  
  /// 获取文件大小（字节）
  static Future<int?> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return null;
    }
  }
  
  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 获取应用缓存目录
  static Future<Directory?> getCacheDirectory() async {
    try {
      return await getTemporaryDirectory();
    } catch (e) {
      return null;
    }
  }
  
  /// 获取应用文档目录
  static Future<Directory?> getDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      return null;
    }
  }
  
  /// 下载文件
  static Future<File?> downloadFile(String url, String savePath) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print('下载文件失败: $e');
    }
    return null;
  }
  
  /// 下载文件到缓存目录
  static Future<File?> downloadToCache(String url, {String? fileName}) async {
    try {
      final cacheDir = await getCacheDirectory();
      if (cacheDir == null) return null;
      
      final name = fileName ?? path.basename(url);
      final savePath = path.join(cacheDir.path, name);
      
      return await downloadFile(url, savePath);
    } catch (e) {
      print('下载到缓存失败: $e');
      return null;
    }
  }
  
  /// 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('删除文件失败: $e');
    }
    return false;
  }
  
  /// 清理缓存文件
  static Future<void> clearCache() async {
    try {
      final cacheDir = await getCacheDirectory();
      if (cacheDir != null && await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      print('清理缓存失败: $e');
    }
  }
  
  /// 读取文件为 base64
  static Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('文件转base64失败: $e');
      return null;
    }
  }
}
