import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/glass.dart';
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
    return GlossyCard(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      radius: 14,
      padding: EdgeInsets.zero,
      glow: isFavorite ? AppColors.amber : null,
      child: Stack(
        children: [
          Column(
            children: [
              // Logo well: a slightly recessed pane so the artwork reads as
              // sitting under glass.
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: _buildLogo(),
                ),
              ),
              // Caption plate.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.30),
                    ],
                  ),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1),
                    ),
                    if (nowPlaying != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          nowPlaying!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, color: AppColors.lift(AppColors.violet, 0.35)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isFavorite)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  boxShadow: [
                    BoxShadow(color: AppColors.amber.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: -2),
                  ],
                ),
                child: const Icon(Icons.star_rounded, size: 15, color: AppColors.amber),
              ),
            ),
          if (isVOD)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [AppColors.lift(AppColors.violet, 0.25), AppColors.violet],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Text(
                  'VOD',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLo,
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
        placeholder: (_, __) => _logoFallback(),
        errorWidget: (_, __, ___) => _logoFallback(),
      );
    }
    return _logoFallback();
  }

  Widget _logoFallback() {
    return Center(
      child: Icon(Icons.live_tv_rounded, size: 34, color: Colors.white.withValues(alpha: 0.30)),
    );
  }
}
