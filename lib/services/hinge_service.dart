import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'debug_launch_env.dart';

/// The iPhone Duo hinge, as reported by iOS 27.1's UIHingeInteraction (see HingeBridge in
/// ios/Runner/AppDelegate.swift). Every other device reports [HingeStatus.none].
enum HingeStatus { none, unknown, closed, partiallyOpen, fullyOpen }

class HingeState {
  final HingeStatus status;
  final double? angle; // degrees, when the system provides it

  const HingeState(this.status, [this.angle]);
  static const none = HingeState(HingeStatus.none);

  /// Half folded (laptop / tent style): the player splits into video + channel list.
  bool get isHalfOpen => status == HingeStatus.partiallyOpen;

  static HingeState parse(Object? event) {
    if (event is! Map) return none;
    final s = event['status'];
    final status = HingeStatus.values.firstWhere((v) => v.name == s, orElse: () => HingeStatus.none);
    final a = event['angle'];
    return HingeState(status, a is num ? a.toDouble() : null);
  }
}

const _channel = EventChannel('iptv/hinge');

final hingeProvider = StreamProvider<HingeState>((ref) {
  if (!Platform.isIOS) return Stream.value(HingeState.none);
  // Simulator screenshots: IPTV_HINGE=half pretends the Duo is half folded (DEBUG builds only).
  final forced = debugLaunchEnv('iptv')['IPTV_HINGE'];
  if (forced == 'half') return Stream.value(const HingeState(HingeStatus.partiallyOpen, 90));
  return _channel.receiveBroadcastStream().map(HingeState.parse);
});
