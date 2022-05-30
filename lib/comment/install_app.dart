import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:appcenter_distribute/comment/dao.dart';
import 'package:install_plugin/install_plugin.dart';

Future<void> installApk(String url,String appId,Function(int, int) showDownloadProgress) async {
  File _apkFile = await Dao().downloadAndroid(url,showDownloadProgress);
  String _apkFilePath = _apkFile.path;

  if (_apkFilePath.isEmpty) {
    debugPrint('make sure the apk file is set');
    return;
  }

  InstallPlugin.installApk(_apkFilePath, appId)
  .then((result) {
    debugPrint('install apk $result');
  }).catchError((error) {
    debugPrint('install apk error: $error');
  });
}