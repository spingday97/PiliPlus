import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/services/audio_handler.dart';
import 'package:PiliPlus/services/audio_session.dart';
import 'package:flutter/services.dart';

VideoPlayerServiceHandler? videoPlayerServiceHandler;
AudioSessionHandler? audioSessionHandler;

Future<void> setupServiceLocator() async {
  final audio = await initAudioService();
  videoPlayerServiceHandler = audio;
  audioSessionHandler = AudioSessionHandler();
  const MethodChannel('piliplus/lifecycle').setMethodCallHandler((call) async {
    if (call.method == 'onDestroy') {
      await videoPlayerServiceHandler?.stop();
      await PlPlayerController.pauseIfExists();
      await audioSessionHandler?.setActive(false);
    }
  });
}
