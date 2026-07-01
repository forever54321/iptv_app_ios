import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced search — only triggers filtering after 300ms of no typing
final debouncedSearchProvider = StateProvider<String>((ref) {
  Timer? timer;
  ref.listen(searchQueryProvider, (prev, next) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 300), () {
      ref.controller.state = next;
    });
  });
  ref.onDispose(() => timer?.cancel());
  return '';
});
