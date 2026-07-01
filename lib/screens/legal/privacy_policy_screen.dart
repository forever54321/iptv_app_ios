import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: March 28, 2026',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildHighlight(
              'Summary: IPTV Stream Player does not collect, store, or share any personal data. All information stays on your device.',
            ),
            _buildSection('1. Introduction',
              'IPTV Stream Player ("the App") is developed and published by Saed Zakari. '
              'This Privacy Policy describes how we handle information when you use our App on iOS, macOS, and tvOS platforms.\n\n'
              'We are committed to protecting your privacy. This App is designed to operate without collecting any personal information.',
            ),
            _buildSection('2. Information We Do NOT Collect',
              '• We do not collect personal information (name, email, phone number, etc.)\n'
              '• We do not track your location\n'
              '• We do not collect usage analytics or statistics\n'
              '• We do not use advertising or ad tracking\n'
              '• We do not use cookies or similar tracking technologies\n'
              '• We do not share any data with third parties\n'
              '• We do not monitor the content you access through the App\n'
              '• We do not log your streaming activity or viewing history on our servers',
            ),
            _buildSection('3. Data Stored Locally on Your Device',
              'The App stores the following data locally on your device only. This data never leaves your device and is not accessible to us:\n\n'
              '• Playlist URLs: M3U playlist links and Xtream Codes server details that you manually enter\n'
              '• Favorite Channels: Channels you mark as favorites\n'
              '• App Settings: Your preferences such as language, aspect ratio, parental control PIN, and display options\n'
              '• Cached Data: Temporary cached channel logos and playlist data for faster loading (can be cleared in Settings)\n'
              '• Legal Disclaimer Acceptance: Whether you have accepted the terms of use\n\n'
              'You can delete all locally stored data at any time by uninstalling the App or using the cache clearing options in Settings.',
            ),
            _buildSection('4. Network Communications',
              'The App connects to the internet for the following purposes only:\n\n'
              '• Fetching Playlists: Downloading M3U playlist files from URLs that you provide\n'
              '• Streaming Content: Playing video streams from URLs contained in your playlists\n'
              '• Loading Channel Logos: Downloading channel logo images referenced in your playlists\n\n'
              'All network connections are initiated based on URLs that you provide. The App does not connect to any servers owned or operated by us. We have no visibility into the content you access.',
            ),
            _buildSection('5. Third-Party Services',
              'The App does not integrate with any third-party services including:\n\n'
              '• No analytics services (Google Analytics, Firebase, etc.)\n'
              '• No advertising networks\n'
              '• No crash reporting services\n'
              '• No social media SDKs\n'
              '• No user authentication services\n\n'
              'When you enter a playlist URL, the App connects directly to that URL. We are not responsible for the privacy practices of the servers hosting the content you choose to access.',
            ),
            _buildSection('6. Children\'s Privacy',
              'The App includes a Parental Control feature that allows a parent or guardian to set a PIN code and lock specific channel categories. '
              'The App does not knowingly collect any information from children under the age of 13. '
              'If you are a parent or guardian, we encourage you to use the Parental Control feature to restrict access to inappropriate content.',
            ),
            _buildSection('7. Data Security',
              'Since we do not collect or store any data on our servers, there is no risk of a data breach from our side. '
              'All data stored locally on your device is protected by your device\'s built-in security features (device passcode, Face ID, Touch ID, etc.).',
            ),
            _buildSection('8. Your Rights',
              'Since we do not collect any personal data, there is no personal data for us to access, modify, or delete. '
              'All data is stored locally on your device and is fully under your control. You can:\n\n'
              '• Clear cached data through the App\'s Settings\n'
              '• Delete all App data by uninstalling the App\n'
              '• Remove individual playlists and favorites from within the App',
            ),
            _buildSection('9. Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated "Last updated" date. '
              'We encourage you to review this Privacy Policy periodically.',
            ),
            _buildSection('10. Contact Us',
              'If you have any questions or concerns about this Privacy Policy, please contact us at:\n\n'
              'Email: IPTV@zakari.me',
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 IPTV App. All rights reserved.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlight(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: Colors.deepPurple, width: 4)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade300, height: 1.6),
          ),
        ],
      ),
    );
  }
}
