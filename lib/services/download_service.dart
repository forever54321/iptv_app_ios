import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/m3u_entry.dart';

class DownloadState {
  final bool isDownloading;
  final String? currentChannel;
  final double progress;
  final String? error;

  const DownloadState({
    this.isDownloading = false,
    this.currentChannel,
    this.progress = 0,
    this.error,
  });
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier() : super(const DownloadState());

  Future<void> download(M3uEntry channel) async {
    state = DownloadState(isDownloading: true, currentChannel: channel.title);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final name = channel.title.replaceAll(RegExp(r'[^\w\s-]'), '');
      final ext = channel.url.contains('.mp4') ? 'mp4' : 'ts';
      final file = File('${dir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}.$ext');

      final request = http.Request('GET', Uri.parse(channel.url));
      request.headers['User-Agent'] = 'VLC/3.0.20 LibVLC/3.0.20';
      final response = await request.send();

      if (response.statusCode != 200) {
        state = DownloadState(error: 'Failed: HTTP ${response.statusCode}');
        return;
      }

      final contentLength = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          state = DownloadState(
            isDownloading: true,
            currentChannel: channel.title,
            progress: received / contentLength,
          );
        }
      }

      await sink.close();
      state = const DownloadState();
    } catch (e) {
      state = DownloadState(error: e.toString());
    }
  }

  void cancel() {
    state = const DownloadState();
  }
}

final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>(
  (ref) => DownloadNotifier(),
);
