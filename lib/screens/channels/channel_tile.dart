import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/m3u_entry.dart';

class ChannelTile extends StatelessWidget {
  final M3uEntry channel;
  final VoidCallback onTap;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.black26,
              child: Text(
                channel.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
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
        placeholder: (_, _) => const Icon(Icons.live_tv, size: 40),
        errorWidget: (_, _, _) => const Icon(Icons.live_tv, size: 40),
      );
    }
    return const Icon(Icons.live_tv, size: 40);
  }
}
