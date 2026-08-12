import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// The Connect emblem: a small network of linked nodes on a brand-gradient tile.
///
/// Painted rather than shipped as an asset so it stays crisp at any size and
/// can be tinted per surface. Wrapped in a [Hero] so it flies between the login
/// and signup screens instead of popping.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.heroTag = 'brand-mark'});

  final double size;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final Widget tile = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.brandBright, AppColors.brand],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandDeep.withValues(alpha: 0.45),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.24),
        child: CustomPaint(painter: _NetworkGlyphPainter()),
      ),
    );

    if (heroTag == null) return tile;
    return Hero(
      tag: heroTag!,
      // Keep the tile square through the flight; the default rect tween can
      // otherwise letterbox the gradient mid-transition.
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection direction,
        BuildContext fromContext,
        BuildContext toContext,
      ) {
        return FittedBox(fit: BoxFit.contain, child: tile);
      },
      child: tile,
    );
  }
}

class _NetworkGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> nodes = <Offset>[
      Offset(size.width * 0.5, size.height * 0.08),
      Offset(size.width * 0.08, size.height * 0.82),
      Offset(size.width * 0.92, size.height * 0.82),
    ];

    final Paint edge = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        canvas.drawLine(nodes[i], nodes[j], edge);
      }
    }

    final Paint node = Paint()..color = Colors.white;
    final Paint crown = Paint()..color = AppColors.accentBright;

    for (int i = 0; i < nodes.length; i++) {
      // The apex node carries the accent colour so the mark has a focal point.
      canvas.drawCircle(
        nodes[i],
        size.shortestSide * (i == 0 ? 0.17 : 0.14),
        i == 0 ? crown : node,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkGlyphPainter oldDelegate) => false;
}

/// Wordmark used beside or beneath [BrandMark].
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.color, this.fontSize = 26});

  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: color ?? Theme.of(context).colorScheme.onSurface,
          height: 1.1,
        ),
        children: const <TextSpan>[
          TextSpan(text: 'Connect'),
          TextSpan(
            text: '.',
            style: TextStyle(color: AppColors.accentBright),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase label used under the wordmark on the auth header.
class BrandTagline extends StatelessWidget {
  const BrandTagline({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'FOR SERVING OFFICIALS',
      style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
          .copyWith(
        color: color ?? AppColors.accentBright,
        letterSpacing: 2.4,
        fontSize: 10.5,
      ),
    );
  }
}

/// Spacing helper kept here so the emblem block reads as one unit at call sites.
const double kBrandBlockGap = AppSpacing.md;
