import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/auth_store.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/bus_simulator.dart';
import '../../services/favorites_store.dart';
import '../../services/nearby.dart';
import '../../widgets/ios.dart';
import '../../widgets/recharge_widgets.dart';
import '../../widgets/stop_widgets.dart';
import 'common.dart';
import 'sheet_nav.dart';

SheetContent buildHomeSheet(BuildContext context, SheetNav nav) {
  final query = nav.search.text.trim().toLowerCase();
  return SheetContent(
    headerHeight: 60,
    header: _SearchHeader(nav: nav),
    body: query.isEmpty
        ? _homeBody(context, nav)
        : _searchResults(context, nav, query),
  );
}

class _SearchHeader extends StatelessWidget {
  final SheetNav nav;

  const _SearchHeader({required this.nav});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: nav.search,
              focusNode: nav.searchFocus,
              placeholder: 'Buscar linhas e pontos',
              backgroundColor: ios.fill,
              style: Theme.of(context).textTheme.bodyLarge,
              placeholderStyle: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ios.secondaryLabel),
              itemColor: ios.secondaryLabel,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: nav.openSettings,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFA1A1AA), Color(0xFF71717A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Text(
                AuthStore.instance.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _homeBody(BuildContext context, SheetNav nav) {
  final sim = BusSimulator.instance;
  final favs = FavoritesStore.instance;
  final nearby = stopsByDistance();
  final alertLines = MockData.lines.where((l) => l.alert != null);

  return [
    for (final line in alertLines)
      ServiceAlertCard(line.id, onTap: () => nav.push(LinePage(line.id))),
    const SizedBox(height: 12),
    NearestStopCard(onOpen: () => nav.push(StopPage(nearby.first.stop.id))),
    SectionHeader('Pontos perto de você'),
    InsetGroup(
      separatorIndent: 58,
      children: [
        for (final near in nearby.skip(1).take(4))
          StopListRow(
            near: near,
            favorite: favs.hasStop(near.stop.id),
            onTap: () => nav.push(StopPage(near.stop.id)),
          ),
      ],
    ),
    SectionHeader('Recarga do passe'),
    InsetGroup(
      separatorIndent: 58,
      children: [
        for (final n in rechargeByDistance().take(2))
          RechargeRow(near: n, onTap: () => nav.push(RechargePage(n.point.id))),
        IosRow(
          leading: const IconTile(CupertinoIcons.map_fill, AppColors.gray),
          title: 'Ver todos os pontos de recarga',
          chevron: true,
          onTap: () => nav.push(const RechargeListPage()),
        ),
      ],
    ),
    SectionHeader('Linhas'),
    InsetGroup(
      separatorIndent: 74,
      children: [
        for (final line in MockData.lines)
          IosRow(
            leading: SizedBox(width: 46, child: LineBadge(line)),
            title: line.name,
            subtitle:
                '${sim.busesOf(line.id).length} ônibus · a cada ~${line.headwayMinutes} min',
            chevron: true,
            onTap: () => nav.push(LinePage(line.id)),
          ),
      ],
    ),
    const SizedBox(height: 32),
  ];
}

List<Widget> _searchResults(BuildContext context, SheetNav nav, String q) {
  final ios = IosColors.of(context);
  final lines = MockData.lines.where(
    (l) => l.number.contains(q) || l.name.toLowerCase().contains(q),
  );
  final stops = MockData.stops.where(
    (s) =>
        s.name.toLowerCase().contains(q) || s.address.toLowerCase().contains(q),
  );
  if (lines.isEmpty && stops.isEmpty) {
    return [
      const SizedBox(height: 40),
      Icon(CupertinoIcons.search, size: 40, color: ios.tertiaryLabel),
      const SizedBox(height: 8),
      Text(
        'Nenhum resultado para "$q"',
        textAlign: TextAlign.center,
        style: TextStyle(color: ios.secondaryLabel),
      ),
    ];
  }
  final favs = FavoritesStore.instance;
  return [
    if (lines.isNotEmpty) ...[
      SectionHeader('Linhas'),
      InsetGroup(
        separatorIndent: 74,
        children: [
          for (final line in lines)
            IosRow(
              leading: SizedBox(width: 46, child: LineBadge(line)),
              title: line.name,
              trailing: _StarButton(
                active: favs.hasLine(line.id),
                onTap: () => favs.toggleLine(line.id),
              ),
              onTap: () => nav.push(LinePage(line.id)),
            ),
        ],
      ),
    ],
    if (stops.isNotEmpty) ...[
      SectionHeader('Pontos'),
      InsetGroup(
        separatorIndent: 58,
        children: [
          for (final stop in stops)
            IosRow(
              leading: const IconTile(CupertinoIcons.bus, AppColors.gray),
              title: stop.name,
              subtitle: stop.address,
              trailing: _StarButton(
                active: favs.hasStop(stop.id),
                onTap: () => favs.toggleStop(stop.id),
              ),
              onTap: () => nav.push(StopPage(stop.id)),
            ),
        ],
      ),
    ],
    const SizedBox(height: 32),
  ];
}

class _StarButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _StarButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          active ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: 20,
          color: active
              ? AppColors.orange
              : IosColors.of(context).tertiaryLabel,
        ),
      ),
    );
  }
}
