import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/pro_provider.dart';
import '../../services/pro_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    if (isPro) {
      return _ProUnlockedSuccess(isStandalone: !context.canPop());
    }

    final product = ProService.instance.product;
    final price = product?.price ?? '\$3.99';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.purpleAccent.shade400,
                      Colors.deepPurple.shade700,
                    ],
                  ),
                ),
                child: const Icon(Icons.shield, size: 48, color: Colors.white),
              ).wrapCentered(),
              const SizedBox(height: 16),
              const Text(
                'IPTV Player Pro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'One-time purchase  •  No subscription',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 28),
              _feature(Icons.tv, 'EPG Program Guide',
                  'Traditional TV guide with now-playing highlight'),
              _feature(Icons.fiber_manual_record, 'Channel Recording',
                  'Record any live stream to disk'),
              _feature(Icons.favorite, 'Favorites',
                  'Save and quickly access favorite channels'),
              _feature(Icons.lock, 'Parental Control',
                  'PIN-protect adult content and settings'),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _busy || product == null ? null : _buy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Unlock Pro — $price',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Restore Purchase'),
              ),
              TextButton(
                onPressed: _busy ? null : _redeemPromoCode,
                child: const Text('Redeem Promo Code'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Supports an independent developer. No ads, no tracking, no subscriptions — ever.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.purpleAccent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      await ProService.instance.buy();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await ProService.instance.restore();
      if (mounted && !ref.read(isProProvider)) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Restore Result'),
            content: Text(ProService.instance.diagnosticMessage()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeemPromoCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Promo Code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Enter code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;

    final ok = await ProService.instance.redeemPromoCode(code);
    if (!mounted) return;
    if (!ok) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid Code'),
          content: const Text(
              'That code is not valid or has expired. Please double-check the code and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

extension _Centered on Widget {
  Widget wrapCentered() => Center(child: this);
}

class _ProUnlockedSuccess extends StatelessWidget {
  final bool isStandalone;
  const _ProUnlockedSuccess({required this.isStandalone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent.shade400,
                      Colors.green.shade700,
                    ],
                  ),
                ),
                child: const Icon(Icons.check, size: 72, color: Colors.white),
              ).wrapCentered(),
              const SizedBox(height: 24),
              const Text(
                'Pro Unlocked',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you! All features are now available.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
