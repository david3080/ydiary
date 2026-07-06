import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../data/firestore_repo.dart';
import '../data/seed_data.dart';
import '../data/weather_api.dart';

// --- データ源 ---
final plantingInfoProvider =
    Provider<Map<String, PlantingInfo>>((ref) => kPlantings);

/// 野菜マスタ（名前・色・絵文字）。Firestore(crops)と同期する。
/// 追加・編集・削除は即Firestoreに書き込み、スナップショット購読が state を更新する。
/// カスタム描画アイコン（里芋・オクラ等）はcrop.idが一致すれば自動的に使われる。
class CropsNotifier extends Notifier<Map<String, Crop>> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  Map<String, Crop> build() {
    ref.onDispose(() => _sub?.cancel());
    if (Firebase.apps.isNotEmpty) {
      _sub = FirestorePaths.crops.snapshots().listen((snap) {
        if (snap.docs.isEmpty) {
          _seedIfEmpty();
          return;
        }
        state = {
          for (final doc in snap.docs) doc.id: cropFromDoc(doc),
        };
      });
    }
    return Map<String, Crop>.of(kCrops);
  }

  Future<void> _seedIfEmpty() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final entry in kCrops.entries) {
      batch.set(FirestorePaths.crops.doc(entry.key), cropToMap(entry.value));
    }
    await batch.commit();
  }

  /// 新規作物を追加し、そのIDを返す。
  String add({required String name, required Color color, required String icon}) {
    final id = 'crop_${DateTime.now().millisecondsSinceEpoch}';
    FirestorePaths.crops
        .doc(id)
        .set(cropToMap(Crop(id: id, name: name, color: color, icon: icon)));
    return id;
  }

  void update(String id, {String? name, Color? color, String? icon}) {
    final current = state[id];
    if (current == null) return;
    final next = Crop(
      id: id,
      name: name ?? current.name,
      color: color ?? current.color,
      icon: icon ?? current.icon,
    );
    FirestorePaths.crops.doc(id).set(cropToMap(next));
  }

  void remove(String id) {
    FirestorePaths.crops.doc(id).delete();
  }
}

final cropsProvider =
    NotifierProvider<CropsNotifier, Map<String, Crop>>(CropsNotifier.new);

/// 区画一覧（可変）。Firestore(users/{uid}/plots)と同期する。
/// 追加・リネーム・リサイズ・マス塗替えは即Firestoreに書き込み、
/// スナップショット購読が state を更新する（ローカルキャッシュ経由でほぼ即時）。
class PlotsNotifier extends Notifier<List<Plot>> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  int _seq = 0;

  @override
  List<Plot> build() {
    // 初回表示はシードを即返し、購読が繋がり次第Firestoreの内容に切り替える。
    ref.onDispose(() => _sub?.cancel());
    // Firebase.apps は未初期化でも例外を投げない安全な判定
    // （try-catchで囲むと本物の実行時エラーまで握りつぶしてしまうため使わない）。
    if (Firebase.apps.isNotEmpty) {
      _sub = FirestorePaths.plots.orderBy('order').snapshots().listen((snap) {
        if (snap.docs.isEmpty) {
          _seedIfEmpty();
          return;
        }
        state = snap.docs.map(plotFromDoc).toList();
      });
    }
    return List<Plot>.of(kPlots);
  }

  Future<void> _seedIfEmpty() async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < kPlots.length; i++) {
      batch.set(FirestorePaths.plots.doc(kPlots[i].id),
          plotToMap(kPlots[i], order: i));
    }
    await batch.commit();
  }

  /// 空の新規区画を末尾に追加し、そのインデックスを返す。
  int addNew({int cols = 8, int rows = 8}) {
    _seq++;
    final plot = Plot.empty(
      id: 'plot_${DateTime.now().millisecondsSinceEpoch}_$_seq',
      name: '区画${state.length + 1}',
      cols: cols,
      rows: rows,
    );
    FirestorePaths.plots
        .doc(plot.id)
        .set(plotToMap(plot, order: state.length));
    return state.length; // 追加後のインデックス（スナップショット反映後の位置）
  }

  void removeAt(int index) {
    FirestorePaths.plots.doc(state[index].id).delete();
  }

  void rename(int index, String name) {
    FirestorePaths.plots.doc(state[index].id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void resize(int index, {int? cols, int? rows}) {
    final p = state[index];
    final next = p.resized(cols ?? p.cols, rows ?? p.rows);
    FirestorePaths.plots.doc(p.id).update({
      'cols': next.cols,
      'rows': next.rows,
      'cells': next.cells,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// マスを塗り替える（cropId=null で空きに）。
  void paintCell(int index, int c, int r, String? cropId) {
    final p = state[index];
    if (p.at(c, r) == cropId) return;
    final next = p.withCell(c, r, cropId);
    FirestorePaths.plots.doc(p.id).update({
      'cells': next.cells,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final plotsProvider =
    NotifierProvider<PlotsNotifier, List<Plot>>(PlotsNotifier.new);

/// エディタで選択中の塗り作物ID（null=消しゴム＝空きにする）。
class PaintCrop extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? cropId) => state = cropId;
}

final paintCropProvider = NotifierProvider<PaintCrop, String?>(PaintCrop.new);

// --- UI状態（Riverpod 3.x の Notifier） ---

/// 選択中の区画インデックス。
class SelectedPlotIndex extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final selectedPlotIndexProvider =
    NotifierProvider<SelectedPlotIndex, int>(SelectedPlotIndex.new);

/// 凡例/セルタップでハイライトする作物ID（null=なし）。
class HighlightedCrop extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? cropId) => state = cropId;
  void toggle(String cropId) => state = state == cropId ? null : cropId;
  void clear() => state = null;
}

final highlightedCropProvider =
    NotifierProvider<HighlightedCrop, String?>(HighlightedCrop.new);

/// 情報カードに表示する選択マス。
class SelectedCell extends Notifier<CellSelection?> {
  @override
  CellSelection? build() => null;
  void select(CellSelection cell) => state = cell;
  void clear() => state = null;
}

final selectedCellProvider =
    NotifierProvider<SelectedCell, CellSelection?>(SelectedCell.new);

// --- 派生状態（UI = f(状態)） ---
final currentPlotProvider = Provider<Plot>((ref) {
  final plots = ref.watch(plotsProvider);
  final i = ref.watch(selectedPlotIndexProvider);
  // 削除直後などで範囲外になっても安全なようにクランプする。
  return plots[i.clamp(0, plots.length - 1)];
});

final currentMatrixProvider = Provider<List<List<String?>>>(
  (ref) => ref.watch(currentPlotProvider).buildMatrix(),
);

/// 作物ID→マス数。
final cropCountsProvider = Provider<Map<String, int>>((ref) {
  final m = ref.watch(currentMatrixProvider);
  final counts = <String, int>{};
  for (final row in m) {
    for (final cell in row) {
      if (cell != null) counts[cell] = (counts[cell] ?? 0) + 1;
    }
  }
  return counts;
});

/// 利用率（0〜100）。
final usageRateProvider = Provider<int>((ref) {
  final plot = ref.watch(currentPlotProvider);
  final counts = ref.watch(cropCountsProvider);
  final used = counts.values.fold<int>(0, (a, b) => a + b);
  final total = plot.cols * plot.rows;
  return total == 0 ? 0 : (used / total * 100).round();
});

/// 区画を切り替えて選択状態をリセットする。
void selectPlot(WidgetRef ref, int index) {
  ref.read(selectedPlotIndexProvider.notifier).select(index);
  ref.read(highlightedCropProvider.notifier).clear();
  ref.read(selectedCellProvider.notifier).clear();
}

/// 凡例（野菜リスト）で野菜を選択/解除する。
/// グリッドのハイライトと、情報カードが見る selectedCell を同期させる。
void toggleCropFocus(WidgetRef ref, String cropId) {
  final current = ref.read(highlightedCropProvider);
  if (current == cropId) {
    ref.read(highlightedCropProvider.notifier).clear();
    ref.read(selectedCellProvider.notifier).clear();
    return;
  }
  ref.read(highlightedCropProvider.notifier).set(cropId);
  // 情報カード用に、その野菜の最初のマスを選択状態にする
  final plot = ref.read(currentPlotProvider);
  for (var r = 0; r < plot.rows; r++) {
    for (var c = 0; c < plot.cols; c++) {
      if (plot.at(c, r) == cropId) {
        ref
            .read(selectedCellProvider.notifier)
            .select(CellSelection(c, r, cropId));
        return;
      }
    }
  }
}

// --- 作業スケジュール（区画×野菜ごとの予定・実績） ---
/// Firestore(users/{uid}/events)と同期する。書き込みは即Firestoreへ、
/// スナップショット購読が state を更新する。
class CropEvents extends Notifier<List<CropEvent>> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  List<CropEvent> build() {
    ref.onDispose(() => _sub?.cancel());
    if (Firebase.apps.isNotEmpty) {
      _sub = FirestorePaths.events.snapshots().listen((snap) {
        if (snap.docs.isEmpty) {
          _seedIfEmpty();
          return;
        }
        state = snap.docs.map(eventFromDoc).toList();
      });
    }
    return List<CropEvent>.of(kSeedEvents);
  }

  Future<void> _seedIfEmpty() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final e in kSeedEvents) {
      batch.set(FirestorePaths.events.doc(e.id), eventToMap(e));
    }
    await batch.commit();
  }

  void add(String plotId, String cropId, CropEventType type, DateTime planned,
      {String note = ''}) {
    final doc = FirestorePaths.events.doc();
    final e = CropEvent(
      id: doc.id,
      plotId: plotId,
      cropId: cropId,
      type: type,
      plannedDate: planned,
      note: note,
    );
    doc.set(eventToMap(e));
  }

  void markDone(String id, DateTime date) {
    FirestorePaths.events.doc(id).update({'doneDate': Timestamp.fromDate(date)});
  }

  void markUndone(String id) {
    FirestorePaths.events.doc(id).update({'doneDate': null});
  }

  void reschedule(String id, DateTime date) {
    FirestorePaths.events
        .doc(id)
        .update({'plannedDate': Timestamp.fromDate(date)});
  }

  void remove(String id) {
    FirestorePaths.events.doc(id).delete();
  }
}

final cropEventsProvider =
    NotifierProvider<CropEvents, List<CropEvent>>(CropEvents.new);

/// 指定した作付け（区画×野菜）のイベントを予定日順で返す。
final eventsForPlantingProvider =
    Provider.family<List<CropEvent>, PlantingKey>((ref, key) {
  final all = ref.watch(cropEventsProvider);
  final list = all
      .where((e) => e.plotId == key.plotId && e.cropId == key.cropId)
      .toList()
    ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
  return list;
});

/// 全イベントを予定日順で返す（暦・ホームの横断表示用）。
final allEventsSortedProvider = Provider<List<CropEvent>>((ref) {
  final all = [...ref.watch(cropEventsProvider)]
    ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
  return all;
});

/// 作付け一覧（区画×野菜の重複なしペア）。表示順は区画→マス順。
final plantingsProvider = Provider<List<PlantingKey>>((ref) {
  final plots = ref.watch(plotsProvider);
  final result = <PlantingKey>[];
  final seen = <String>{};
  for (final p in plots) {
    for (final cropId in p.cells) {
      if (cropId == null) continue;
      final k = '${p.id}/$cropId';
      if (seen.add(k)) result.add((plotId: p.id, cropId: cropId));
    }
  }
  return result;
});

// --- ナビゲーション（ホーム/区画/暦/野菜/設定） ---
class NavIndex extends Notifier<int> {
  @override
  int build() => 1; // 区画
  void select(int i) => state = i;
}

final navIndexProvider = NotifierProvider<NavIndex, int>(NavIndex.new);

// --- 天気（1週間予報。Open-Meteoからライブ取得） ---
final weatherProvider = FutureProvider<List<DailyWeather>>(
  (ref) => fetchWeeklyForecast(),
);
