import 'dart:async';

import 'package:just_audio/just_audio.dart';

class LyricSynchronizer {
  final AudioPlayer player;
  final List<Map<String, dynamic>> lyrics;
  final _lyricController = StreamController<List<String>>.broadcast();
  StreamSubscription<Duration>? lyricSubscription;

  LyricSynchronizer(this.player, this.lyrics) {
    _synchronizeLyrics();
  }

  Stream<List<String>> get currentLyricStream => _lyricController.stream;

  void _synchronizeLyrics() {
    lyricSubscription = player.positionStream.listen((position) {
      final currentTime = position.inMilliseconds;
      int currentIndex = lyrics.indexWhere(
        (lyric) {
          final start = int.parse(lyric['cueRange']['startTimeMilliseconds']);
          final end = int.parse(lyric['cueRange']['endTimeMilliseconds']);
          return currentTime >= start && currentTime < end;
        },
      );

      if (currentIndex != -1) {
        String previousLyric =
            currentIndex > 0 ? lyrics[currentIndex - 1]['lyricLine'] : '';
        String currentLyric = lyrics[currentIndex]['lyricLine'];
        String nextLyric = currentIndex < lyrics.length - 1
            ? lyrics[currentIndex + 1]['lyricLine']
            : '';

        _lyricController.add([previousLyric, currentLyric, nextLyric]);
      } else {
        _lyricController.add(['', '', '']);
      }
    });
  }

  void dispose() {
    lyricSubscription?.cancel();
    _lyricController.close();
  }
}
