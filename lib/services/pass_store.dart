import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import 'alerts_center.dart';

String formatMoney(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// Demo balance of the transit pass, persisted on the device. Warns once
/// when the balance gets low (see [lowThreshold]) and again if it runs out.
class PassStore extends ValueNotifier<double> {
  PassStore._() : super(18.40);

  static final instance = PassStore._();

  static const _key = 'pass_balance';

  static const fare = 5.0;

  /// Service fee charged on top of every recharge.
  static const rechargeFee = 1.50;

  /// Below this the pass is "running out": fewer than two trips left.
  static const lowThreshold = 2 * fare;

  /// The warning already shown for the current balance, if any.
  _Level _warned = _Level.ok;

  bool get isLow => value < lowThreshold;

  int get tripsLeft => (value / fare).floor();

  String get tripsLabel => switch (tripsLeft) {
    0 => 'sem saldo para uma viagem',
    1 => 'saldo para 1 viagem',
    final n => 'saldo para $n viagens',
  };

  _Level get _level => value < fare
      ? _Level.empty
      : value < lowThreshold
      ? _Level.low
      : _Level.ok;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = prefs.getDouble(_key) ?? value;
    } catch (_) {}
  }

  /// Warns on launch when the pass is already running out.
  void checkOnLaunch() => _warn();

  void recharge(double amount) {
    value += amount;
    _save();
    _warned = _level;
  }

  /// Charges one fare (demo of boarding a bus).
  void chargeFare() {
    value = (value - fare).clamp(0.0, double.infinity);
    _save();
    _warn();
  }

  void _warn() {
    final level = _level;
    if (level == _Level.ok) {
      _warned = level;
      return;
    }
    if (level.index <= _warned.index) return;
    _warned = level;
    AlertsCenter.instance.show(
      AppBanner(
        icon: CupertinoIcons.creditcard_fill,
        color: level == _Level.empty ? AppColors.red : AppColors.orange,
        title: level == _Level.empty
            ? 'Seu passe acabou'
            : 'Seu passe está acabando',
        message:
            'Saldo de ${formatMoney(value)}, $tripsLabel. Recarregue para não ficar na mão.',
      ),
      system: true,
    );
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, value);
    } catch (_) {}
  }
}

enum _Level { ok, low, empty }
