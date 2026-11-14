import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';

enum FeedStatus { loading, ready, error }

/// State of the "live data" the lists depend on (bus positions, stops, pass).
///
/// Today the feed is simulated on the device, so a refresh is quick; the
/// screens already handle the three states (skeleton while loading, a retry
/// block on failure) that a real backend will need.
class FeedService extends ChangeNotifier {
  FeedService._();

  static final instance = FeedService._();

  /// How long a refresh takes (tests set this to zero).
  static Duration loadingDelay = const Duration(milliseconds: 900);

  FeedStatus status = FeedStatus.ready;

  bool get loading => status == FeedStatus.loading;
  bool get failed => status == FeedStatus.error;

  Future<void> refresh() async {
    if (loading) return;
    status = FeedStatus.loading;
    notifyListeners();
    await Future<void>.delayed(loadingDelay);
    // The service keeps `online` current from the platform's own events.
    final online = ConnectivityService.instance.online.value;
    status = online ? FeedStatus.ready : FeedStatus.error;
    notifyListeners();
  }
}
