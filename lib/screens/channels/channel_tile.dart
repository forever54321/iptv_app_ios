import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/m3u_entry.dart';

class ChannelTile extends StatelessWidget {
  final M3uEntry channel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDownload;
  final bool isFavorite;
  final bool isVOD;
  final String? nowPlaying;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.onLongPress,
    this.onDownload,
    this.isFavorite = false,
    this.isVOD = false,
    this.nowPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildLogo(),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black26,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (nowPlaying != null)
                        Text(
                          nowPlaying!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9, color: Colors.deepPurple.shade200),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Favorite star
            if (isFavorite)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.star, size: 18, color: Colors.amber.shade400),
              ),
            // VOD/Download indicator
            if (isVOD)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('VOD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                channel.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                isFavorite ? Icons.star : Icons.star_outline,
                color: isFavorite ? Colors.amber : null,
              ),
              title: Text(isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                onLongPress?.call();
              },
            ),
            if (isVOD && onDownload != null)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  onDownload?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (channel.tvgLogo != null && channel.tvgLogo!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: channel.tvgLogo!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Icon(Icons.live_tv, size: 40),
        errorWidget: (_, __, ___) => const Icon(Icons.live_tv, size: 40),
      );
    }
    return const Icon(Icons.live_tv, size: 40);
  }
}
