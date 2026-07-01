import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/epg_program.dart';
import '../../models/m3u_entry.dart';
import '../../providers/channel_list_provider.dart';
import '../../providers/epg_provider.dart';
import '../../providers/category_filter_provider.dart';
import '../../services/epg_service.dart';
import '../../widgets/loading_widget.dart';

class EpgScreen extends ConsumerStatefulWidget {
  const EpgScreen({super.key});

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> {
  final ScrollController _timeScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();
  String _searchQuery = '';
  bool _isLoadingEpg = false;

  // Timeline config
  static const double channelWidth = 120.0;
  static const double rowHeight = 80.0;
  static const double timeHeaderHeight = 40.0;
  static const double pixelsPerMinute = 4.0; // 4px per minute = 240px per hour

  late DateTime _timelineStart;
  late DateTime _timelineEnd;

  @override
  void initState() {
    super.initState();
    // Timeline from 2 hours ago to 24 hours from now
    final now = DateTime.now();
    _timelineStart = DateTime(now.year, now.month, now.day, now.hour - 2);
    _timelineEnd = _timelineStart.add(const Duration(hours: 26));

    // Scroll to current time after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = now.difference(_timelineStart).inMinutes * pixelsPerMinute - 200;
      if (offset > 0) {
        _timeScrollController.jumpTo(offset);
        _gridScrollController.jumpTo(offset);
      }
    });
  }

  @override
  void dispose() {
    _timeScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  void _showAddEpgUrlDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    EpgService.getManualUrl().then((url) {
      controller.text = url ?? '';
    });
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('EPG URL'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your XMLTV EPG URL:', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://example.com/epg.xml',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              await EpgService.setManualUrl(url.isEmpty ? null : url);
              ref.invalidate(epgUrlProvider);
              ref.invalidate(epgProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              setState(() => _isLoadingEpg = true);
              await ref.read(epgProvider.notifier).refresh();
              if (mounted) setState(() => _isLoadingEpg = false);
            },
            child: const Text('Save & Load'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelListProvider);
    final epgAsync = ref.watch(epgProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        title: const Text('EPG Guide'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(epgProvider.notifier).refresh()),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEpgUrlDialog(context, ref)),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (channels) {
          final epgData = epgAsync.valueOrNull ?? {};

          if (_isLoadingEpg || epgAsync.isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading EPG data...')],
              ),
            );
          }

          if (epgData.isEmpty) {
            return _buildEmptyState(context, ref, epgAsync);
          }

          // Filter channels with EPG data
          var epgChannels = channels.where((ch) {
            final id = ch.tvgId ?? '';
            return id.isNotEmpty && (epgData.containsKey(id) || epgData.keys.any((k) => k.toLowerCase() == id.toLowerCase()));
          }).toList();

          if (_searchQuery.isNotEmpty) {
            epgChannels = epgChannels.where((ch) => ch.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search channels...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true, fillColor: Colors.white.withValues(alpha: 0.07),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              // EPG Grid
              Expanded(child: _buildEpgGrid(epgChannels, epgData)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, AsyncValue epgAsync) {
    final epgUrl = ref.watch(epgUrlProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 60, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(epgAsync.hasError ? 'Failed to load EPG' : 'No EPG Data', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tap + to add your EPG URL', style: TextStyle(color: Colors.grey, fontSize: 13)),
          if (epgUrl.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('URL: ${epgUrl.valueOrNull}', style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 2),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddEpgUrlDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add EPG URL'),
          ),
        ],
      ),
    );
  }

  Widget _buildEpgGrid(List<M3uEntry> channels, Map<String, List<EpgProgram>> epgData) {
    final totalMinutes = _timelineEnd.difference(_timelineStart).inMinutes;
    final totalWidth = totalMinutes * pixelsPerMinute;
    final now = DateTime.now();
    final nowOffset = now.difference(_timelineStart).inMinutes * pixelsPerMinute;

    return Row(
      children: [
        // Channel logos column (fixed)
        SizedBox(
          width: channelWidth,
          child: Column(
            children: [
              // Empty corner
              Container(height: timeHeaderHeight, color: const Color(0xFF1A1A2E)),
              // Channel logos
              Expanded(
                child: ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final ch = channels[index];
                    return GestureDetector(
                      onTap: () {
                        final allChannels = ref.read(channelListProvider).valueOrNull ?? [];
                        final idx = allChannels.indexWhere((c) => c.url == ch.url);
                        if (idx >= 0) {
                          ref.read(selectedCategoryProvider.notifier).state = null;
                          context.go('/player', extra: {'initialIndex': idx});
                        }
                      },
                      child: Container(
                        height: rowHeight,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (ch.tvgLogo != null && ch.tvgLogo!.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: ch.tvgLogo!,
                                width: 50, height: 35, fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => const Icon(Icons.tv, size: 24, color: Colors.grey),
                              )
                            else
                              const Icon(Icons.tv, size: 24, color: Colors.grey),
                            const SizedBox(height: 2),
                            Text(ch.title, style: const TextStyle(fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Scrollable grid
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                _timeScrollController.jumpTo(_gridScrollController.offset);
              }
              return false;
            },
            child: Column(
              children: [
                // Time header
                SizedBox(
                  height: timeHeaderHeight,
                  child: SingleChildScrollView(
                    controller: _timeScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: totalWidth,
                      child: CustomPaint(
                        painter: _TimeHeaderPainter(
                          start: _timelineStart,
                          pixelsPerMinute: pixelsPerMinute,
                          nowOffset: nowOffset,
                        ),
                      ),
                    ),
                  ),
                ),
                // Program grid
                Expanded(
                  child: ListView.builder(
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final ch = channels[index];
                      final channelId = ch.tvgId ?? '';
                      final programs = epgData[channelId] ??
                          epgData[epgData.keys.firstWhere((k) => k.toLowerCase() == channelId.toLowerCase(), orElse: () => '')] ??
                          [];

                      return SizedBox(
                        height: rowHeight,
                        child: SingleChildScrollView(
                          controller: index == 0 ? _gridScrollController : null,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalWidth,
                            child: Stack(
                              children: [
                                // Row background
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
                                  ),
                                ),
                                // Program blocks
                                ...programs.map((program) {
                                  final startOffset = max(0.0, program.start.difference(_timelineStart).inMinutes * pixelsPerMinute);
                                  final endOffset = program.stop.difference(_timelineStart).inMinutes * pixelsPerMinute;
                                  final width = max(40.0, endOffset - startOffset);
                                  final isLive = program.isNowPlaying;

                                  return Positioned(
                                    left: startOffset,
                                    top: 2,
                                    child: GestureDetector(
                                      onTap: () => _showProgramDetail(context, program, ch),
                                      child: Container(
                                        width: width - 2,
                                        height: rowHeight - 4,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isLive ? Colors.deepPurple.shade800 : const Color(0xFF252540),
                                          borderRadius: BorderRadius.circular(4),
                                          border: isLive ? Border.all(color: Colors.deepPurple.shade400, width: 1) : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    program.title,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: isLive ? FontWeight.w700 : FontWeight.w500,
                                                      color: isLive ? Colors.white : Colors.grey.shade300,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isLive)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(3)),
                                                    child: const Text('LIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                                                  ),
                                              ],
                                            ),
                                            if (program.description != null && width > 100)
                                              Expanded(
                                                child: Text(
                                                  program.description!,
                                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            Text(
                                              program.timeRange,
                                              style: TextStyle(fontSize: 9, color: isLive ? Colors.deepPurple.shade200 : Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                // Now marker
                                Positioned(
                                  left: nowOffset,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(width: 2, color: Colors.red.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProgramDetail(BuildContext context, EpgProgram program, M3uEntry channel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(program.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (program.isNowPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    child: const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(channel.title, style: TextStyle(color: Colors.deepPurple.shade200, fontSize: 13)),
            const SizedBox(height: 4),
            Text(program.timeRange, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            if (program.isNowPlaying) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: program.progress, backgroundColor: Colors.grey.shade800, color: Colors.deepPurple, minHeight: 4),
              ),
            ],
            if (program.description != null && program.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(program.description!, style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.4)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final allChannels = ref.read(channelListProvider).valueOrNull ?? [];
                  final idx = allChannels.indexWhere((c) => c.url == channel.url);
                  if (idx >= 0) {
                    ref.read(selectedCategoryProvider.notifier).state = null;
                    context.go('/player', extra: {'initialIndex': idx});
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('Watch ${channel.title}'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TimeHeaderPainter extends CustomPainter {
  final DateTime start;
  final double pixelsPerMinute;
  final double nowOffset;

  _TimeHeaderPainter({required this.start, required this.pixelsPerMinute, required this.nowOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(color: Colors.grey.shade400, fontSize: 11);
    final boldTextStyle = const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600);
    final linePaint = Paint()..color = Colors.grey.shade700..strokeWidth = 1;
    final nowPaint = Paint()..color = Colors.red..strokeWidth = 2;

    // Draw 30-minute intervals
    for (var i = 0; i < 52; i++) {
      final minutes = i * 30;
      final x = minutes * pixelsPerMinute;
      final time = start.add(Duration(minutes: minutes));
      final isHour = time.minute == 0;

      canvas.drawLine(Offset(x, isHour ? 0 : size.height * 0.5), Offset(x, size.height), linePaint);

      if (isHour) {
        final hour = time.hour;
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final label = '$displayHour:00 $ampm';

        final tp = TextPainter(text: TextSpan(text: label, style: textStyle), textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x + 4, 4));
      } else {
        final hour = time.hour;
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final label = '$displayHour:30 $ampm';

        final tp = TextPainter(text: TextSpan(text: label, style: textStyle), textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x + 4, 8));
      }
    }

    // Now marker
    canvas.drawLine(Offset(nowOffset, 0), Offset(nowOffset, size.height), nowPaint);

    // "Now" label
    final nowTp = TextPainter(text: TextSpan(text: 'Now', style: boldTextStyle), textDirection: TextDirection.ltr);
    nowTp.layout();
    canvas.drawRect(Rect.fromLTWH(nowOffset - 2, 0, nowTp.width + 8, nowTp.height + 4), Paint()..color = Colors.red);
    nowTp.paint(canvas, Offset(nowOffset + 2, 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
