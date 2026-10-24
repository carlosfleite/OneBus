import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

typedef _Ad = ({
  String brand,
  String text,
  String cta,
  IconData icon,
  Color color,
});

const _ads = <_Ad>[
  (
    brand: 'Pão & Cia',
    text: 'Café + pão na chapa por R\$ 8. Só até as 10h!',
    cta: 'Ver oferta',
    icon: Icons.bakery_dining_rounded,
    color: Color(0xFFB4690E),
  ),
  (
    brand: 'Academia Pulso',
    text: 'Primeira semana grátis para quem anda de ônibus.',
    cta: 'Quero',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFF5856D6),
  ),
  (
    brand: 'Sorvetes Gelato',
    text: 'Dois picolés pelo preço de um na volta pra casa.',
    cta: 'Aproveitar',
    icon: Icons.icecream_rounded,
    color: Color(0xFFD6336C),
  ),
  (
    brand: 'Inglês Express',
    text: 'Aulas de 20 min para fazer no trajeto.',
    cta: 'Testar',
    icon: Icons.translate_rounded,
    color: Color(0xFF1E9E50),
  ),
];

/// Placeholder ad. Shown inline in the lists of Início and Passe, never on
/// the map or on the pages where you are catching a bus, so it can't get in
/// the way of tracking. Picks a random fictional ad each time it appears.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final _ad = _ads[math.Random().nextInt(_ads.length)];

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Anúncio: ${_ad.brand}. ${_ad.text}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ios.cell,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _ad.color,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_ad.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: ios.fill,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Anúncio',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ios.secondaryLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _ad.brand,
                          style: text.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ad.text,
                    style: text.bodySmall?.copyWith(color: ios.secondaryLabel),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _ad.cta,
              style: TextStyle(
                color: ios.tint,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
