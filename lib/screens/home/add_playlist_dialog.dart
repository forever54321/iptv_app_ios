import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playlist_source.dart';
import '../../providers/playlist_source_provider.dart';
import '../../services/playlist_fetch_service.dart';

class AddPlaylistDialog extends ConsumerStatefulWidget {
  const AddPlaylistDialog({super.key});

  @override
  ConsumerState<AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends ConsumerState<AddPlaylistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  PlaylistType _type = PlaylistType.direct;
  bool _testing = false;
  String? _testResult;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Playlist'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                SegmentedButton<PlaylistType>(
                  segments: const [
                    ButtonSegment(
                      value: PlaylistType.direct,
                      label: Text('Direct URL'),
                      icon: Icon(Icons.link),
                    ),
                    ButtonSegment(
                      value: PlaylistType.xtreamCodes,
                      label: Text('Xtream Codes'),
                      icon: Icon(Icons.dns),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: _type == PlaylistType.direct
                        ? 'M3U URL'
                        : 'Server URL',
                    hintText: _type == PlaylistType.direct
                        ? 'https://example.com/playlist.m3u'
                        : 'http://server:port',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!Uri.tryParse(v)!.hasScheme) return 'Invalid URL';
                    return null;
                  },
                ),
                if (_type == PlaylistType.xtreamCodes) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) =>
                        _type == PlaylistType.xtreamCodes && (v == null || v.isEmpty)
                            ? 'Required'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        _type == PlaylistType.xtreamCodes && (v == null || v.isEmpty)
                            ? 'Required'
                            : null,
                  ),
                ],
                const SizedBox(height: 16),
                if (_testResult != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testResult!.startsWith('Success')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(_testing ? 'Testing...' : 'Test Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    final source = _buildSource();
    final ok = await PlaylistFetchService.testConnection(source.effectiveUrl);

    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = ok ? 'Success! Connection works.' : 'Failed to connect.';
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final source = _buildSource();
    ref.read(playlistSourcesProvider.notifier).add(source);
    Navigator.pop(context);
  }

  PlaylistSource _buildSource() {
    return PlaylistSource(
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      username: _type == PlaylistType.xtreamCodes
          ? _usernameController.text.trim()
          : null,
      password: _type == PlaylistType.xtreamCodes
          ? _passwordController.text.trim()
          : null,
      type: _type,
    );
  }
}
