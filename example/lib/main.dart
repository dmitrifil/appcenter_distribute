import 'package:flutter/material.dart';
import 'dart:async';

import 'package:appcenter_distribute/appcenter_distribute.dart';
import 'package:package_info/package_info.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        home: Main()
    );
  }
}

class Main extends StatefulWidget{
  const Main({Key? key}) : super(key: key);

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  var _initResult = false;
  var _isUpdate = false;
  var _version = '';
  var _buildNumber = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Appcenter Distribute $_version+$_buildNumber'),
        ),
        body: Center(
          child: Text('Running on: FlutterAppCenter v$_version+${_version == _buildNumber ? 0 : _buildNumber} \nresult: ${_initResult ? 'Initialize Successly' : 'appSecret must be not null'}\n${_isUpdate ? 'It has the latest version' : 'It\'s the latest version.' }'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => checkForUpdate(context),
          tooltip: 'Update',
          child: const Icon(Icons.update),
        )
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    AppCenterDistribute.init(
      appSecretAndroid: '4b240a24-0b36-4103-9990-ada028ab73d4',//'Your Android App Secret',
      appSecretIOS: '6c3a2ab7-386f-4605-8978-0300b6461c63',//'Your iOS App Secret'
      tokenAndroid: 'c03dc79718321b4e8cbaabc04a95fcdb792adde3',//'Your Android Token'
      tokenIOS: '2b8c5602e3caf419563069b0c161cd5c04ff20f2',//'Your iOS Token',
      groupIdAndroid: 'abed0875-951a-4bc6-8f0e-dfd2ffcb686f',
      groupIdIOS: '4507b530-e3ca-405d-965e-00d6df8eebc8',
      installUrlAndroid: 'https://install.appcenter.ms/users/dmitrifil-gmail.com/apps/appcenter/distribution_groups/all%20users',
      installUrlIOS: 'https://install.appcenter.ms/users/dmitrifil-gmail.com/apps/appcenter-ios/distribution_groups/all%20users',
    );
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _initResult = true;
    });

    final t = await checkForUpdate(context);

    setState(() {
      _isUpdate = t;
    });
  }
}

Future<bool> checkForUpdate(BuildContext context) async{
  return await AppCenterDistribute.checkForUpdate(
    context,
      title: 'App Update Avaiable',
      subTitle: 'Enjoy the lastest version',
      content: 'There is a new version available with the most advanced features, please click confirm to upgrade!',
      confirmButtonText: 'Install',
      cancelButtonText: 'Skip',
  );
}
