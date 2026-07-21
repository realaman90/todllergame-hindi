import 'dart:async';

/// Idle-nudge timer (feel rule F17): when a prompted task sees no input
/// for [delay], fire [onNudge] — a helping hand (sparkle the target,
/// re-prompt softly), never a countdown or consequence.
///
/// Call [arm] on every meaningful input to push the nudge away; call
/// [cancel]/[dispose] once the task is solved or the screen leaves.
class NudgeTimer {
  final void Function() onNudge;
  final Duration delay;
  Timer? _timer;

  NudgeTimer({required this.onNudge, this.delay = const Duration(seconds: 7)});

  void arm() {
    _timer?.cancel();
    _timer = Timer(delay, onNudge);
  }

  void cancel() => _timer?.cancel();

  void dispose() => cancel();
}
