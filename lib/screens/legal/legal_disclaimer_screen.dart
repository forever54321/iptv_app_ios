import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class LegalDisclaimerScreen extends StatelessWidget {
  const LegalDisclaimerScreen({super.key});

  static const _acceptedKey = 'legal_disclaimer_accepted';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedKey) ?? false;
  }

  Future<void> _accept(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_acceptedKey, true);
    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.shield_outlined,
                  size: 64, color: Colors.deepPurple.shade300),
              const SizedBox(height: 16),
              Text(
                'Terms of Use & Legal Disclaimer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Please read and accept the following terms before using this application.\n\n'
                      '1. PURPOSE OF THE APPLICATION\n'
                      'IPTV Player is a generic media player application, similar to VLC or Infuse. It allows users to load and play their own M3U playlist files and streaming URLs. This application does not host, store, provide, index, catalog, or distribute any media content or streaming services. No content of any kind is included with or provided by this application.\n\n'
                      '2. USER-PROVIDED CONTENT ONLY\n'
                      'All content played through this application is provided entirely by the user. The application functions solely as a playback tool for media URLs that the user manually enters. The developers have no knowledge of, control over, or responsibility for the content that users choose to play.\n\n'
                      '3. USER RESPONSIBILITY\n'
                      'You are solely and fully responsible for all content you access through this application. By using this app, you agree that:\n\n'
                      '   a) You will only access content that you are legally authorized to view in your jurisdiction.\n\n'
                      '   b) You will not use this application to access, stream, or distribute copyrighted material without the express permission of the copyright holder.\n\n'
                      '   c) You are responsible for ensuring that any M3U playlists, URLs, or streams you add to this application are obtained legally and that you have the right to access them.\n\n'
                      '   d) You understand that some content may be geo-restricted and that bypassing geo-restrictions may violate applicable laws or terms of service.\n\n'
                      '   e) You acknowledge that using this application to play unauthorized or pirated content is strictly prohibited and may result in legal consequences for which you bear sole responsibility.\n\n'
                      '   f) You will only download or record content that you own or have explicit authorization to copy. Unauthorized downloading or recording of copyrighted material is illegal.\n\n'
                      '4. DOWNLOADING AND RECORDING\n'
                      'This application provides download and recording features for personal use only. By using these features, you acknowledge that:\n\n'
                      '   a) You are solely responsible for ensuring you have the legal right to download or record any content.\n\n'
                      '   b) Downloading or recording copyrighted material without permission from the copyright holder is strictly prohibited.\n\n'
                      '   c) The developers are not responsible for any unauthorized use of the download or recording features.\n\n'
                      '   d) Downloaded and recorded files are stored locally on your device and are your responsibility.\n\n'
                      '5. DISCLAIMER OF LIABILITY\n'
                      'The developers of this application shall not be held liable for:\n\n'
                      '   a) Any content accessed by the user through playlists or URLs entered by the user.\n\n'
                      '   b) Any legal consequences arising from the user\'s misuse of this application.\n\n'
                      '   c) Any damages, losses, or claims resulting from the use of this application.\n\n'
                      '   d) The availability, legality, or quality of any streams or content accessed by the user.\n\n'
                      '6. NO THIRD-PARTY CONTENT OR SERVICES\n'
                      'This application does not provide access to any third-party audio or video streaming services, catalogs, or discovery services. It does not aggregate, curate, or recommend any content. All playback functionality requires the user to manually provide their own streaming URLs.\n\n'
                      '7. INTELLECTUAL PROPERTY\n'
                      'All trademarks, logos, and brand names that may appear within user-provided streaming content belong to their respective owners. Their appearance does not imply endorsement by or affiliation with this application.\n\n'
                      '8. COMPLIANCE WITH LAWS\n'
                      'You agree to comply with all applicable local, state, national, and international laws and regulations when using this application. If you are unsure whether your use of certain content is legal, you should seek legal advice before proceeding.\n\n'
                      '9. CHANGES TO TERMS\n'
                      'We reserve the right to update these terms at any time. Continued use of the application constitutes acceptance of the updated terms.\n\n'
                      'By tapping "I Agree" below, you acknowledge that you have read, understood, and agree to be bound by these terms.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _accept(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I Agree',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => _decline(context),
                  child: Text(
                    'Decline',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _decline(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cannot Continue'),
        content: const Text(
          'You must accept the terms of use to use this application. '
          'If you decline, you will not be able to proceed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
