import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:PiliPlus/utils/path_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ExtractedAudioItem {
  ExtractedAudioItem({
    required this.fileName,
    required this.filePath,
    required this.title,
    required this.quality,
    required this.fileSize,
    required this.createdAt,
    this.codecs,
    this.bandWidth,
    this.url,
  });

  final String fileName;
  final String filePath;
  final String title;
  final String quality;
  final int fileSize;
  final int createdAt;
  final String? codecs;
  final int? bandWidth;
  final String? url;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'title': title,
        'quality': quality,
        'fileSize': fileSize,
        'createdAt': createdAt,
        if (codecs != null) 'codecs': codecs,
        if (bandWidth != null) 'bandWidth': bandWidth,
        if (url != null) 'url': url,
      };

  factory ExtractedAudioItem.fromJson(
    Map<String, dynamic> json,
    String filePath,
  ) {
    return ExtractedAudioItem(
      fileName: json['fileName'] as String? ?? path.basename(filePath),
      filePath: filePath,
      title: json['title'] as String? ?? path.basenameWithoutExtension(filePath),
      quality: json['quality'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      codecs: json['codecs'] as String?,
      bandWidth: (json['bandWidth'] as num?)?.toInt(),
      url: json['url'] as String?,
    );
  }
}

abstract final class AudioExtractStorage {
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static Future<Directory> _getDir() async {
    final dir = Directory(path.join(downloadPath, 'audio_extract'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<ExtractedAudioItem> saveAudio({
    required String fileName,
    required Uint8List bytes,
    required String title,
    required String quality,
    String? codecs,
    int? bandWidth,
    String? url,
  }) async {
    final dir = await _getDir();
    final audioPath = path.join(dir.path, fileName);
    final audioFile = File(audioPath);
    await audioFile.writeAsBytes(bytes, flush: true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final item = ExtractedAudioItem(
      fileName: fileName,
      filePath: audioPath,
      title: title,
      quality: quality,
      fileSize: bytes.length,
      createdAt: now,
      codecs: codecs,
      bandWidth: bandWidth,
      url: url,
    );

    final metaFile = File('$audioPath.meta.json');
    await metaFile.writeAsString(jsonEncode(item.toJson()), flush: true);
    version.value++;
    return item;
  }

  static Future<List<ExtractedAudioItem>> listAll() async {
    final dir = await _getDir();
    if (!dir.existsSync()) return const [];
    final items = <ExtractedAudioItem>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.meta.json')) {
        try {
          final audioPath = entity.path.substring(
            0,
            entity.path.length - '.meta.json'.length,
          );
          final audioFile = File(audioPath);
          if (!audioFile.existsSync()) continue;
          final map = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          items.add(ExtractedAudioItem.fromJson(map, audioPath));
        } catch (_) {}
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<void> deleteItem(ExtractedAudioItem item) async {
    try {
      final audioFile = File(item.filePath);
      if (audioFile.existsSync()) {
        await audioFile.delete();
      }
      final metaFile = File('${item.filePath}.meta.json');
      if (metaFile.existsSync()) {
        await metaFile.delete();
      }
    } finally {
      version.value++;
    }
  }
}
