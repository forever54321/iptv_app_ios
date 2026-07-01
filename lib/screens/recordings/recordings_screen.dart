import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';

class RecordingsScreen extends ConsumerStatefulWidget {
  const RecordingsScreen({super.key});

  @override
  ConsumerState<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends ConsumerState<RecordingsScreen> {
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final allFiles = <FileSystemEntity>[];

    // Check recordings subfolder
    final recordingsDir = Directory('${dir.path}/recordings');
    if (recordingsDir.existsSync()) {
      allFiles.addAll(recordingsDir.listSync().where((f) => f is File));
    }

    // Also check documents root for any .ts files (mpv might save there)
    allFiles.addAll(dir.listSync().where((f) =>
        f is File &&
        (f.path.endsWith('.ts') || f.path.endsWith('.mp4') || f.path.endsWith('.mkv'))));

    // Also check current working directory
    final cwd = Directory.current;
    if (cwd.path != dir.path) {
      try {
        allFiles.addAll(cwd.listSync().where((f) =>
            f is File &&
            (f.path.endsWith('.ts') || f.path.endsWith('.mp4'))));
      } catch (_) {}
    }

    // Also check temp directory
    final tempDir = await getTemporaryDirectory();
    try {
      allFiles.addAll(tempDir.listSync().where((f) =>
          f is File &&
          (f.path.endsWith('.ts') || f.path.endsWith('.mp4'))));
    } catch (_) {}

    // Remove duplicates by path
    final seen = <String>{};
    final unique = allFiles.where((f) => seen.add(f.path)).toList();
    unique.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    setState(() {
      _files = unique;
      _loading = false;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int bytes) {
    // Rough estimate: ~1MB per second for standard streams
    final seconds = bytes ~/ (128 * 1024);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(S.recordings(lang)),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteAllDialog(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record_outlined, size: 80, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        'No recordings yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the record button while watching to start recording',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final stat = file.statSync();
                    final name = file.path.split('/').last;
                    return Dismissible(
                      key: Key(file.path),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        file.deleteSync();
                        _loadFiles();
                      },
                      child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade800,
                          child: const Icon(Icons.fiber_manual_record, color: Colors.white),
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${_formatSize(stat.size)} • ~${_formatDuration(stat.size)} • ${_formatDate(stat.modified)}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'play') _playFile(file);
                            if (action == 'delete') _deleteFile(file);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'play', child: Text('Play')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        onTap: () => _playFile(file),
                      ),
                    ),
                    );
                  },
                ),
    );
  }

  void _playFile(FileSystemEntity file) {
    context.go('/local-player', extra: file.path);
  }

  void _deleteFile(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete recording?'),
        content: Text('Delete ${file.path.split('/').last}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              file.deleteSync();
              Navigator.pop(context);
              _loadFiles();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all recordings?'),
        content: const Text('This will delete all recorded files.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              for (final f in _files) {
                f.deleteSync();
              }
              Navigator.pop(context);
              _loadFiles();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
