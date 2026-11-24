import 'dart:typed_data' show Uint8List;

import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/base_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/pgc/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/utils/audio_extract_storage.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class AudioExtractSheet extends StatefulWidget {
  const AudioExtractSheet({
    super.key,
    required this.videoDetailCtr,
  });

  final VideoDetailController videoDetailCtr;

 static void show(BuildContext context, VideoDetailController videoDetailCtr) {
   try {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      builder: (_) => AudioExtractSheet(videoDetailCtr: videoDetailCtr),
    );
     } catch (e) { SmartDialog.showToast('打开失败: $e'); }
  }

  @override
  State<AudioExtractSheet> createState() => _AudioExtractSheetState();
}

class _AudioExtractSheetState extends State<AudioExtractSheet> {
  late List<AudioItem> _audioList;
  int? _durationSec;
  bool _refreshing = false;
  int? _downloadingIndex;
  double? _downloadProgress;
  String _downloadStatus = '';
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _loadFromController();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('sheet_disposed');
    super.dispose();
  }

  void _loadFromController() {
    try {
      final dash = widget.videoDetailCtr.data.dash;
      _durationSec = dash?.duration;
      _audioList = _sortAudio(dash?.audio ?? const []);
    } catch (_) {
      _audioList = const [];
    }
    if (_audioList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStreams());
    }
  }

  List<AudioItem> _sortAudio(List<AudioItem> list) {
    final sorted = List<AudioItem>.from(list);
    sorted.sort(
      (a, b) => AudioQuality.fromCode(b.id)
          .rank
          .compareTo(AudioQuality.fromCode(a.id).rank),
    );
    return sorted;
  }

  String _resolveTitle() {
    try {
      final ctr = widget.videoDetailCtr;
      if (ctr.isUgc) {
        final t = Get.find<UgcIntroController>(tag: ctr.heroTag)
            .videoDetail
            .value
            .title;
        if (t != null && t.isNotEmpty) return t;
      } else {
        final t = Get.find<PgcIntroController>(tag: ctr.heroTag)
            .videoDetail
            .value
            .title;
        if (t != null && t.isNotEmpty) return t;
      }
    } catch (_) {}
    final bvid = widget.videoDetailCtr.bvid;
    return bvid.isNotEmpty ? bvid : 'bilibili_audio';
  }

  Future<void> _refreshStreams() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final ctr = widget.videoDetailCtr;
      final res = await VideoHttp.videoUrl(
        avid: ctr.aid,
        bvid: ctr.bvid,
        cid: ctr.cid.value,
        qn: 80,
        tryLook: false,
        videoType: ctr.videoType,
        voiceBalance: true,
      );
      if (!mounted) return;
      if (res is Success<PlayUrlModel>) {
        final dash = res.response.dash;
        setState(() {
          _durationSec = dash?.duration ?? _durationSec;
          _audioList = _sortAudio(dash?.audio ?? const []);
        });
        SmartDialog.showToast('已刷新音轨列表');
      } else {
        SmartDialog.showToast('刷新音轨失败');
      }
    } catch (e) {
      if (mounted) SmartDialog.showToast('刷新失败: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _extFor(AudioItem item) {
    final mime = item.mimeType?.toLowerCase() ?? '';
    if (mime.contains('flac')) return 'flac';
    if (mime.contains('mpeg') || mime.contains('mp3')) return 'mp3';
    return 'm4a';
  }

  Future<void> _downloadAudio(int index, AudioItem item) async {
    if (_downloadingIndex != null) {
      SmartDialog.showToast('当前有音轨正在下载');
      return;
    }
    final urls = item.playUrls.toList();
    if (urls.isEmpty) {
      SmartDialog.showToast('未找到可用音频流地址');
      return;
    }

    final qualityDesc = AudioQuality.fromCode(item.id).desc;
    final rawTitle = _resolveTitle();
    final safeTitle = rawTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|\r\n]'), '_')
        .trim();
    final shortTitle =
        safeTitle.length > 50 ? safeTitle.substring(0, 50) : safeTitle;
    final fileName = '${shortTitle}_$qualityDesc.${_extFor(item)}';

    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    setState(() {
      _downloadingIndex = index;
      _downloadProgress = null;
      _downloadStatus = '正在连接...';
    });

    List<int>? downloadedBytes;
    Object? lastError;

    for (final rawUrl in urls) {
      if (cancelToken.isCancelled) break;
      final url = rawUrl.startsWith('http://')
          ? rawUrl.replaceFirst('http://', 'https://')
          : rawUrl;
      try {
        final res = await Request.http11Dio.get<List<int>>(
          url,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'referer': HttpString.baseUrl},
          ),
          onReceiveProgress: (received, total) {
            if (!mounted) return;
            setState(() {
              if (total > 0) {
                _downloadProgress = (received / total).clamp(0.0, 1.0);
                _downloadStatus =
                    '${(_downloadProgress! * 100).toStringAsFixed(0)}% · ${_formatSize(received)} / ${_formatSize(total)}';
              } else {
                _downloadProgress = null;
                _downloadStatus = '已下载 ${_formatSize(received)}';
              }
            });
          },
        );
        if (res.data != null && res.data!.isNotEmpty) {
          downloadedBytes = res.data;
          break;
        }
      } catch (e) {
        if (CancelToken.isCancel(e as DioException? ?? DioException(requestOptions: RequestOptions()))) {
          lastError = e;
          break;
        }
        lastError = e;
      }
    }

    if (!mounted) return;

    setState(() {
      _downloadingIndex = null;
      _downloadProgress = null;
      _downloadStatus = '';
      _cancelToken = null;
    });

    if (cancelToken.isCancelled) {
      SmartDialog.showToast('已取消下载');
      return;
    }

    if (downloadedBytes == null) {
      SmartDialog.showToast('下载失败: $lastError');
      return;
    }

    await AudioExtractStorage.saveAudio(
      fileName: fileName,
      bytes: Uint8List.fromList(downloadedBytes),
      title: rawTitle,
      quality: qualityDesc,
      codecs: item.codecs,
      bandWidth: item.bandWidth,
      url: urls.first,
    );
    SmartDialog.showToast('已保存到「我的下载 -> 音频」');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.audiotrack_rounded, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '独立音频流嗅探',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '按音质从高到低排列，可直接保存纯音频或复制直链',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '刷新音轨',
                onPressed: _refreshing ? null : _refreshStreams,
                icon: _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_audioList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '当前视频未检测到独立 DASH 音频流',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _audioList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _audioList[index];
                  final qa = AudioQuality.fromCode(item.id);
                  final isHighest = index == 0;
                  final isDownloading = _downloadingIndex == index;
                  final kbps = item.bandWidth != null && item.bandWidth! > 0
                      ? '${(item.bandWidth! / 1000).round()} kbps'
                      : '';
                  final estBytes = (_durationSec != null &&
                          _durationSec! > 0 &&
                          item.bandWidth != null &&
                          item.bandWidth! > 0)
                      ? (_durationSec! * item.bandWidth! / 8).round()
                      : null;
                  final estSize = estBytes != null ? '约 ${_formatSize(estBytes)}' : '';
                  final firstUrl = item.playUrls.isNotEmpty ? item.playUrls.first : '';
                  final host = Uri.tryParse(firstUrl)?.host ?? '';

                  final metaParts = <String>[
                    if (item.codecs?.isNotEmpty == true) item.codecs!,
                    if (kbps.isNotEmpty) kbps,
                    if (estSize.isNotEmpty) estSize,
                    if (host.isNotEmpty) host,
                  ];

                  return Container(
                    decoration: BoxDecoration(
                      color: isHighest
                          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isHighest
                            ? colorScheme.primary.withValues(alpha: 0.45)
                            : colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        qa.desc,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isHighest) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '最高',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onPrimary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (metaParts.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      metaParts.join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.outline,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: '复制音频流地址',
                              onPressed: firstUrl.isEmpty
                                  ? null
                                  : () => Utils.copyText(firstUrl),
                              icon: const Icon(Icons.link_rounded, size: 20),
                            ),
                            if (isDownloading)
                              IconButton(
                                tooltip: '取消下载',
                                onPressed: () => _cancelToken?.cancel('user_cancel'),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              )
                            else
                              FilledButton.tonalIcon(
                                onPressed: _downloadingIndex != null
                                    ? null
                                    : () => _downloadAudio(index, item),
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('保存'),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                              ),
                          ],
                        ),
                        if (isDownloading) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: _downloadProgress),
                          const SizedBox(height: 4),
                          Text(
                            _downloadStatus,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
