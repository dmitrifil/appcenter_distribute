library appcenter_distribute;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:appcenter_distribute/comment/configs.dart';
import 'package:appcenter_distribute/comment/dao.dart';
import 'package:appcenter_distribute/components/update_dialog.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AppCenterDistribute {
  static String appSecret = '';
  static String token = '';
  static String groupId = '';
  static String installUrl = '';

  static var _initialized = false;
  static var _running = false;

  static void init({
    String? appSecretAndroid,
    String? appSecretIOS,
    String? tokenAndroid,
    String? tokenIOS,
    String? groupIdAndroid,
    String? groupIdIOS,
    String? installUrlAndroid,
    String? installUrlIOS,
  }) {
    String? _appSecret;
    String? _token;
    String? _groupId;
    String? _installUrl;
    if (Platform.isAndroid) {
      _appSecret = appSecretAndroid;
      _token = tokenAndroid;
      _groupId = groupIdAndroid;
      _installUrl = installUrlAndroid;
    } else {
      _appSecret = appSecretIOS;
      _token = tokenIOS;
      _groupId = groupIdIOS;
      _installUrl = installUrlIOS;
    }
    assert(_appSecret != null && _appSecret.isNotEmpty, 'appSecret must be not empty.');
    assert(_token != null && _token.isNotEmpty, 'token must be not empty.');
    assert(_groupId != null && _groupId.isNotEmpty, 'groupId must be not empty.');
    assert(_installUrl != null && _installUrl.isNotEmpty, 'installUrl must be not empty.');
    appSecret = _appSecret!;
    token = _token!;
    groupId = _groupId!;
    installUrl = _installUrl!;

    _initialized = true;
  }

  static Future<bool> checkForUpdate(BuildContext context,{
    String title = 'App update available',
    String subTitle = '',
    String content = '',
    String confirmButtonText = 'Install',
    String cancelButtonText = 'Skip',
  }) async{
    if (!_initialized || _running) return false;
    _running = true;

    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    var _requestResult = {};

    void showUpdateDialog() async{
      subTitle = subTitle + ' ${_requestResult['short_version']}(${_requestResult['version']})';

      if (content.isEmpty) content = _requestResult['release_notes'];

      await showDialog(
          context: context,
          barrierDismissible: (_requestResult['mandatory_update'] == false),
          builder: (BuildContext ctx) {
            return WillPopScope(
              onWillPop: () async =>
                (_requestResult['mandatory_update'] == false),
              child: UpdateDialog(
                mandatoryUpdate: _requestResult['mandatory_update'],
                title: title,
                subTitle: subTitle,
                content: content,
                confirmButtonText: confirmButtonText,
                cancelButtonText: cancelButtonText,
                onConfirm: () async{
                  await launchUrl(Uri.parse(installUrl));
                },
              ),
            );
          }
      );

      _running = false;
    }

    /// step 1: abtain the app vesion
    String _version = _packageInfo.version;
    String _buildNumber = _packageInfo.buildNumber;
    debugPrint('local version: $_version+$_buildNumber');
    if(_version == _buildNumber){
      _buildNumber = '0';
    }

    /// step 2: require latest version from AppCenter
    Dao.token = token;
    var dao = Dao();
    _requestResult = await dao.get(url: Configs.latestVersionUrl(appSecret));

    debugPrint('latestUrl:${Configs.latestVersionUrl(appSecret)}');
    debugPrint('remote version: ${_requestResult['short_version']}+${_requestResult['version']}');

    /// step 3: compare the app's verion and build number with the remote's
    if(_version != _requestResult['short_version']){
      List<String> versionArr = _version.split('.');
      List<String> remoteVersionArr = _requestResult['short_version'].split('.');

      for(int i = 0; i < remoteVersionArr.length; i++){
        if(int.parse(remoteVersionArr[i]) > int.parse(versionArr[i])){
          showUpdateDialog();
          return true;
        }
      }
    }else if(_buildNumber != _requestResult['version'] && int.parse(_requestResult['version']) > int.parse(_buildNumber)){
      showUpdateDialog();
      return true;
    }

    _running = false;
    return false;
  }
}