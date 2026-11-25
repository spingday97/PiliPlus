import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/utils/audio_extract_storage.dart';
import 'package:PiliPlus/utils/neu_style.dart';
import 'package:PiliPlus/utils/storage_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:media_kit/media_kit.dart';

class DownloadedAudioTab extends StatefulWidget {
  const DownloadedAudioTab({super.key});

  @override
  State<DownloadedAudioTab> createState() => _DownloadedAudioTabState();
}

class _DownloadedAudioTabState extends State<DownloadedAudioTab>
    with AutomaticKeepAliveClientMixin {
  Player? _player;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _completedSub;

  List<ExtractedAudioItem> _items = const [];
  bool _loading = true;
  String? _playingPath;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    AudioExtractStorage.version.addListener(_load);
     _load();
  }

  @override
  void dispose() {
    AudioExtractStorage.version.removeListener(_load);
    _playingSub?.cancel();
   _posSub?.cancel();
   _durSub?.cancel();
    _completedSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
  Future<Player> _ensurePlayer() async {
    if (_player != null) return _player!;
    final p = await Player.create();
    _playingSub = p.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
      });
   _posSub = p.stream.position.listen((pos) { if (mounted) setState(() => _position = pos); });
   _durSub = p.stream.duration.listen((dur) { if (mounted) setState(() => _duration = dur); });
    _completedSub = p.stream.completed.listen((done) {
      if (done && mounted) setState(() => _isPlaying = false);
      });
    _player = p;
    return p;
  }
  
  Future<void> _load() async {
    final list = await AudioExtractStorage.listAll();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _togglePlay(ExtractedAudioItem item) async {
    final player = await _ensurePlayer();
    if (_playingPath == item.filePath) {
      await player.playOrPause();
    } else {
      setState(() => _playingPath = item.filePath);
      await player.open(Media(item.filePath));
    }
  }

  Future<void> _exportItem(ExtractedAudioItem item) async {
    try {
      final bytes = await File(item.filePath).readAsBytes();
      await StorageUtils.saveBytes2File(name: item.fileName, bytes: bytes);
    } catch (e) {
      SmartDialog.showToast('导出失败: $e');
    }
  }

  Future<void> _deleteItem(ExtractedAudioItem item) async {
    if (_playingPath == item.filePath) {
      await _player?.stop();
      _playingPath = null;
    }
    await AudioExtractStorage.deleteItem(item);
    SmartDialog.showToast('已删除');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '暂无已提取的独立音频\n可在视频播放页右上角「更多 -> 提取独立音频」中保存',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(children: [Expanded(child: RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          final isCurrent = _playingPath == item.filePath;
          final isThisPlaying = isCurrent && _isPlaying;

          final meta = <String>[
            if (item.codecs?.isNotEmpty == true) item.codecs!,
            if (item.bandWidth != null && item.bandWidth! > 0)
              '${(item.bandWidth! / 1000).round()} kbps',
            if (item.fileSize > 0) _formatSize(item.fileSize),
          ];

          return Material(
            color: isCurrent
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _togglePlay(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _togglePlay(item),
                      icon: Icon(
                        isThisPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (item.quality.isNotEmpty)
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
                                    item.quality,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (meta.isNotEmpty)
                                Text(
                                  meta.join(' · '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                    fontSize: 11.5,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (item.url?.isNotEmpty == true)
                      IconButton(
                        tooltip: '复制流地址',
                        onPressed: () => Utils.copyText(item.url!),
                        icon: const Icon(Icons.link_rounded, size: 20),
                      ),
                    IconButton(
                      tooltip: '导出到手机',
                      onPressed: () => _exportItem(item),
                      icon: const Icon(Icons.save_alt_rounded, size: 20),
                    ),
                    IconButton(
                      tooltip: '删除',
                      onPressed: () => _deleteItem(item),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    )), if (_playingPath != null) Builder(builder: (context) { final currentItem = _items.where((e) => e.filePath == _playingPath).firstOrNull; final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0; final posMs = _position.inMilliseconds.toDouble().clamp(0.0, maxMs); return Container(margin: const EdgeInsets.fromLTRB(12, 4, 12, 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: NeuStyle.enabled ? NeuStyle.raised(isDark: theme.brightness == Brightness.dark) : BoxDecoration(color: colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [IconButton(onPressed: () { if (currentItem != null) { _togglePlay(currentItem); } else { _player?.playOrPause(); } }, icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)), Expanded(child: Text(currentItem?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))), Text('${_formatDur(_position)} / ${_formatDur(_duration)}', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline))]), Slider(value: posMs, max: maxMs, onChanged: (v) => _player?.seek(Duration(milliseconds: v.round())))])); }), ]);
  }
  String _formatDur(Duration d) { final m = d.inMinutes.toString().padLeft(2, '0'); final s = d.inSeconds.remainder(60).toString().padLeft(2, '0'); return '$m:$s'; }
}
