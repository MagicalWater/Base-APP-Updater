import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdater {
  /// 下載狀態串流(當狀態變更 / 下載進度更新時呼叫)
  static Stream<DownloadData> get downloadStream => _downloadSubject.stream;

  /// 當前是否下載中
  static bool get isDownloading => _isDownloading;

  /// 當前下載 url
  static String get currentDownloadUrl => _currentDownloadUrl;

  /// 當前的下載進度
  static int get currentProgress {
    if (_downloadSubject.hasValue) {
      return _downloadSubject.value.progress;
    }
    return 0;
  }

  /// 與本地溝通 channel 識別名稱
  static const _channelName = 'app_updater';

  /// 與本地溝通類, 因為有 Stream, 使用 EventChannel
  static const _eventChannel = const EventChannel(_channelName);

  /// 下載事件訂閱監聽
  static StreamSubscription _downloadSubscription;

  /// 當前是否正在下載中
  static bool _isDownloading = false;

  /// 當前正在下載的 url 回調
  static String _currentDownloadUrl;

  /// 進度subject
  static BehaviorSubject<DownloadData> _downloadSubject = BehaviorSubject();

  /// 進行更新
  /// ios => 強制使用開啟 web
  /// android => 依據 [openWeb] 來決定是用下載還是開啟web
  /// 其餘系統 => 嘗試使用開啟 web
  static Future<void> update(String url, {bool openWeb = true}) async {
    print("開始更新: $url, 是否為開啟 web: $openWeb");
    // 若 url 無效則拋出錯誤
    if (!(await _isUrlEffect(url))) {
      throw UpdateError.urlFail;
    }

    if (Platform.isIOS) {
      if (!openWeb) {
        print("ios 尚不支持下載ipa更新的方式, 自動更改為開啟 web");
      }
      await launch(url);
    } else if (Platform.isAndroid) {
      if (openWeb) {
        await launch(url);
      } else {
        await _downloadAndroidApk(url);
      }
    } else {
      print("未知系統, 無法進行更新: ${Platform.operatingSystem}, 嘗試開啟 url web");
      await launch(url);
    }
  }

  /// android 下載
  static Future<void> _downloadAndroidApk(String url) async {
    // 檢查是否有外部 storage 的權限
    print("android 檢查權限");
    var permissionStatus =
        await Permission.storage.status;
    print("storage權限狀態: $permissionStatus");

    if (permissionStatus == PermissionStatus.granted) {
      print("擁有讀寫外部儲存空間的權限, 開始下載");
      _currentDownloadUrl = url;
      var receiveStream = _eventChannel.receiveBroadcastStream(url);
      _downloadSubscription?.cancel();
      _downloadSubscription = receiveStream
          .listen((event) => _parseDownloadEvent(event), onDone: () {
        print("下載串流結束");
      }, onError: (error) {
        print("下載串流錯誤: $error");
        _isDownloading = false;
        _currentDownloadUrl = null;
        var updateError = UpdateError.downloadFail;
        updateError.message = error.toString();
        var data = DownloadData(
          status: DownloadStatus.downloading,
          progress: currentProgress,
          error: updateError,
        );
        _downloadSubject.add(data);
      });
    } else {
      // 沒有權限, 需要打開儲存權限
      throw UpdateError.needExStoragePermission;
    }
  }

  /// 解析下載的回傳事件, 並且放到 subject 打出去
  static void _parseDownloadEvent(dynamic event) {
    if (event is Map) {
      switch (event[EventTag.event]) {
        case Event.start:
          print("下載開始");
          _isDownloading = true;
          var data = DownloadData(
            status: DownloadStatus.downloading,
            progress: 0,
          );
          _downloadSubject.add(data);
          break;
        case Event.cancel:
          print("下載取消");
          _isDownloading = false;
          _currentDownloadUrl = null;
          var data = DownloadData(
            status: DownloadStatus.cancel,
            progress: currentProgress,
          );
          _downloadSubject.add(data);
          break;
        case Event.progress:
          var data = DownloadData.progress(
            event[EventTag.value],
          );
          _downloadSubject.add(data);
          break;
        case Event.error:
          print("下載失敗");
          _isDownloading = false;
          _currentDownloadUrl = null;
          var updateError = UpdateError.downloadFail;
          updateError.message = event[EventTag.value];
          var data = DownloadData(
              status: DownloadStatus.error,
              progress: currentProgress,
              error: updateError);
          _downloadSubject.add(data);
          break;
        case Event.finish:
          print("下載完成");
          _isDownloading = false;
          _currentDownloadUrl = null;
          var data = DownloadData(
            status: DownloadStatus.complete,
            progress: 100,
          );
          _downloadSubject.add(data);
          break;
      }
    }
  }

  /// 檢查 url 是否有效
  static Future<bool> _isUrlEffect(String url) async {
    return await canLaunch(url);
  }

  static void dispose() {
    _downloadSubject?.close();
    _downloadSubscription?.cancel();
  }
}

/// 下載狀態與進度
class DownloadData {
  /// 下載狀態
  DownloadStatus status;

  // 下載進度, 0 ~ 100
  int progress;

  /// 下載錯誤時的 Error 訊息
  UpdateError error;

  DownloadData({
    this.status,
    this.progress = 0,
    this.error,
  });

  DownloadData.progress(this.progress) {
    this.status = DownloadStatus.downloading;
    this.progress = progress;
  }
}

class UpdateError extends Error implements Exception {
  final UpdateErrorType type;
  String message;

  UpdateError._(this.type, [this.message]);

  static UpdateError urlFail = UpdateError._(UpdateErrorType.urlFail);
  static UpdateError needExStoragePermission =
      UpdateError._(UpdateErrorType.needExStoragePermission);
  static UpdateError downloadFail = UpdateError._(UpdateErrorType.downloadFail);

  @override
  String toString() {
    return "下載錯誤[$type] - $message";
  }
}

enum DownloadStatus {
  /// 下載已取消
  cancel,

  /// 下載錯誤
  error,

  /// 下載中
  downloading,

  /// 下載結束
  complete,

  /// 尚未開始下載
  none,
}

enum UpdateErrorType {
  /// url 無效
  urlFail,

  /// 沒有外部儲存權限
  needExStoragePermission,

  /// 下載失敗
  downloadFail,
}

class EventTag {
  static var event = "event";
  static var value = "value";
}

class Event {
  static const progress = "process";
  static const finish = "finish";
  static const cancel = "cancel";
  static const error = "error";
  static const start = "start";
}
