import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// OTA 更新服务：从 GitHub Pages 检查版本，下载并安装新 APK
class UpdateService {
  // 替换为你的 GitHub Pages 地址
  static const _versionUrl = 'https://rsreeuzxsxotybuuifyh.supabase.co/storage/v1/object/public/ota/version.json';

  /// 检查是否有新版本，返回 (有新版本, 下载地址, 版本号)
  static Future<(bool, String?, String?)> checkUpdate() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));
      if (response.statusCode != 200) return (false, null, null);

      final data = json.decode(response.body);
      final remoteVersion = data['version'] as String;
      final downloadUrl = data['download_url'] as String;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_compareVersion(remoteVersion, currentVersion) > 0) {
        return (true, downloadUrl, remoteVersion);
      }
      return (false, null, null);
    } catch (_) {
      return (false, null, null);
    }
  }

  /// 下载 APK 到本地
  static Future<String> downloadApk(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/update.apk';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  /// 弹出更新对话框
  static void showUpdateDialog(BuildContext context, String version, VoidCallback onDownload) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('发现新版本'),
        content: Text('新版本 $version 已发布，是否更新？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('稍后')),
          FilledButton(onPressed: () {
            Navigator.pop(context);
            onDownload();
          }, child: const Text('立即更新')),
        ],
      ),
    );
  }

  /// 安装 APK 文件
  static Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath);
  }

  /// 版本号比较：返回 >0 表示 v1 > v2
  static int _compareVersion(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final a = i < parts1.length ? parts1[i] : 0;
      final b = i < parts2.length ? parts2[i] : 0;
      if (a != b) return a - b;
    }
    return 0;
  }
}
