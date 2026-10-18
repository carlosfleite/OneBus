import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/bus_simulator.dart';
import '../services/favorites_store.dart';
import '../services/nearby.dart';
import '../widgets/ios.dart';
import '../widgets/stop_widgets.dart';
import '../widgets/tab_page.dart';
import 'app_shell.dart';
import 'sheet/sheet_nav.dart';

/// "Pontos": every bus stop, closest first, with the lines that serve it.
class StopsTab extends StatefulWidget {
  const StopsTab({super.key});

  @override
  State<StopsTab> createState() => _StopsTabState();
}

class _StopsTabState extends State<StopsTab> {
  final _search = TextEditingController();
  String? _line;
  bool _onlyAccessible = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = AppNav.of(context);
    final ios = IosColors.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        BusSimulator.instance,
        FavoritesStore.instance,
      ]),
      builder: (context, _) {
        final favs = FavoritesStore.instance;
        final all = stopsByDistance();
        final nearestId = all.first.stop.id;
        final q = _search.text.trim().toLowerCase();
        final shown = all.where((n) {
          final s = n.stop;
          final matchesText =
              q.isEmpty ||
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q);
          final matchesLine = _line == null || s.lineIds.contains(_line);
          final matchesAccess = !_onlyAccessible || s.accessible;
          return matchesText && matchesLine && matchesAccess;
        }).toList();
        final nearestShown = shown.where((n) => n.stop.id == nearestId);
        final others = shown.where((n) => n.stop.id != nearestId).toList();

        Widget row(NearbyStop n) => Row(
          children: [
            Expanded(
              child: StopListRow(
                near: n,
                isNearest: n.stop.id == nearestId,
                chevron: false,
                onTap: () => nav.openOnMap(StopPage(n.stop.id)),
              ),
            ),
            GestureDetector(
              onTap: () => favs.toggleStop(n.stop.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                child: Icon(
                  favs.hasStop(n.stop.id)
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.star,
                  size: 20,
                  color: favs.hasStop(n.stop.id)
                      ? AppColors.orange
                      : ios.tertiaryLabel,
                ),
              ),
            ),
          ],
        );

        return TabPage(
          title: 'Pontos',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () => nav.openOnMap(const HomePage()),
            child: const Text('Ver no mapa'),
          ),
          children: [
            CupertinoSearchTextField(
              controller: _search,
              placeholder: 'Buscar ponto ou bairro',
              backgroundColor: ios.fill,
              style: Theme.of(context).textTheme.bodyLarge,
              itemColor: ios.secondaryLabel,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.accessible_rounded, size: 18),
                        SizedBox(width: 4),
                        Text('Acessíveis'),
                      ],
                    ),
                    selected: _onlyAccessible,
                    onTap: () =>
                        setState(() => _onlyAccessible = !_onlyAccessible),
                  ),
                  _FilterChip(
                    label: const Text('Todas as linhas'),
                    selected: _line == null,
                    onTap: () => setState(() => _line = null),
                  ),
                  for (final line in MockData.lines)
                    _FilterChip(
                      label: LineBadge(line, height: 20),
                      selected: _line == line.id,
                      onTap: () => setState(
                        () => _line = _line == line.id ? null : line.id,
                      ),
                    ),
                ],
              ),
            ),
            if (nearestShown.isNotEmpty) ...[
              const SectionHeader('Mais próximo de você'),
              InsetGroup(children: [row(nearestShown.first)]),
            ],
            SectionHeader(
              _line == null
                  ? 'Todos os pontos'
                  : 'Pontos da linha ${MockData.line(_line!).number}',
            ),
            InsetGroup(
              separatorIndent: 58,
              footer:
                  '${shown.length} de ${all.length} pontos · distâncias a partir da sua localização. '
                  'Toque para ver no mapa; estrela para favoritar.',
              children: [
                if (others.isEmpty && nearestShown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Nenhum ponto encontrado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ios.secondaryLabel),
                    ),
                  ),
                for (final n in others) row(n),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ios.tint.withValues(alpha: 0.15) : ios.cell,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? ios.tint : ios.separator,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? ios.tint : ios.label,
            ),
            child: label,
          ),
        ),
      ),
    );
  }
}
