import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../services/favorites_store.dart';
import 'ds/app_sheets.dart';
import 'ds/app_toast.dart';

/// Adds or removes a favorite line. Removing asks first, since it also
/// turns off its arrival alerts; both outcomes get a toast.
Future<void> toggleLineFavorite(BuildContext context, String lineId) async {
  final favs = FavoritesStore.instance;
  final line = MockData.line(lineId);
  if (favs.hasLine(lineId)) {
    final ok = await showConfirmDialog(
      context,
      title: 'Remover linha ${line.number}?',
      message: 'Você deixa de receber avisos de chegada dessa linha.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;
    favs.toggleLine(lineId);
    AppToast.info('Linha ${line.number} removida dos favoritos.');
  } else {
    favs.toggleLine(lineId);
    AppToast.success('Linha ${line.number} adicionada aos favoritos.');
  }
}

/// Same as [toggleLineFavorite], for stops.
Future<void> toggleStopFavorite(BuildContext context, String stopId) async {
  final favs = FavoritesStore.instance;
  final stop = MockData.stop(stopId);
  if (favs.hasStop(stopId)) {
    final ok = await showConfirmDialog(
      context,
      title: 'Remover ${stop.name}?',
      message: 'Você deixa de receber avisos de chegada nesse ponto.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;
    favs.toggleStop(stopId);
    AppToast.info('Ponto removido dos favoritos.');
  } else {
    favs.toggleStop(stopId);
    AppToast.success('Ponto adicionado aos favoritos.');
  }
}
