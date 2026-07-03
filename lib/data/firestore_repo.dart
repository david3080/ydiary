import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models.dart';

/// 家族など許可されたユーザー全員で共有する、トップレベルのコレクション参照。
/// 誰が読み書きできるかは Firestore セキュリティルール（メール許可リスト）で制御する。
class FirestorePaths {
  static CollectionReference<Map<String, dynamic>> get plots =>
      FirebaseFirestore.instance.collection('plots');

  static CollectionReference<Map<String, dynamic>> get events =>
      FirebaseFirestore.instance.collection('events');
}

// --- Plot <-> Firestore ---

Map<String, dynamic> plotToMap(Plot p, {required int order}) => {
      'name': p.name,
      'cols': p.cols,
      'rows': p.rows,
      'cells': p.cells,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
    };

Plot plotFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data();
  final cols = (d['cols'] as num).toInt();
  final rows = (d['rows'] as num).toInt();
  final rawCells = (d['cells'] as List?) ?? const [];
  final cells = List<String?>.generate(
    cols * rows,
    (i) => i < rawCells.length ? rawCells[i] as String? : null,
  );
  return Plot(
    id: doc.id,
    name: d['name'] as String? ?? '',
    cols: cols,
    rows: rows,
    cells: cells,
  );
}

// --- CropEvent <-> Firestore ---

Map<String, dynamic> eventToMap(CropEvent e) => {
      'plotId': e.plotId,
      'cropId': e.cropId,
      'type': e.type.name,
      'plannedDate': Timestamp.fromDate(e.plannedDate),
      'doneDate': e.doneDate == null ? null : Timestamp.fromDate(e.doneDate!),
      'note': e.note,
    };

CropEvent eventFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data();
  final doneTs = d['doneDate'] as Timestamp?;
  return CropEvent(
    id: doc.id,
    plotId: d['plotId'] as String? ?? '',
    cropId: d['cropId'] as String? ?? '',
    type: CropEventType.values.byName(d['type'] as String),
    plannedDate: (d['plannedDate'] as Timestamp).toDate(),
    doneDate: doneTs?.toDate(),
    note: d['note'] as String? ?? '',
  );
}
