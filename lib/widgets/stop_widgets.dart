import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../models/bus_stop.dart';
import '../services/bus_simulator.dart';
import '../services/nearby.dart';
import 'ios.dart';

/// Line badges with the next arrival of each, for a stop.
class LineEtaChips extends StatelessWidget {
  final BusStop stop;

  const LineEtaChips(this.stop, {super.key});

  @override
  Widget build(BuildContext context) {
    final sim = BusSimulator.instance;
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final lineId in stop.lineIds)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LineBadge(MockData.line(lineId), height: 20),
              const SizedBox(width: 5),
              EtaLabel(sim.eta(lineId, stop.id), fontSize: 13),
            ],
          ),
      ],
    );
  }
}

/// "Ponto mais próximo" card: where it is, how far to walk, which buses
/// stop there and when they arrive.
class NearestStopCard extends StatelessWidget {
  final VoidCallback onOpen;

  const NearestStopCard({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;
    final near = nearestStop();
    final sim = BusSimulator.instance;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: ios.cell,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  IconTile(Icons.directions_walk_rounded, ios.tint, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PONTO MAIS PRÓXIMO',
                          style: text.labelSmall?.copyWith(
                            color: ios.tint,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          near.stop.name,
                          style: text.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${near.distanceLabel} · ${near.walkLabel} · ${near.stop.address}',
                          style: text.bodySmall?.copyWith(
                            color: ios.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: ios.tertiaryLabel,
                  ),
                ],
              ),
            ),
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 14),
              color: ios.separator,
            ),
            for (final lineId in near.stop.lineIds)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      child: LineBadge(MockData.line(lineId)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        MockData.line(lineId).name,
                        style: text.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    EtaLabel(sim.eta(lineId, near.stop.id), fontSize: 15),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Row for a stop in lists: name, distance, and the lines that serve it
/// with their next arrival.
class StopListRow extends StatelessWidget {
  final NearbyStop near;
  final bool isNearest;
  final bool favorite;
  final bool chevron;
  final VoidCallback onTap;

  const StopListRow({
    super.key,
    required this.near,
    required this.onTap,
    this.isNearest = false,
    this.favorite = false,
    this.chevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              CupertinoIcons.bus,
              isNearest ? ios.tint : AppColors.gray,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          near.stop.name,
                          style: text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (near.stop.accessible) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.accessible_rounded,
                          size: 15,
                          color: AppColors.blue,
                          semanticLabel: 'Ponto acessível',
                        ),
                      ],
                      if (favorite) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.star_fill,
                          size: 13,
                          color: AppColors.orange,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${near.stop.address} · ${near.distanceLabel} · ${near.walkLabel}',
                    style: text.bodySmall?.copyWith(color: ios.secondaryLabel),
                  ),
                  const SizedBox(height: 8),
                  LineEtaChips(near.stop),
                ],
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: ios.tertiaryLabel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
