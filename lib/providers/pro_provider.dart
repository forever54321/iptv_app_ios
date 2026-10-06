import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pro_service.dart';

/// True when Pro features may be used: owned, or inside the free week.
final hasProAccessProvider =
    NotifierProvider<HasProAccessNotifier, bool>(HasProAccessNotifier.new);

class HasProAccessNotifier extends Notifier<bool> {
  @override
  bool build() {
    ProService.instance.hasAccess.addListener(_update);
    ref.onDispose(() => ProService.instance.hasAccess.removeListener(_update));
    return ProService.instance.hasAccess.value;
  }

  void _update() => state = ProService.instance.hasAccess.value;
}

final isProProvider = NotifierProvider<IsProNotifier, bool>(IsProNotifier.new);

class IsProNotifier extends Notifier<bool> {
  @override
  bool build() {
    ProService.instance.isPro.addListener(_update);
    ref.onDispose(() => ProService.instance.isPro.removeListener(_update));
    return ProService.instance.isPro.value;
  }

  void _update() => state = ProService.instance.isPro.value;
}
