import 'package:flutter/material.dart';

/// 野菜マスタ。グリッド表示用の色とアイコンを持つ。
class Crop {
  final String id;
  final String name;
  final Color color;
  final String icon;
  const Crop({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  /// セル背景用に白と混ぜて薄くした色。
  Color get soft => Color.lerp(color, Colors.white, 0.4)!;
}

/// 作付けのサンプル情報（いつ・どのように）。
class PlantingInfo {
  final String date;
  final String method;
  const PlantingInfo({required this.date, required this.method});
}

/// 区画内で1作物が占める矩形範囲（列・行はどちらも両端含む）。
class Block {
  final String cropId;
  final int c0;
  final int c1;
  final int r0;
  final int r1;
  const Block(
    this.cropId, {
    required this.c0,
    required this.c1,
    required this.r0,
    required this.r1,
  });
}

/// 区画。50cm/マスのグリッド。セルは row-major（index = r*cols + c）で保持。
/// 座標系は 列(c)=左0〜右 / 行(r)=奥0〜手前(rows-1)。
class Plot {
  final String id;
  final String name;
  final int cols;
  final int rows;

  /// 各マスの作物ID。空きは null。長さ = cols*rows。
  final List<String?> cells;

  const Plot({
    required this.id,
    required this.name,
    required this.cols,
    required this.rows,
    required this.cells,
  });

  factory Plot.empty({
    required String id,
    required String name,
    required int cols,
    required int rows,
  }) =>
      Plot(
        id: id,
        name: name,
        cols: cols,
        rows: rows,
        cells: List<String?>.filled(cols * rows, null),
      );

  factory Plot.fromBlocks({
    required String id,
    required String name,
    required int cols,
    required int rows,
    required List<Block> blocks,
  }) {
    final cells = List<String?>.filled(cols * rows, null);
    for (final b in blocks) {
      for (var r = b.r0; r <= b.r1; r++) {
        for (var c = b.c0; c <= b.c1; c++) {
          cells[r * cols + c] = b.cropId;
        }
      }
    }
    return Plot(id: id, name: name, cols: cols, rows: rows, cells: cells);
  }

  String? at(int c, int r) => cells[r * cols + c];

  /// 例: 12×12 → "6×6m"（1マス50cm）。
  String get sizeLabel {
    String f(int v) {
      final m = v * 0.5;
      return m == m.roundToDouble() ? m.toInt().toString() : m.toString();
    }

    return '${f(cols)}×${f(rows)}m';
  }

  List<List<String?>> buildMatrix() => List.generate(
        rows,
        (r) => List.generate(cols, (c) => cells[r * cols + c]),
      );

  Plot copyWith({String? name, int? cols, int? rows, List<String?>? cells}) =>
      Plot(
        id: id,
        name: name ?? this.name,
        cols: cols ?? this.cols,
        rows: rows ?? this.rows,
        cells: cells ?? this.cells,
      );

  /// 1マスを塗り替えた新しいPlotを返す（不変更新）。
  Plot withCell(int c, int r, String? cropId) {
    final next = List<String?>.of(cells);
    next[r * cols + c] = cropId;
    return copyWith(cells: next);
  }

  /// 行列サイズを変更。重なる範囲の作付けは引き継ぐ。
  Plot resized(int newCols, int newRows) {
    final next = List<String?>.filled(newCols * newRows, null);
    for (var r = 0; r < rows && r < newRows; r++) {
      for (var c = 0; c < cols && c < newCols; c++) {
        next[r * newCols + c] = cells[r * cols + c];
      }
    }
    return copyWith(cols: newCols, rows: newRows, cells: next);
  }
}

/// タップされたマスの選択状態。
class CellSelection {
  final int c;
  final int r;
  final String? cropId;
  const CellSelection(this.c, this.r, this.cropId);
}

/// 作業イベントの種別（あらかじめ決められたもの）。
enum CropEventType {
  seeding('タネ植', Icons.spa, Color(0xFF7CAE4A)),
  seedling('苗植', Icons.local_florist, Color(0xFF5AA469)),
  transplant('植え替え', Icons.swap_horiz, Color(0xFF4C9AA0)),
  lime('石灰', Icons.grain, Color(0xFF8A8F98)),
  fertilize('肥料', Icons.compost, Color(0xFF9C7A3A)),
  topdress('追肥', Icons.add_circle_outline, Color(0xFFC29A3A)),
  hilling('土寄せ', Icons.terrain, Color(0xFF9C7A4E)),
  prune('剪定', Icons.content_cut, Color(0xFF6B8E9C)),
  thin('間引', Icons.filter_alt_outlined, Color(0xFF8A9A5B)),
  harvest('収穫', Icons.agriculture, Color(0xFFD98B2B));

  final String label;
  final IconData icon;
  final Color color;
  const CropEventType(this.label, this.icon, this.color);
}

/// 区画×野菜の作付けに紐づく作業イベント。予定日を持ち、実施したら実施日が入る。
class CropEvent {
  final String id;
  final String plotId;
  final String cropId;
  final CropEventType type;
  final DateTime plannedDate;
  final DateTime? doneDate;
  final String note;

  const CropEvent({
    required this.id,
    required this.plotId,
    required this.cropId,
    required this.type,
    required this.plannedDate,
    this.doneDate,
    this.note = '',
  });

  bool get isDone => doneDate != null;

  CropEvent copyWith({
    DateTime? plannedDate,
    DateTime? doneDate,
    bool clearDone = false,
    String? note,
  }) =>
      CropEvent(
        id: id,
        plotId: plotId,
        cropId: cropId,
        type: type,
        plannedDate: plannedDate ?? this.plannedDate,
        doneDate: clearDone ? null : (doneDate ?? this.doneDate),
        note: note ?? this.note,
      );
}

/// 作付け（区画×野菜）を指す軽量キー。
typedef PlantingKey = ({String plotId, String cropId});

/// 1日ぶんの天気予報。
class DailyWeather {
  final DateTime date;
  final int weatherCode; // WMO weather code
  final double tempMax;
  final double tempMin;
  final int precipProbability; // %

  const DailyWeather({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precipProbability,
  });
}
