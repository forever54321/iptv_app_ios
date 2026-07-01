import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pro_service.dart';

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
