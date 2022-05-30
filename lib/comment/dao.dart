import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:appcenter_distribute/comment/configs.dart';

class Dao {
  static String baseUrl = Configs.baseUrl;
  static String token = '';

  Response? response;
  Dio dio;

  // Single Mode
  factory Dao() => _getInstance();
  static Dao get instance => _getInstance();
  static Dao? _instance;

  Dao._internal() : dio = Dio() {
    // initialization
    dio.options.baseUrl = baseUrl;
    dio.options.headers = {'X-API-Token': token};
  }

  static Dao _getInstance() {
    _instance ??= Dao._internal();
    return _instance!;
  }

  Future<dynamic> get({required String url, Map? data}) async {
    try {
      Response response = await dio.get(
        url,
        queryParameters:
            data != null ? Map<String, dynamic>.from(data) : null,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } on DioError catch (e) {
      throw e.response != null ? e.response.data['message'] : e.message;
    }
  }

  Future<File> downloadAndroid(String url,Function(int, int) showDownloadProgress) async {
    Directory storageDir = (await getExternalStorageDirectory())!;
    String storagePath = storageDir.path;
    File file = File('$storagePath/download_app');

    if (!file.existsSync()) {
      file.createSync();
    }

    try {
      Response response = await dio.get(  
        url,
        onReceiveProgress: showDownloadProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        )
      );
      file.writeAsBytesSync(response.data);
      return file;
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }
}
