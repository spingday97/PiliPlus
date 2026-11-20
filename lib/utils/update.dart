import 'dart:io' show File, Platform;

import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

abstract final class Update {
  static const MethodChannel _channel = MethodChannel('piliplus/install');

  static Future<void> checkUpdate([bool isAuto = true]) async {
    if (kDebugMode) return;
    SmartDialog.dismiss();
    try {
      final res = await Request().get(
        Api.latestApp,
        options: Options(
          headers: {'user-agent': BrowserUa.mob},
          extra: {'account': const NoAccount()},
        ),
      );
      if (res.data is Map || res.data.isEmpty) {
        if (!isAuto) {
          SmartDialog.showToast('检查更新失败，GitHub接口未返回数据，请检查网络');
        }
        return;
      }
      final data = res.data[0];
      final int latest =
          DateTime.parse(data['created_at']).millisecondsSinceEpoch ~/ 1000;
      if (BuildConfig.buildTime >= latest) {
        if (!isAuto) {
          SmartDialog.showToast('已是最新版本');
        }
      } else {
        _showUpdateDialog(data, isAuto: isAuto);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('failed to check update: $e');
    }
  }

  static void _showUpdateDialog(Map data, {required bool isAuto}) {
    bool isDownloading = false;
    bool downloadDone = false;
    double progress = 0;
    int receivedBytes = 0;
    int totalBytes = 0;
    String? downloadedPath;
    CancelToken? cancelToken;

    SmartDialog.show(
      animationType: SmartAnimationType.centerFade_otherSlide,
      backType: SmartBackType.normal,
      builder: (context) {
        final colorScheme = ColorScheme.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> installDownloaded() async {
              if (downloadedPath == null) return;
              try {
                final res = await _channel.invokeMethod(
                  'installApk',
                  {'filePath': downloadedPath},
                );
                if (res == false) {
                  SmartDialog.showToast('请先允许安装未知应用权限，授权后再点「立即安装」');
                } else {
                  SmartDialog.dismiss();
                }
              } catch (e) {
                SmartDialog.showToast('拉起安装失败，请尝试浏览器下载');
              }
            }

            Future<void> startInAppDownload() async {
              final url = await _resolveDownloadUrl(data);
              if (url == null) {
                PageUtils.launchURL(
                  '${Constants.sourceCodeUrl}/releases/latest',
                );
                SmartDialog.dismiss();
                return;
              }
              final dir = await getTemporaryDirectory();
              final savePath = '${dir.path}/PiliPlus_update.apk';
              final file = File(savePath);
              if (file.existsSync()) {
                file.deleteSync();
              }
              cancelToken = CancelToken();
              setState(() {
                isDownloading = true;
                downloadDone = false;
                progress = 0;
                receivedBytes = 0;
                totalBytes = 0;
                downloadedPath = null;
              });
              try {
                await Dio(
                  BaseOptions(
                    followRedirects: true,
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(minutes: 10),
                  ),
                ).download(
                  url,
                  savePath,
                  cancelToken: cancelToken,
                  onReceiveProgress: (received, total) {
                    if (cancelToken?.isCancelled == true) return;
                    setState(() {
                      receivedBytes = received;
                      totalBytes = total;
                      progress = total > 0 ? received / total : 0;
                    });
                  },
                );
                setState(() {
                  isDownloading = false;
                  downloadDone = true;
                  progress = 1;
                  downloadedPath = savePath;
                });
                await installDownloaded();
              } on DioException catch (e) {
                if (CancelToken.isCancel(e)) {
                  setState(() {
                    isDownloading = false;
                    progress = 0;
                  });
                } else {
                  setState(() => isDownloading = false);
                  SmartDialog.showToast('下载失败，可改用浏览器下载');
                }
              } catch (_) {
                setState(() => isDownloading = false);
                SmartDialog.showToast('下载失败，可改用浏览器下载');
              }
            }

            String formatMb(int bytes) =>
                (bytes / (1024 * 1024)).toStringAsFixed(1);

            Widget downloadBtn(String text, {String? ext}) => TextButton(
              onPressed: () => onDownload(data, ext: ext),
              child: Text(text),
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '发现新版本 ${data['tag_name'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '更新内容：',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data['body'] ?? ''}',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      TextButton(
                        onPressed: () => PageUtils.launchURL(
                          '${Constants.sourceCodeUrl}/commits/main',
                        ),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(
                          '查看完整更新记录',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                      if (isDownloading || downloadDone) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      downloadDone
                                          ? '安装包已就绪'
                                          : '正在下载安装包... ${(progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (totalBytes > 0)
                                    Text(
                                      '${formatMb(receivedBytes)} / ${formatMb(totalBytes)} MB',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: downloadDone
                                      ? 1
                                      : (totalBytes > 0 ? progress : null),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (isAuto && !isDownloading)
                  TextButton(
                    onPressed: () {
                      SmartDialog.dismiss();
                      GStorage.setting.put(SettingBoxKey.autoUpdate, false);
                    },
                    child: Text(
                      '不再提醒',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    cancelToken?.cancel();
                    SmartDialog.dismiss();
                  },
                  child: Text(
                    '取消',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ),
                if (Platform.isAndroid) ...[
                  TextButton(
                    onPressed: () => onDownload(data),
                    child: const Text('浏览器下载'),
                  ),
                  if (!isDownloading)
                    FilledButton(
                      onPressed:
                          downloadDone ? installDownloaded : startInAppDownload,
                      child: Text(downloadDone ? '立即安装' : '立即更新'),
                    ),
                ] else if (Platform.isWindows) ...[
                  downloadBtn('zip', ext: 'zip'),
                  downloadBtn('exe', ext: 'exe'),
                ] else if (Platform.isLinux) ...[
                  downloadBtn('rpm', ext: 'rpm'),
                  downloadBtn('deb', ext: 'deb'),
                  downloadBtn('targz', ext: 'tar.gz'),
                ] else
                  downloadBtn('Github'),
              ],
            );
          },
        );
      },
    );
  }

  static Future<String?> _resolveDownloadUrl(
    Map data, {
    String? ext,
  }) async {
    final assets = data['assets'];
    if (assets is! List || assets.isEmpty) return null;
    final String plat = Platform.isAndroid
        ? (await DeviceInfoPlugin().androidInfo).supportedAbis.first
        : Platform.operatingSystem;
    for (final item in assets) {
      if (item is Map) {
        final String name = item['name']?.toString() ?? '';
        if (name.contains(plat) &&
            (ext == null || ext.isEmpty || name.endsWith(ext))) {
          return item['browser_download_url']?.toString();
        }
      }
    }
    return null;
  }

  static Future<void> onDownload(Map data, {String? ext}) async {
    SmartDialog.dismiss();
    try {
      final url = await _resolveDownloadUrl(data, ext: ext);
      if (url != null) {
        PageUtils.launchURL(url);
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('download error: $e');
    }
    PageUtils.launchURL('${Constants.sourceCodeUrl}/releases/latest');
  }
}
