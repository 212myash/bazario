import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionEvents {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void emitUnauthorized() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
