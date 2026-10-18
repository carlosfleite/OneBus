import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import 'bus_simulator.dart';
import 'favorites_store.dart';
import 'notification_service.dart';

/// In-app notification shown at the top of the screen.
class AppBanner {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const AppBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

enum Crowding {
  empty('Vazio', 'Muitos lugares livres'),
  seated('Tem lugar', 'Alguns lugares livres'),
  standing('Em pé', 'Só em pé'),
  packed('Lotado', 'Difícil de entrar');

  final String label;
  final String description;

  const Crowding(this.label, this.description);
}

/// Arrival alerts ("avise quando o 214 estiver a 3 min"), alighting alerts
/// ("avise antes do meu ponto") and passenger reports.
class AlertsCenter extends ChangeNotifier {
  AlertsCenter._();

  static final instance = AlertsCenter._();

  static const arrivalThresholdSeconds = 180;

  final banner = ValueNotifier<AppBanner?>(null);
  Timer? _bannerTimer;

  final Set<String> _arrival = {};
  ({String busId, String stopId})? alight;
  bool _alightWarned = false;

  int _notificationId = 1;

  /// "line|stop|bus" approaches already notified for favorite pairs.
  final Set<String> _favNotified = {};

  /// Latest crowding report per bus.
  final Map<String, ({Crowding level, DateTime at})> crowdReports = {};

  static String _key(String lineId, String stopId) => '$lineId|$stopId';

  bool hasArrivalAlert(String lineId, String stopId) =>
      _arrival.contains(_key(lineId, stopId));

  void toggleArrivalAlert(String lineId, String stopId) {
    final key = _key(lineId, stopId);
    if (!_arrival.remove(key)) {
      _arrival.add(key);
      final line = MockData.line(lineId);
      show(
        AppBanner(
          icon: CupertinoIcons.bell_fill,
          color: AppColors.orange,
          title: 'Alerta criado',
          message:
              'Avisaremos quando a linha ${line.number} estiver a 3 min de ${MockData.stop(stopId).name}.',
        ),
      );
    }
    notifyListeners();
  }

  void setAlight(String busId, String stopId) {
    alight = (busId: busId, stopId: stopId);
    _alightWarned = false;
    show(
      AppBanner(
        icon: CupertinoIcons.flag_fill,
        color: AppColors.blue,
        title: 'Vamos te avisar',
        message: 'Você será avisado antes de ${MockData.stop(stopId).name}.',
      ),
    );
    notifyListeners();
  }

  void clearAlight() {
    alight = null;
    notifyListeners();
  }

  void reportCrowding(String busId, Crowding level) {
    crowdReports[busId] = (level: level, at: DateTime.now());
    show(
      const AppBanner(
        icon: CupertinoIcons.person_2_fill,
        color: AppColors.green,
        title: 'Obrigado!',
        message:
            'Sua informação de lotação já aparece para outros passageiros.',
      ),
    );
    notifyListeners();
  }

  void reportProblem(String lineId, String problem) {
    show(
      AppBanner(
        icon: CupertinoIcons.checkmark_seal_fill,
        color: AppColors.green,
        title: 'Relato enviado',
        message:
            '"$problem" na linha ${MockData.line(lineId).number}. Protocolo #${DateTime.now().millisecondsSinceEpoch % 100000}.',
      ),
    );
  }

  /// Shows an in-app banner; with [system] also a system notification
  /// (useful when the app is in the background or another tab).
  void show(AppBanner b, {bool system = false}) {
    if (system) {
      NotificationService.instance.show(_notificationId++, b.title, b.message);
    }
    banner.value = b;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 5), dismiss);
  }

  void dismiss() {
    _bannerTimer?.cancel();
    banner.value = null;
  }

  /// Call on every GPS ping.
  void check(BusSimulator sim) {
    for (final key in _arrival.toList()) {
      final [lineId, stopId] = key.split('|');
      final eta = sim.eta(lineId, stopId);
      if (eta != null && eta.seconds <= arrivalThresholdSeconds) {
        _arrival.remove(key);
        show(
          AppBanner(
            icon: CupertinoIcons.bus,
            color: MockData.line(lineId).color,
            title: 'Linha ${MockData.line(lineId).number} chegando',
            message: '${eta.label} até ${MockData.stop(stopId).name}.',
          ),
          system: true,
        );
        notifyListeners();
      }
    }

    _checkFavorites(sim);

    final a = alight;
    if (a == null) return;
    final bus = sim.bus(a.busId);
    if (sim.currentStopOf(bus)?.id == a.stopId) {
      show(
        AppBanner(
          icon: CupertinoIcons.flag_fill,
          color: AppColors.blue,
          title: 'Desça agora',
          message: 'Você chegou em ${MockData.stop(a.stopId).name}.',
        ),
        system: true,
      );
      clearAlight();
      return;
    }
    final next = sim.upcomingStopsOf(bus, count: 1).first;
    if (!_alightWarned && next.stop.id == a.stopId && next.eta.seconds <= 60) {
      _alightWarned = true;
      show(
        AppBanner(
          icon: CupertinoIcons.flag_fill,
          color: AppColors.blue,
          title: 'Prepare-se para descer',
          message: 'Próximo ponto: ${next.stop.name}. Dê o sinal.',
        ),
        system: true,
      );
    }
  }

  /// Notifies once per approaching bus when a favorite line is within the
  /// chosen minutes of a favorite stop it serves.
  void _checkFavorites(BusSimulator sim) {
    final favs = FavoritesStore.instance;
    final pairs = favs.notifyArrivals
        ? favs.watchedPairs
        : const <({String lineId, String stopId})>[];
    final live = <String>{};
    for (final p in pairs) {
      final bus = sim.nextBusAt(p.lineId, p.stopId);
      final eta = sim.eta(p.lineId, p.stopId);
      if (bus == null || eta == null) continue;
      final key = '${p.lineId}|${p.stopId}|${bus.id}';
      live.add(key);
      if (eta.seconds <= favs.notifyMinutes * 60 && _favNotified.add(key)) {
        final line = MockData.line(p.lineId);
        show(
          AppBanner(
            icon: CupertinoIcons.star_fill,
            color: line.color,
            title: 'Linha ${line.number} chegando no seu ponto',
            message:
                '${eta.seconds < 30 ? 'Chegando agora' : 'Chega em ${eta.label}'} '
                'em ${MockData.stop(p.stopId).name}.',
          ),
          system: true,
        );
      }
    }
    // Forget buses that already passed so the next one notifies again.
    _favNotified.retainAll(live);
  }
}
