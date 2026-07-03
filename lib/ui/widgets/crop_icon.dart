import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models.dart';

/// カスタム描画するcropIdの集合（それ以外は絵文字にフォールバック）。
const _painted = {
  'taro',
  'okra',
  'kuwamame',
  'moroheiya',
  'akajiso',
  'aojiso',
  'negi',
  'kyonegi',
  'nira',
};

Offset _quadPoint(Offset a, Offset b, Offset e, double t) => Offset(
      (1 - t) * (1 - t) * a.dx + 2 * (1 - t) * t * b.dx + t * t * e.dx,
      (1 - t) * (1 - t) * a.dy + 2 * (1 - t) * t * b.dy + t * t * e.dy,
    );

Offset _quadTangent(Offset a, Offset b, Offset e, double t) => Offset(
      2 * (1 - t) * (b.dx - a.dx) + 2 * t * (e.dx - b.dx),
      2 * (1 - t) * (b.dy - a.dy) + 2 * t * (e.dy - b.dy),
    );

/// 2次ベジェ曲線(base→ctrl→tip)に沿って幅がbaseW→tipWに変化する帯状パス。
/// t0〜t1の区間だけ切り出せるので、葉の根元だけ白く塗る等に使える。
Path _taperedSegment(
  Offset base,
  Offset ctrl,
  Offset tip,
  double baseW,
  double tipW,
  double k, {
  double t0 = 0,
  double t1 = 1,
  int samples = 10,
}) {
  double widthAt(double t) => baseW + (tipW - baseW) * t;
  final leftPts = <Offset>[];
  final rightPts = <Offset>[];
  for (var i = 0; i <= samples; i++) {
    final t = t0 + (t1 - t0) * (i / samples);
    final pt = _quadPoint(base, ctrl, tip, t);
    final tan = _quadTangent(base, ctrl, tip, t);
    final len = math.sqrt(tan.dx * tan.dx + tan.dy * tan.dy);
    final n =
        len == 0 ? const Offset(0, 0) : Offset(-tan.dy / len, tan.dx / len);
    final w = widthAt(t);
    leftPts.add(pt + n * w);
    rightPts.add(pt - n * w);
  }
  final p = Path()..moveTo(leftPts.first.dx * k, leftPts.first.dy * k);
  for (final pnt in leftPts.skip(1)) {
    p.lineTo(pnt.dx * k, pnt.dy * k);
  }
  for (final pnt in rightPts.reversed) {
    p.lineTo(pnt.dx * k, pnt.dy * k);
  }
  p.close();
  return p;
}

/// 野菜アイコン。描画対応のものはCustomPaint、未対応は絵文字。
class CropIcon extends StatelessWidget {
  final Crop crop;
  final double size;
  const CropIcon({super.key, required this.crop, required this.size});

  @override
  Widget build(BuildContext context) {
    if (_painted.contains(crop.id)) {
      return CustomPaint(
        size: Size.square(size),
        painter: _CropIconPainter(crop.id, crop.color),
      );
    }
    return Text(crop.icon, style: TextStyle(fontSize: size * 0.66, height: 1.0));
  }
}

class _CropIconPainter extends CustomPainter {
  final String id;
  final Color color;
  _CropIconPainter(this.id, this.color);

  // 48x48 の論理キャンバス。x=24 が左右対称の中心軸。

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 48.0;
    Paint fill(Color col) => Paint()
      ..color = col
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    Paint line(Color col, double w) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final dark = Color.lerp(color, Colors.black, 0.32)!;
    Offset o(double x, double y) => Offset(x * k, y * k);

    switch (id) {
      case 'taro': // 里芋: 茶色い卵形の芋（横縞）を1個、中央に大きく
        {
          final strokeCol = Color.lerp(color, Colors.black, 0.5)!;
          final stripeCol =
              Color.lerp(color, Colors.black, 0.3)!.withValues(alpha: 0.55);

          double d(double v) => v * k;
          final p = Path()
            ..moveTo(d(24), d(5))
            ..cubicTo(d(31), d(6.5), d(38), d(13), d(39), d(24))
            ..cubicTo(d(40), d(35), d(33), d(43), d(24), d(46))
            ..cubicTo(d(15), d(43), d(8), d(35), d(9), d(24))
            ..cubicTo(d(10), d(13), d(17), d(6.5), d(24), d(5))
            ..close();

          c.drawPath(p, fill(color));
          c.save();
          c.clipPath(p);
          for (var i = 0; i < 5; i++) {
            final y = 9.0 + i * 7.5;
            final wp = Path()
              ..moveTo(4 * k, y * k)
              ..quadraticBezierTo(14 * k, (y - 3.2) * k, 24 * k, y * k)
              ..quadraticBezierTo(34 * k, (y + 3.2) * k, 44 * k, y * k);
            c.drawPath(wp, line(stripeCol, 2.4));
          }
          c.restore();
          c.drawPath(p, line(strokeCol, 1.8));
        }
        break;

      case 'moroheiya': // モロヘイヤ: 尖った葉が束になったブーケ状
        {
          final vein = Color.lerp(color, Colors.white, 0.55)!;
          final stemCol = Color.lerp(color, Colors.white, 0.35)!;

          void leaf(double len, double halfW) {
            final p = Path()
              ..moveTo(0, 0)
              ..cubicTo(-halfW * k, -len * k * 0.25, -halfW * 0.9 * k,
                  -len * k * 0.7, 0, -len * k)
              ..cubicTo(halfW * 0.9 * k, -len * k * 0.7, halfW * k,
                  -len * k * 0.25, 0, 0)
              ..close();
            c.drawPath(p, fill(color));
            c.drawLine(Offset(0, -2 * k), Offset(0, -len * k * 0.92),
                line(vein, 1.1));
            for (final t in [0.32, 0.55, 0.75]) {
              final y = -len * k * t;
              c.drawLine(Offset(0, y), Offset(-halfW * k * 0.55 * (1 - t + 0.3), y - 2 * k),
                  line(vein, 0.9));
              c.drawLine(Offset(0, y), Offset(halfW * k * 0.55 * (1 - t + 0.3), y - 2 * k),
                  line(vein, 0.9));
            }
          }

          // (角度, 長さ, 半幅, 手前寄りに描く順)
          const leaves = [
            [-40.0, 20.0, 6.5],
            [-22.0, 26.0, 7.5],
            [-6.0, 29.0, 8.0],
            [10.0, 27.0, 7.5],
            [26.0, 23.0, 7.0],
            [42.0, 17.0, 6.0],
          ];
          final base = o(24, 42);
          for (final leafDef in leaves) {
            c.save();
            c.translate(base.dx, base.dy);
            c.rotate(leafDef[0] * math.pi / 180);
            leaf(leafDef[1], leafDef[2]);
            c.restore();
          }

          // 茎（束になって根元に集まる）
          for (final dx in [-2.0, 0.0, 2.5]) {
            final p = Path()
              ..moveTo(base.dx + dx * k, base.dy)
              ..quadraticBezierTo(o(24, 45).dx, o(24, 45).dy, o(24, 47).dx,
                  o(24, 47).dy);
            c.drawPath(p, line(stemCol, 1.6));
          }
        }
        break;

      case 'akajiso': // 赤しそ・青じそ: 滑らかなベジェ曲線の葉形＋細かい鋸歯＋脈
      case 'aojiso':
        {
          const topY = 5.0, baseY = 44.0;
          const p0 = Offset(24, topY); // 先端
          const p1 = Offset(40, 11); // 右肩の制御点
          const p2 = Offset(42, 33); // 右下の制御点
          const p3 = Offset(24, baseY); // 根元
          const toothCount = 14.0, toothDepth = 2.3;

          Offset cubic(double t) {
            final mt = 1 - t;
            final a = mt * mt * mt,
                b = 3 * mt * mt * t,
                cc = 3 * mt * t * t,
                d = t * t * t;
            return Offset(
              a * p0.dx + b * p1.dx + cc * p2.dx + d * p3.dx,
              a * p0.dy + b * p1.dy + cc * p2.dy + d * p3.dy,
            );
          }

          const samples = 100;
          final rightPts = <Offset>[];
          for (var i = 0; i <= samples; i++) {
            final t = i / samples;
            final basePt = cubic(t);
            final phase = (t * toothCount) % 1.0;
            final tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            final fade = math.sin(math.pi * t.clamp(0.0001, 0.9999));
            rightPts.add(
                Offset(basePt.dx + toothDepth * fade * tri, basePt.dy));
          }

          final p = Path()..moveTo(rightPts.first.dx * k, rightPts.first.dy * k);
          for (final pt in rightPts.skip(1)) {
            p.lineTo(pt.dx * k, pt.dy * k);
          }
          for (var i = rightPts.length - 2; i >= 0; i--) {
            final pt = rightPts[i];
            p.lineTo((48 - pt.dx) * k, pt.dy * k);
          }
          p.close();

          c.drawPath(p, fill(color));
          c.drawPath(p, line(dark, 1.4));

          // 主脈（先端近くでU字に分かれてから根元へ）
          final vein = Color.lerp(color, Colors.white, 0.55)!;
          final uTop = topY + (baseY - topY) * 0.12;
          final uPath = Path()
            ..moveTo((24 - 2.2) * k, uTop * k)
            ..quadraticBezierTo(
                (24 - 2.4) * k, (uTop + 5) * k, 24 * k, (uTop + 7) * k)
            ..quadraticBezierTo(
                (24 + 2.4) * k, (uTop + 5) * k, (24 + 2.2) * k, uTop * k);
          c.drawPath(uPath, line(vein, 1.1));
          c.drawLine(Offset(24 * k, (uTop + 6) * k), Offset(24 * k, (baseY - 1) * k),
              line(vein, 1.3));

          // 茎
          final stemCol = Color.lerp(vein, color, 0.3)!;
          final stemPath = Path()
            ..moveTo(24 * k, baseY * k)
            ..quadraticBezierTo(
                (24 + 1.4) * k, (baseY + 3) * k, (24 + 1) * k, (baseY + 5) * k);
          c.drawPath(stemPath, line(stemCol, 1.8));

          // 側脈（左右7対）
          for (final t in [0.24, 0.34, 0.44, 0.54, 0.64, 0.74, 0.84]) {
            final basePt = cubic(t);
            final r = (basePt.dx - 24) * 0.7;
            final y = basePt.dy;
            c.drawLine(Offset(24 * k, y * k), Offset((24 - r) * k, (y + 2.6) * k),
                line(vein, 1.0));
            c.drawLine(Offset(24 * k, y * k), Offset((24 + r) * k, (y + 2.6) * k),
                line(vein, 1.0));
          }
        }
        break;

      case 'okra': // オクラ: 斜め構図の先細りポッド＋ヘタ＋ハイライト帯
        {
          const outlineCol = Color(0xFF3A3A38);
          final tip = const Offset(9, 43);
          final ctrl = const Offset(16, 24);
          final base = const Offset(30, 12);

          Offset quad(Offset a, Offset b, Offset e, double t) => Offset(
                (1 - t) * (1 - t) * a.dx + 2 * (1 - t) * t * b.dx + t * t * e.dx,
                (1 - t) * (1 - t) * a.dy + 2 * (1 - t) * t * b.dy + t * t * e.dy,
              );
          Offset quadTangent(Offset a, Offset b, Offset e, double t) => Offset(
                2 * (1 - t) * (b.dx - a.dx) + 2 * t * (e.dx - b.dx),
                2 * (1 - t) * (b.dy - a.dy) + 2 * t * (e.dy - b.dy),
              );
          double widthAt(double t) {
            const maxW = 7.5;
            if (t < 0.72) {
              return maxW * math.sin((t / 0.72) * math.pi / 2);
            }
            return maxW * (1 - 0.2 * ((t - 0.72) / 0.28));
          }

          const samples = 16;
          final leftPts = <Offset>[];
          final rightPts = <Offset>[];
          for (var i = 0; i <= samples; i++) {
            final t = i / samples;
            final pt = quad(tip, ctrl, base, t);
            final tan = quadTangent(tip, ctrl, base, t);
            final len = math.sqrt(tan.dx * tan.dx + tan.dy * tan.dy);
            final n = len == 0
                ? const Offset(0, 0)
                : Offset(-tan.dy / len, tan.dx / len);
            final w = widthAt(t);
            leftPts.add(pt + n * w);
            rightPts.add(pt - n * w);
          }
          final pod = Path()..moveTo(leftPts.first.dx * k, leftPts.first.dy * k);
          for (final p in leftPts.skip(1)) {
            pod.lineTo(p.dx * k, p.dy * k);
          }
          for (final p in rightPts.reversed) {
            pod.lineTo(p.dx * k, p.dy * k);
          }
          pod.close();

          c.drawPath(pod, fill(color));

          // ハイライト帯（上側の縁沿い）
          c.save();
          c.clipPath(pod);
          final hi = Color.lerp(color, Colors.white, 0.38)!;
          final hiPath = Path();
          for (var i = 0; i <= samples; i++) {
            final t = i / samples;
            final pt = quad(tip, ctrl, base, t);
            final tan = quadTangent(tip, ctrl, base, t);
            final len = math.sqrt(tan.dx * tan.dx + tan.dy * tan.dy);
            final n = len == 0
                ? const Offset(0, 0)
                : Offset(-tan.dy / len, tan.dx / len);
            final hp = pt + n * (widthAt(t) * 0.32);
            if (i == 0) {
              hiPath.moveTo(hp.dx * k, hp.dy * k);
            } else {
              hiPath.lineTo(hp.dx * k, hp.dy * k);
            }
          }
          c.drawPath(hiPath, line(hi, 3.0));
          c.restore();

          c.drawPath(pod, line(outlineCol, 2.0));

          // ヘタ（先端の2つの突起）
          final capDark = Color.lerp(color, Colors.black, 0.28)!;
          final cap = Path()
            ..moveTo(27 * k, 14 * k)
            ..cubicTo(27 * k, 9 * k, 29 * k, 5 * k, 30 * k, 6 * k)
            ..cubicTo(31 * k, 8 * k, 31 * k, 10 * k, 33 * k, 8 * k)
            ..cubicTo(35 * k, 6 * k, 37 * k, 8 * k, 36 * k, 11 * k)
            ..cubicTo(35 * k, 14 * k, 33 * k, 15 * k, 33 * k, 15 * k)
            ..cubicTo(31 * k, 16 * k, 28 * k, 16 * k, 27 * k, 14 * k)
            ..close();
          c.drawPath(cap, fill(capDark));
          c.drawPath(cap, line(outlineCol, 1.6));
        }
        break;

      case 'kuwamame': // 桑の木豆: 豆のさや＋豆
        {
          final pod = Path()
            ..moveTo(13 * k, 14 * k)
            ..quadraticBezierTo(28 * k, 20 * k, 33 * k, 38 * k);
          c.drawPath(pod, line(color, 10)..strokeCap = StrokeCap.round);
          for (final t in [0.25, 0.5, 0.75]) {
            final x = 13 + (33 - 13) * t;
            final y = 14 + (38 - 14) * (t * t * 0.6 + t * 0.4);
            c.drawCircle(o(x, y), 2.6 * k, fill(dark.withValues(alpha: 0.55)));
          }
        }
        break;

      case 'negi': // ネギ: 太い白い茎（斜め）＋先端の緑の葉の房、根元は切り口
        {
          const outlineCol = Color(0xFF3A2818);
          const whiteCol = Color(0xFFFAF8EE);
          const cutCol = Color(0xFFC79A6B);
          final yellowGreen = Color.lerp(whiteCol, color, 0.55)!;

          const base1 = Offset(9, 44);
          const neck1 = Offset(29, 21);
          const base2 = Offset(15, 45);
          const neck2 = Offset(33, 23);
          final ctrl1 = Offset.lerp(base1, neck1, 0.5)!;
          final ctrl2 = Offset.lerp(base2, neck2, 0.5)!;

          // 奥側の茎（少し細め・後ろに描く）
          final outline2 = _taperedSegment(base2, ctrl2, neck2, 4.4, 3.2, k);
          c.drawPath(outline2, fill(outlineCol));
          final inner2 = _taperedSegment(base2, ctrl2, neck2, 3.6, 2.6, k);
          c.drawPath(inner2, fill(whiteCol));

          // 手前の茎（太め）
          final outline1 = _taperedSegment(base1, ctrl1, neck1, 6.0, 4.4, k);
          c.drawPath(outline1, fill(outlineCol));
          final inner1 = _taperedSegment(base1, ctrl1, neck1, 5.2, 3.7, k);
          c.drawPath(inner1, fill(whiteCol));

          // 切り口
          final cutCenter = o(base1.dx, base1.dy);
          final cutOval =
              Rect.fromCenter(center: cutCenter, width: 6 * k, height: 4.2 * k);
          c.drawOval(cutOval, fill(cutCol));
          c.drawOval(cutOval, line(outlineCol, 1.2));

          // 茎の縦線（質感）
          final vLineA = _quadPoint(base1, ctrl1, neck1, 0.15) * k;
          final vLineB = _quadPoint(base1, ctrl1, neck1, 0.75) * k;
          c.drawLine(vLineA, vLineB, line(outlineCol.withValues(alpha: 0.45), 0.9));

          // 葉（緑）が先端で扇状に広がる
          final neckCenter = Offset.lerp(neck1, neck2, 0.5)!;
          c.drawCircle(o(neckCenter.dx, neckCenter.dy), 4.5 * k, fill(yellowGreen));

          final tips = [
            const Offset(26, 6),
            const Offset(32, 4),
            const Offset(38, 7),
            const Offset(42, 13),
            const Offset(45, 19),
          ];
          for (final tip in tips) {
            final ctrl = Offset.lerp(neckCenter, tip, 0.5)!;
            final leafOutline =
                _taperedSegment(neckCenter, ctrl, tip, 2.6, 0.7, k);
            c.drawPath(leafOutline, fill(outlineCol));
            final leafInner =
                _taperedSegment(neckCenter, ctrl, tip, 2.0, 0.4, k);
            c.drawPath(leafInner, fill(color));
          }
        }
        break;

      case 'kyonegi': // 九条ネギ: 先端が細く尖った葉が根元から斜めに扇状に広がる
        {
          const outlineCol = Color(0xFF6B4A2C);
          const paleBase = Color(0xFFF3F1DE);
          final veinCol = Color.lerp(color, Colors.black, 0.35)!;

          const base = Offset(11, 41);
          final tips = [
            const Offset(23, 8),
            const Offset(29, 5),
            const Offset(35, 6),
            const Offset(40, 11),
            const Offset(44, 19),
          ];

          // 根元のまとまり
          final baseOval =
              Rect.fromCenter(center: o(11, 41), width: 10 * k, height: 7 * k);
          c.drawOval(baseOval, fill(paleBase));
          c.drawOval(baseOval, line(outlineCol, 1.4));

          for (final tip in tips) {
            final ctrl = Offset.lerp(base, tip, 0.5)!;
            final outline = _taperedSegment(base, ctrl, tip, 2.6, 0.15, k);
            c.drawPath(outline, fill(outlineCol));
            final inner = _taperedSegment(base, ctrl, tip, 1.9, 0.05, k);
            c.drawPath(inner, fill(color));
            final white = _taperedSegment(base, ctrl, tip, 1.9, 0.05, k,
                t0: 0, t1: 0.3);
            c.drawPath(white, fill(paleBase));
            final veinStart = _quadPoint(base, ctrl, tip, 0.38) * k;
            final veinEnd = _quadPoint(base, ctrl, tip, 0.94) * k;
            c.drawLine(veinStart, veinEnd, line(veinCol, 1.0));
          }
        }
        break;

      case 'nira': // にら: 扁平な葉が根元から扇状に広がる
        {
          final origin = o(24, 44);
          final angles = [-28.0, -13.0, 0.0, 13.0, 28.0];
          for (final deg in angles) {
            c.save();
            c.translate(origin.dx, origin.dy);
            c.rotate(deg * math.pi / 180);
            final blade = Path()
              ..moveTo(-1.8 * k, 0)
              ..quadraticBezierTo(-2.6 * k, -18 * k, 0, -34 * k)
              ..quadraticBezierTo(2.6 * k, -18 * k, 1.8 * k, 0)
              ..close();
            c.drawPath(blade, fill(color.withValues(alpha: 0.92)));
            c.restore();
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CropIconPainter old) =>
      old.id != id || old.color != color;
}
