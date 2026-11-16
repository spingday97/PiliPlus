part of 'package:PiliPlus/pages/live_room/controller.dart';

mixin _LiveDMStreamMixin
    on
        GetxController,
        _LiveDMTrimMixin,
        _LiveSCMixin,
        _LiveDMMixin,
        _LiveBlockMixin {
  LiveMessageStream? _msgStream;
  LiveMessageStream? get msgStream => _msgStream;

  static final Map<String, dynamic> _emoteImgCache = <String, dynamic>{};
  static final Map<String, Future<dynamic>> _emotePending =
      <String, Future<dynamic>>{};

  Future<dynamic> _loadEmoteImage(String url) {
    if (_emoteImgCache.containsKey(url)) {
      return Future.value(_emoteImgCache[url]);
    }
    return _emotePending[url] ??= () async {
      var done = false;
      dynamic loadedImg;
      final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          stream.removeListener(listener);
          if (_emoteImgCache.length >= 200) {
            _emoteImgCache.remove(_emoteImgCache.keys.first);
          }
          _emoteImgCache[url] = info.image;
          loadedImg = info.image;
          done = true;
        },
        onError: (_, _) {
          stream.removeListener(listener);
          done = true;
        },
      );
      stream.addListener(listener);
      try {
        var elapsed = 0;
        while (!done && elapsed < 500) {
          await Future.delayed(const Duration(milliseconds: 25));
          elapsed += 25;
        }
        return loadedImg;
      } finally {
        _emotePending.remove(url);
      }
    }();
  }

  late final headerKey = GlobalKey<TimeBatteryMixin>();
  late final RxString title = ''.obs;
  late final RxnString onlineCount = RxnString();
  late final RxnString watchedShow = RxnString();
  Widget get watchedWidget => Obx(() {
    if (watchedShow.value case final watchedShow?) {
      return Text(
        watchedShow,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      );
    }
    return const SizedBox.shrink();
  });

  void startLiveMsgStream() {
    if (messages.isEmpty) {
      prefetchDM();
      if (showSuperChat) getSuperChatMsg();
    }
    if (_msgStream != null) {
      return;
    }
    if (dmInfo != null) {
      initDm(dmInfo!);
      return;
    }
    LiveHttp.liveRoomGetDanmakuToken(roomId: roomId).then((res) {
      if (res case Success(:final response)) {
        initDm(dmInfo = response);
      }
    });
  }

  Future<void> initDm(LiveDmInfoData info) async {
    if (info.hostList.isEmpty) return;
    _msgStream =
        LiveMessageStream(
            streamToken: info.token,
            roomId: roomId,
            uid: Accounts.heartbeat.mid,
            servers: info.hostList
                .map((host) => 'wss://${host.host}:${host.wssPort}/sub')
                .toList(),
          )
          ..addEventListener(_danmakuListener)
          ..init();
  }

  void addDm(dynamic msg, [DanmakuContentItem<DanmakuExtra>? item]) {
    _trimDm();

    if (plPlayerController.showDanmaku) {
      if (item != null && plPlayerController.enableShowLiveDanmaku.value) {
        danmakuController?.addDanmaku(item);
      }
      if (autoScroll && !disableAutoScroll.value) {
        messages.add(msg);
        scrollToBottom();
        return;
      }
    }

    messages.addOnly(msg);
  }

  @pragma('vm:notify-debugger-on-exception')
  Future<void> _danmakuListener(dynamic obj) async {
    try {
      // logger.i(' 原始弹幕消息 ======> ${jsonEncode(obj)}');
      switch (obj['cmd']) {
        case 'DANMU_MSG':
          final info = obj['info'];
          final first = info[0];
          final content = first[15];
          final user = content['user'];
          // final midHash = first[7];
          final uid = user['uid'] as int;
          final msg = info[1];
          if (isBlocked(msg, uid)) {
            return;
          }
          final Map<String, dynamic> extra = jsonDecode(content['extra']);
          final name = user['base']['name'];
          BaseEmote? uemote;
          if (first[13] case Map<String, dynamic> map) {
            uemote = BaseEmote.fromJson(map);
          }
          final emots = (extra['emotes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, BaseEmote.fromJson(v)),
          );
          final checkInfo = info[9];
          final liveExtra = LiveDanmaku(
            id: extra['id_str'],
            mid: uid,
            dmType: extra['dm_type'],
            ts: checkInfo['ts'],
            ct: checkInfo['ct'],
          );
          Owner? reply;
          final replyMid = extra['reply_mid'];
          if (replyMid != null && replyMid != 0) {
            reply = Owner(
              mid: replyMid,
              name: extra['reply_uname'],
            );
          }

          dynamic danmakuEmoteImg;
          Map<String, dynamic>? danmakuEmotes;
          if (plPlayerController.showDanmaku &&
              plPlayerController.enableShowLiveDanmaku.value) {
            if (uemote != null && uemote.url.isNotEmpty) {
              danmakuEmoteImg =
                  _emoteImgCache[uemote.url] ??
                  await _loadEmoteImage(uemote.url);
            } else if (emots != null && emots.isNotEmpty) {
              final entries = await Future.wait(
                emots.entries.map((e) async {
                  final img = e.value.url.isNotEmpty
                      ? (_emoteImgCache[e.value.url] ??
                            await _loadEmoteImage(e.value.url))
                      : null;
                  return MapEntry(e.key, img);
                }),
              );
              final resolved = {
                for (final e in entries)
                  if (e.value != null) e.key: e.value,
              };
              if (resolved.isNotEmpty) {
                danmakuEmotes = resolved;
              }
            }
          }

          addDm(
            DanmakuMsg(
              name: name,
              text: msg,
              emots: emots,
              uemote: uemote,
              extra: liveExtra,
              reply: reply,
              medalInfo: GlobalData().showMedal
                  ? UinfoMedal.lightMedal(user['medal'])
                  : null,
            ),
            DanmakuContentItem(
              msg,
              color: DanmakuOptions.blockColorful
                  ? Colors.white
                  : DmUtils.decimalToColor(extra['color']),
              type: DmUtils.getPosition(extra['mode']),
              // extra['send_from_me'] is invalid
              selfSend: isMainLogin && uid == mid,
              extra: liveExtra,
              emoteImage: danmakuEmoteImg,
              emotes: danmakuEmotes?.cast(),
            ),
          );
          break;
        case 'SUPER_CHAT_MESSAGE' when showSuperChat:
          final item = SuperChatItem.fromJson(obj['data'], roomId);
          superChatMsg.insert(0, item);
          addDm(item);
          if (!enableFSSC) return;
          if (Platform.isAndroid && AndroidHelper.isPipMode) return;
          if (plPlayerController.showDanmaku &&
              (isFullScreen || plPlayerController.isDesktopPip)) {
            fsSC.value = item.copyWith(
              endTime: math.min(
                item.endTime,
                DateTime.now().millisecondsSinceEpoch ~/ 1000 + 10,
              ),
            );
          }
          break;
        case 'WATCHED_CHANGE':
          watchedShow.value = obj['data']['text_large'];
          break;
        case 'ONLINE_RANK_COUNT':
          onlineCount.value = NumUtils.numFormat(obj['data']['count']);
          break;
        case 'ROOM_CHANGE':
          title.value = obj['data']['title'];
          break;
        case 'MESSAGEBOX_USER_MEDAL_CHANGE':
          if (kDebugMode) {
            debugPrint(Utils.jsonEncoder.convert(obj));
          }
          if (isMainLogin) {
            final json = obj['data']['uinfo_medal'];
            final updateRuid = json['ruid'];
            final medalRuid = medal.rawValue?.ruid;
            if (medalRuid == updateRuid ||
                (medalRuid == null && updateRuid == ruid)) {
              medal.value = .fromJson(json);
            }
          }
          break;
      }
    } catch (e, s) {
      if (kDebugMode) {
        Utils.reportError(e, s);
      }
    }
  }

  void stopLiveMsgStream() {
    _msgStream?.close();
    _msgStream = null;
  }
}