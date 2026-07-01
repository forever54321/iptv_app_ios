import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsNewScreen extends StatelessWidget {
  final bool isStartup;
  const WhatsNewScreen({super.key, this.isStartup = false});

  static const _shownKey = 'whats_new_v4_1_2_shown';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_shownKey) ?? false);
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shownKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade800,
                            Colors.purple.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 48, color: Colors.white),
                          const SizedBox(height: 12),
                          const Text(
                            "What's New in v4.1.2",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'IPTV Stream Player',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    const _SectionHeader(title: 'BIG NEWS'),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.verified,
                      color: Colors.green,
                      title: 'Thank You — You Get Pro Free',
                      description:
                          'You already paid for the app. All Pro features stay unlocked on this device, automatically. No action needed.',
                    ),
                    _FeatureCard(
                      icon: Icons.celebration,
                      color: Colors.deepPurple,
                      title: 'App is Now Free to Download',
                      description:
                          'New users get the app for free. A one-time \$3.99 Pro Unlock adds EPG, Recording, Favorites, and Parental Control. No subscriptions.',
                    ),

                    const SizedBox(height: 24),

                    const _SectionHeader(title: 'PLAYBACK IMPROVEMENTS'),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.bolt,
                      color: Colors.amber,
                      title: 'Faster Channel Switching',
                      description:
                          'Shallower stream probing starts playback in under a second — matches VLC-style live behavior.',
                    ),
                    _FeatureCard(
                      icon: Icons.save,
                      color: Colors.blue,
                      title: 'Disk-Cached Rolling Buffer',
                      description:
                          'Live streams now hold a 60-second reserve on disk, so short network dips no longer pause playback.',
                    ),
                    _FeatureCard(
                      icon: Icons.memory,
                      color: Colors.teal,
                      title: 'Lower Memory Use',
                      description:
                          'Buffer overflows to storage instead of RAM — iOS no longer kills the app under memory pressure.',
                    ),

                    const SizedBox(height: 24),

                    const _SectionHeader(title: 'ALSO INCLUDED'),
                    const SizedBox(height: 12),

                    _FeatureCard(
                      icon: Icons.schedule,
                      color: Colors.blue,
                      title: 'EPG Program Guide',
                      description:
                          'Traditional TV guide grid with now-playing highlight. Auto-detects from your playlist or XMLTV URL.',
                    ),
                    _FeatureCard(
                      icon: Icons.fiber_manual_record,
                      color: Colors.red,
                      title: 'Record Live Channels',
                      description:
                          'Record live streams and play them back from the Recordings section.',
                    ),
                    _FeatureCard(
                      icon: Icons.star,
                      color: Colors.amber,
                      title: 'Favorites & Recent',
                      description:
                          'Save favorite channels and quickly access recently watched content.',
                    ),
                    _FeatureCard(
                      icon: Icons.shield_outlined,
                      color: Colors.orange,
                      title: 'Parental Control',
                      description:
                          'Set a 4-digit PIN and lock specific channel categories.',
                    ),
                    _FeatureCard(
                      icon: Icons.language,
                      color: Colors.green,
                      title: '15 Languages',
                      description:
                          'Full translation in English, Arabic, French, Spanish, German, and 10 more.',
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.red.shade300, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Important Legal Notice',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This app does not provide any content. You must supply your own M3U playlist URLs or Xtream Codes credentials. '
                            'You are solely responsible for ensuring that the content you access is legal in your jurisdiction.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'IPTV Stream Player v4.1.2',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    markShown();
                    if (isStartup) {
                      context.go('/home');
                    } else {
                      context.go('/settings');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isStartup ? "Let's Go!" : 'Close',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.deepPurple.shade300,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
