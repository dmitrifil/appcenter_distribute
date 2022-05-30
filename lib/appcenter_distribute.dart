library appcenter_distribute;

import 'dart:async';
import 'dart:io';

import 'package:android_metadata/android_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appcenter_distribute/comment/check_permission.dart';
import 'package:appcenter_distribute/comment/configs.dart';
import 'package:appcenter_distribute/comment/dao.dart';
import 'package:appcenter_distribute/comment/install_app.dart';
import 'package:appcenter_distribute/components/update_dialog.dart';
import 'package:open_appstore/open_appstore.dart';
import 'package:package_info/package_info.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AppCenterDistribute {
  // static const MethodChannel _channel = MethodChannel('flutter_appcenter');
  static String appSecret = '';
  static String token = '';
  static String appId = '';
  static String betaUrl = '';

  static var dialogUpdateSingle;

  /// start running the AppCenert
  static void init({
    String? appSecretAndroid,
    String? appSecretIOS,
    String? tokenAndroid,
    String? tokenIOS,
    String? appIdAndroid,
    String? appIdIOS,
    String? betaUrlAndroid,
    String? betaUrlIOS,

    /// set private or public distribution group
    /// defualut value is publice
    bool usePrivateTrack = false,

  }) {
    final _appSecret = Platform.isAndroid ? appSecretAndroid : appSecretIOS;
    final _token = Platform.isAndroid ? tokenAndroid : tokenIOS;
    if(Platform.isAndroid){
      appId = appIdAndroid ?? '';
      betaUrl = betaUrlAndroid ?? '';
    }else{
      appId = appIdIOS ?? '';
      betaUrl = betaUrlIOS ?? '';
    }

    assert(_appSecret != null && _appSecret.isNotEmpty,'appSecret must be not null.');
    assert(_token != null && _token.isNotEmpty,'token must be not null.');

    appSecret = _appSecret!;
    token = _token!;
  }

  /// update dialog
  static Future<bool> checkForUpdate(BuildContext context,{
    /// aim to replace appcenter's download url if it is not empty
    String downloadUrlAndroid = '',
    String channelGooglePlay = 'play',
    String channelProduct = 'prod',
    Map<String, String> dialog = const {}
  }) async{
    final ProgressDialog _progress = ProgressDialog(context,isDismissible: false);
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    var _requestResult = {};

    dialog['title'] = dialog['title'] ?? 'App update avaiable';
    dialog['subTitle'] = dialog['subTitle'] ?? '';
    dialog['content'] = dialog['content'] ?? ''; // defualt to show the releaseNotes and version
    dialog['confirmButtonText'] = dialog['confirmButtonText'] ?? 'Confirm';
    dialog['middleButtonText'] = dialog['middleButtonText'] ?? '';
    dialog['cancelButtonText'] = dialog['cancelButtonText'] ?? 'Postpone';
    dialog['downloadingText'] = dialog['downloadingText'] ?? 'Downloading File...';

    if(dialog['middleButtonText']?.isNotEmpty == true){
      assert(betaUrl.isNotEmpty,'middleButtonText and betaUrl both must be not null or empty.');
    }

    void updateAppForAndroid() async{
      Map<String, dynamic> metadata =
          (await AndroidMetadata.metaDataAsMap) ?? {};
      if(metadata['UMENG_CHANNEL'] == channelGooglePlay){
        await _progress.hide();
        try{
          OpenAppstore.launch(androidAppId: _packageInfo.packageName);
        }catch(e){
          String storeLink = Configs.googlePlayStore(_packageInfo.packageName);

          if (await canLaunch(storeLink)) {
            await launch(storeLink);
          } else {
            throw('can not open google play');
          }
        }
      }else{ /// channels of the others
        if(await checkPermission()){
          if(downloadUrlAndroid.isNotEmpty){
            _requestResult['download_url'] = downloadUrlAndroid;
          }
          debugPrint(_requestResult['download_url']);
          try{
            await installApk(_requestResult['download_url'],_packageInfo.packageName,(received, total) async{
              _progress.update(
                message: dialog['downloadingText'],
                progress: received/total,
                progressWidget: Container(
                    padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator(
                    value: received/total
                )
                ),
                maxProgress: 1,
              );

              if(received == total){
                await _progress.hide();
              }
            });
          }catch(e){
            _progress.update(
                message: 'fail to update: $e'
            );
            await _progress.hide();
          }
        } else {
          await _progress.hide();
        }
      }
    }

    void updateAppForBeta() async{
      if(await canLaunch(betaUrl)) {
        await launch(betaUrl);
      } else {
        if(betaUrl.contains('itms-beta')){
          await launch(betaUrl.replaceFirst(RegExp(r'itms-beta'), 'https'));
        }else{
          debugPrint('can not open testflight');
        }
      }
    }

    void updateAppForIOS() async{
      if(appId.isNotEmpty){
        OpenAppstore.launch(iOSAppId: appId);
      }else{
        updateAppForBeta();
      }
    }

    void showUpdateDialog() async{
      String content = '';
      dialog['subTitle'] = dialog['subTitle']! + ' ${_requestResult['short_version']}(${_requestResult['version']})';

      if(dialog['content']?.isNotEmpty == true){
        content = dialog['content']!;
      }else{
        content = _requestResult['release_notes'];
      }

      if(dialogUpdateSingle == null){
        dialogUpdateSingle = await showDialog(
            context: context,
            barrierDismissible: (_requestResult['mandatory_update'] == false),
            builder: (BuildContext ctx) {
              return WillPopScope(
                onWillPop: () async =>
                  (_requestResult['mandatory_update'] == false),
                child: UpdateDialog(
                  mandatoryUpdate: _requestResult['mandatory_update'],
                  title: '${dialog['title']}',
                  subTitle: dialog['subTitle'] ?? '',
                  content: content,
                  confirmButtonText: dialog['confirmButtonText']!,
                  middleButtonText: dialog['middleButtonText']!,
                  cancelButtonText: dialog['cancelButtonText']!,
                  onMiddle: () async{
                    if(Platform.isIOS && betaUrl.isNotEmpty){
                      updateAppForBeta();
                    }
                  },
                  onConfirm: () async{
                    await _progress.show();
                    if(Platform.isAndroid){
                      updateAppForAndroid();
                    }else{
                      await _progress.hide();
                      updateAppForIOS();
                    }
                  },
                ),
              );
            }
        );
      }else{
        dialogUpdateSingle();
      }
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
    // if (res !is Map) return false;
    // _requestResult = res;

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

    return false;
  }
}

