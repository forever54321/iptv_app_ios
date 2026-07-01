import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../services/parental_pin_service.dart';

// Parental control providers
final parentalPinProvider = StateProvider<String?>((ref) => null);
final parentalLockedGroupsProvider = StateProvider<Set<String>>((ref) => {});

class ParentalControlScreen extends ConsumerStatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  ConsumerState<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends ConsumerState<ParentalControlScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _hasPin = false;
  bool _isUnlocked = false;
  Set<String> _lockedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin = await ParentalPinService.hasPin();
    final locked = prefs.getStringList('parental_locked_groups') ?? [];
    setState(() {
      _hasPin = hasPin;
      _lockedGroups = locked.toSet();
    });
    ref.read(parentalLockedGroupsProvider.notifier).state = _lockedGroups;
  }

  Future<void> _savePin(String pin) async {
    await ParentalPinService.setPin(pin);
    setState(() => _hasPin = true);
    ref.read(parentalPinProvider.notifier).state = pin;
  }

  Future<void> _removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await ParentalPinService.removePin();
    await prefs.remove('parental_locked_groups');
    setState(() {
      _hasPin = false;
      _isUnlocked = false;
      _lockedGroups = {};
    });
    ref.read(parentalPinProvider.notifier).state = null;
    ref.read(parentalLockedGroupsProvider.notifier).state = {};
  }

  Future<void> _saveLockedGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('parental_locked_groups', _lockedGroups.toList());
    ref.read(parentalLockedGroupsProvider.notifier).state = _lockedGroups;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(S.parentalControl(lang)),
      ),
      body: _hasPin && !_isUnlocked
          ? _buildPinEntry(context)
          : _hasPin
              ? _buildSettings(context)
              : _buildSetupPin(context),
    );
  }

  /// Ask for PIN to unlock settings
  Widget _buildPinEntry(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.deepPurple.shade300),
            const SizedBox(height: 16),
            const Text(
              'Enter PIN to access Parental Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '• • • •',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final ok = await ParentalPinService.verifyPin(_pinController.text);
                if (ok) {
                  setState(() => _isUnlocked = true);
                  _pinController.clear();
                } else {
                  _pinController.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect PIN')),
                    );
                  }
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  /// First time setup — create PIN
  Widget _buildSetupPin(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Colors.deepPurple.shade300),
            const SizedBox(height: 16),
            const Text(
              'Set a 4-digit PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This PIN will be required to access locked content',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: 'PIN',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _confirmPinController,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: 'Confirm',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_pinController.text.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be 4 digits')),
                  );
                  return;
                }
                if (_pinController.text != _confirmPinController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PINs do not match')),
                  );
                  return;
                }
                _savePin(_pinController.text);
                _pinController.clear();
                _confirmPinController.clear();
                setState(() => _isUnlocked = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN set successfully')),
                );
              },
              child: const Text('Set PIN'),
            ),
          ],
        ),
      ),
    );
  }

  /// Main settings — lock/unlock groups, change/remove PIN
  Widget _buildSettings(BuildContext context) {
    return ListView(
      children: [
        // Lock groups section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'LOCKED CATEGORIES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.deepPurple.shade300,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Locked categories require PIN entry before viewing',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(height: 8),
        // Common categories to lock
        ..._buildCategoryLockTiles(),

        // PIN management
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
          child: Text(
            'PIN MANAGEMENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.deepPurple.shade300,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.pin, color: Colors.deepPurple.shade200),
              title: const Text('Change PIN'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
              onTap: () => _showChangePinDialog(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove PIN', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remove PIN?'),
                    content: const Text('This will disable parental controls and unlock all categories.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          _removePin();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Parental controls disabled')),
                          );
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  List<Widget> _buildCategoryLockTiles() {
    // Common categories that users might want to lock
    final categories = [
      'Adult', 'XXX', '18+', 'For Adults',
      'Movies', 'Series', 'Entertainment',
      'Sports', 'Music', 'Kids', 'News',
      'Documentary', 'Lifestyle', 'Religious',
    ];

    return categories.map((cat) {
      final isLocked = _lockedGroups.contains(cat);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            secondary: Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              color: isLocked ? Colors.red.shade300 : Colors.grey.shade500,
            ),
            title: Text(cat),
            value: isLocked,
            activeColor: Colors.red,
            onChanged: (v) {
              setState(() {
                if (v) {
                  _lockedGroups.add(cat);
                } else {
                  _lockedGroups.remove(cat);
                }
              });
              _saveLockedGroups();
            },
          ),
        ),
      );
    }).toList();
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Current PIN', counterText: ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'New PIN', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await ParentalPinService.verifyPin(oldPinCtrl.text);
              if (!ok) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect current PIN')),
                  );
                }
                return;
              }
              if (newPinCtrl.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New PIN must be 4 digits')),
                );
                return;
              }
              await _savePin(newPinCtrl.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
