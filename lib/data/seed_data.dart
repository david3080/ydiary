import 'package:flutter/material.dart';
import '../domain/models.dart';

/// 野菜マスタ（現況で確定した19種）。
const kCrops = <String, Crop>{
  'parsley': Crop(id: 'parsley', name: 'パセリ', color: Color(0xFF3F8F4A), icon: '🌿'),
  'tomato': Crop(id: 'tomato', name: 'ミニトマト', color: Color(0xFFE5544B), icon: '🍅'),
  'cucumber': Crop(id: 'cucumber', name: '胡瓜', color: Color(0xFF7CAE4A), icon: '🥒'),
  'eggplant': Crop(id: 'eggplant', name: '茄子', color: Color(0xFF7D5BA6), icon: '🍆'),
  'moroheiya': Crop(id: 'moroheiya', name: 'モロヘイヤ', color: Color(0xFF5B8C3E), icon: '🌿'),
  'lettuce': Crop(id: 'lettuce', name: 'サニーレタス', color: Color(0xFFC56B8A), icon: '🥬'),
  'edamame': Crop(id: 'edamame', name: '枝豆', color: Color(0xFF9AB84E), icon: '🫛'),
  'negi': Crop(id: 'negi', name: 'ネギ', color: Color(0xFFA7C957), icon: '🌱'),
  'taro': Crop(id: 'taro', name: '里芋', color: Color(0xFFA3855F), icon: '🥔'),
  'kuwamame': Crop(id: 'kuwamame', name: '桑の木豆', color: Color(0xFFC2A34E), icon: '🌾'),
  'satsuma': Crop(id: 'satsuma', name: 'さつまいも', color: Color(0xFFB06B3A), icon: '🍠'),
  'piman': Crop(id: 'piman', name: 'ピーマン', color: Color(0xFF5AA469), icon: '🫑'),
  'okra': Crop(id: 'okra', name: 'オクラ', color: Color(0xFF8FBF6A), icon: '🥦'),
  'kabocha': Crop(id: 'kabocha', name: 'カボチャ', color: Color(0xFFE6A92E), icon: '🎃'),
  'carrot': Crop(id: 'carrot', name: 'にんじん', color: Color(0xFFDD7B3A), icon: '🥕'),
  'kyonegi': Crop(id: 'kyonegi', name: '九条ネギ', color: Color(0xFF88B04A), icon: '🌱'),
  'nira': Crop(id: 'nira', name: 'にら', color: Color(0xFF5F9A3C), icon: '🌿'),
  'akajiso': Crop(id: 'akajiso', name: '赤しそ', color: Color(0xFF9C4A7A), icon: '🍃'),
  'aojiso': Crop(id: 'aojiso', name: '青じそ', color: Color(0xFF6FAE52), icon: '🍃'),
};

/// 作付けサンプル情報。
const kPlantings = <String, PlantingInfo>{
  'tomato': PlantingInfo(date: '2026/05/03', method: '苗'),
  'cucumber': PlantingInfo(date: '2026/05/03', method: '苗'),
  'eggplant': PlantingInfo(date: '2026/05/03', method: '苗'),
  'moroheiya': PlantingInfo(date: '2026/05/20', method: '種まき'),
  'lettuce': PlantingInfo(date: '2026/05/10', method: '苗'),
  'edamame': PlantingInfo(date: '2026/05/15', method: '種まき'),
  'negi': PlantingInfo(date: '2026/04/20', method: '植え替え'),
  'taro': PlantingInfo(date: '2026/04/10', method: '種芋'),
  'kuwamame': PlantingInfo(date: '2026/06/20', method: '種まき（発芽期）'),
  'satsuma': PlantingInfo(date: '2026/05/25', method: '挿し苗'),
  'piman': PlantingInfo(date: '2026/05/03', method: '苗'),
  'okra': PlantingInfo(date: '2026/05/20', method: '種まき'),
  'kabocha': PlantingInfo(date: '2026/05/05', method: '苗'),
  'carrot': PlantingInfo(date: '2026/06/15', method: '種まき（発芽期）'),
  'kyonegi': PlantingInfo(date: '2026/05/10', method: '苗'),
  'nira': PlantingInfo(date: '2026/04/25', method: '植え替え'),
  'akajiso': PlantingInfo(date: '2026/05/01', method: '植え替え'),
  'aojiso': PlantingInfo(date: '2026/05/01', method: '植え替え'),
};

/// 現況の区画レイアウト（design.md 第9章と一致）。
final kPlots = <Plot>[
  Plot.fromBlocks(
    id: 'plot1',
    name: '区画1',
    cols: 12,
    rows: 12,
    blocks: const [
      // 手前・左の角: 里芋 3×3
      Block('taro', c0: 0, c1: 2, r0: 9, r1: 11),
      // 左列(c0): 手前→奥に 枝豆・サニーレタス・モロヘイヤ
      Block('edamame', c0: 0, c1: 0, r0: 6, r1: 8),
      Block('lettuce', c0: 0, c1: 0, r0: 3, r1: 5),
      Block('moroheiya', c0: 0, c1: 0, r0: 0, r1: 2),
      // 中央列(c1)は空け / 右列(c2): ネギ
      Block('negi', c0: 2, c1: 2, r0: 0, r1: 8),
      // c3-4: 手前→奥に ナス・胡瓜・ミニトマト
      Block('eggplant', c0: 3, c1: 4, r0: 8, r1: 11),
      Block('cucumber', c0: 3, c1: 4, r0: 4, r1: 7),
      Block('tomato', c0: 3, c1: 4, r0: 0, r1: 3),
      // c5-7: 手前さつまいも(縦6×横3) / 奥・左2列に桑の木豆
      Block('satsuma', c0: 5, c1: 7, r0: 6, r1: 11),
      Block('kuwamame', c0: 5, c1: 6, r0: 0, r1: 4),
      // 右下: オクラ / 最右列の奥: ピーマン
      Block('okra', c0: 10, c1: 11, r0: 9, r1: 11),
      Block('piman', c0: 11, c1: 11, r0: 0, r1: 2),
    ],
  ),
  Plot.fromBlocks(
    id: 'plot2',
    name: '区画2',
    cols: 6,
    rows: 12,
    blocks: const [
      // 左端列＝赤しそ
      Block('akajiso', c0: 0, c1: 0, r0: 0, r1: 11),
      // 中央: 上半分カボチャ / 下半分にんじん(2列)
      Block('kabocha', c0: 1, c1: 3, r0: 1, r1: 5),
      Block('carrot', c0: 1, c1: 2, r0: 6, r1: 10),
      // 右列: 手前にら3 → 続けて九条ネギ3
      Block('nira', c0: 4, c1: 4, r0: 8, r1: 10),
      Block('kyonegi', c0: 4, c1: 4, r0: 5, r1: 7),
      // 右端の盛り土・手前にんじん増設5
      Block('carrot', c0: 5, c1: 5, r0: 6, r1: 10),
      // 一番奥＝青じそ / 一番手前＝赤しそ（左端列の後に塗って角を上書き）
      Block('aojiso', c0: 0, c1: 5, r0: 0, r1: 0),
      Block('akajiso', c0: 0, c1: 5, r0: 11, r1: 11),
    ],
  ),
];

/// 作業スケジュールのサンプル（野菜ごとの予定・実績）。
final kSeedEvents = <CropEvent>[
  // ===== 区画1 =====
  // ネギ
  CropEvent(id: 'e_negi_1', plotId: 'plot1', cropId: 'negi', type: CropEventType.transplant, plannedDate: DateTime(2026, 4, 5), doneDate: DateTime(2026, 4, 5), note: '植え替え'),
  CropEvent(id: 'e_negi_2', plotId: 'plot1', cropId: 'negi', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 4), doneDate: DateTime(2026, 5, 4), note: 'ネギ肥料'),
  CropEvent(id: 'e_negi_3', plotId: 'plot1', cropId: 'negi', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 27), doneDate: DateTime(2026, 5, 27), note: 'ネギ肥料'),
  // 里芋
  CropEvent(id: 'e_taro_1', plotId: 'plot1', cropId: 'taro', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 4), doneDate: DateTime(2026, 5, 4), note: '種芋植付'),
  CropEvent(id: 'e_taro_2', plotId: 'plot1', cropId: 'taro', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17), note: '油粕・鶏糞'),
  CropEvent(id: 'e_taro_3', plotId: 'plot1', cropId: 'taro', type: CropEventType.hilling, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17)),
  CropEvent(id: 'e_taro_4', plotId: 'plot1', cropId: 'taro', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 14), doneDate: DateTime(2026, 6, 14), note: '化成・鶏糞'),
  CropEvent(id: 'e_taro_5', plotId: 'plot1', cropId: 'taro', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 28), doneDate: DateTime(2026, 6, 28), note: '鶏糞・化成'),
  // 茄子
  CropEvent(id: 'e_eggplant_1', plotId: 'plot1', cropId: 'eggplant', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17)),
  CropEvent(id: 'e_eggplant_3', plotId: 'plot1', cropId: 'eggplant', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 31), doneDate: DateTime(2026, 5, 31), note: '油粕・鶏糞・化成'),
  CropEvent(id: 'e_eggplant_4', plotId: 'plot1', cropId: 'eggplant', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 18), doneDate: DateTime(2026, 6, 18), note: '化成・鶏糞'),
  CropEvent(id: 'e_eggplant_5', plotId: 'plot1', cropId: 'eggplant', type: CropEventType.hilling, plannedDate: DateTime(2026, 6, 18), doneDate: DateTime(2026, 6, 18)),
  // ピーマン
  CropEvent(id: 'e_piman_1', plotId: 'plot1', cropId: 'piman', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 3), doneDate: DateTime(2026, 5, 3)),
  CropEvent(id: 'e_piman_2', plotId: 'plot1', cropId: 'piman', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17), note: '鶏糞・化成'),
  // ミニトマト
  CropEvent(id: 'e_tomato_1', plotId: 'plot1', cropId: 'tomato', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 3), doneDate: DateTime(2026, 5, 3)),
  CropEvent(id: 'e_tomato_2', plotId: 'plot1', cropId: 'tomato', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17), note: '鶏糞・化成'),
  CropEvent(id: 'e_tomato_3', plotId: 'plot1', cropId: 'tomato', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 10), doneDate: DateTime(2026, 6, 10), note: '油粕・化成'),
  // オクラ
  CropEvent(id: 'e_okra_1', plotId: 'plot1', cropId: 'okra', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 3), doneDate: DateTime(2026, 5, 3)),
  CropEvent(id: 'e_okra_2', plotId: 'plot1', cropId: 'okra', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17), note: '鶏糞・化成'),
  // モロヘイヤ
  CropEvent(id: 'e_moroheiya_1', plotId: 'plot1', cropId: 'moroheiya', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 3), doneDate: DateTime(2026, 5, 3)),
  CropEvent(id: 'e_moroheiya_2', plotId: 'plot1', cropId: 'moroheiya', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17), note: '鶏糞・化成'),
  CropEvent(id: 'e_moroheiya_3', plotId: 'plot1', cropId: 'moroheiya', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 10), doneDate: DateTime(2026, 6, 10), note: '油粕・化成'),
  // 枝豆
  CropEvent(id: 'e_edamame_1', plotId: 'plot1', cropId: 'edamame', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 3), doneDate: DateTime(2026, 5, 3)),
  CropEvent(id: 'e_edamame_2', plotId: 'plot1', cropId: 'edamame', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17), note: '鶏糞・化成'),
  CropEvent(id: 'e_edamame_4', plotId: 'plot1', cropId: 'edamame', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 10), doneDate: DateTime(2026, 6, 10), note: '油粕・化成'),
  // さつまいも
  CropEvent(id: 'e_satsuma_1', plotId: 'plot1', cropId: 'satsuma', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 8), doneDate: DateTime(2026, 5, 8), note: '挿し苗'),
  CropEvent(id: 'e_satsuma_2', plotId: 'plot1', cropId: 'satsuma', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 23), doneDate: DateTime(2026, 5, 23), note: '化成'),
  CropEvent(id: 'e_satsuma_3', plotId: 'plot1', cropId: 'satsuma', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 6), doneDate: DateTime(2026, 6, 6), note: '化成・鶏糞'),
  // レタス
  CropEvent(id: 'e_lettuce_1', plotId: 'plot1', cropId: 'lettuce', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 17), doneDate: DateTime(2026, 5, 17)),
  CropEvent(id: 'e_lettuce_2', plotId: 'plot1', cropId: 'lettuce', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 31), doneDate: DateTime(2026, 5, 31), note: '油粕・鶏糞・化成'),
  CropEvent(id: 'e_lettuce_3', plotId: 'plot1', cropId: 'lettuce', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 24), doneDate: DateTime(2026, 6, 24), note: '化成'),
  // きゅうり
  CropEvent(id: 'e_cucumber_1', plotId: 'plot1', cropId: 'cucumber', type: CropEventType.lime, plannedDate: DateTime(2026, 5, 27), doneDate: DateTime(2026, 5, 27), note: '苦土石灰'),
  CropEvent(id: 'e_cucumber_2', plotId: 'plot1', cropId: 'cucumber', type: CropEventType.seedling, plannedDate: DateTime(2026, 6, 13), doneDate: DateTime(2026, 6, 13)),
  CropEvent(id: 'e_cucumber_3', plotId: 'plot1', cropId: 'cucumber', type: CropEventType.fertilize, plannedDate: DateTime(2026, 6, 13), doneDate: DateTime(2026, 6, 13), note: '油粕・化成・鶏糞（元肥）'),
  CropEvent(id: 'e_cucumber_4', plotId: 'plot1', cropId: 'cucumber', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 30), doneDate: DateTime(2026, 6, 30), note: '化成'),
  // 桑の木豆
  CropEvent(id: 'e_kuwamame_1', plotId: 'plot1', cropId: 'kuwamame', type: CropEventType.seeding, plannedDate: DateTime(2026, 6, 21), doneDate: DateTime(2026, 6, 21), note: '種植え'),
  // 苦土石灰（4/25 土づくり）
  CropEvent(id: 'e_lime_eggplant', plotId: 'plot1', cropId: 'eggplant', type: CropEventType.lime, plannedDate: DateTime(2026, 4, 25), doneDate: DateTime(2026, 4, 25), note: '苦土石灰'),
  CropEvent(id: 'e_lime_piman', plotId: 'plot1', cropId: 'piman', type: CropEventType.lime, plannedDate: DateTime(2026, 4, 25), doneDate: DateTime(2026, 4, 25), note: '苦土石灰'),
  CropEvent(id: 'e_lime_tomato', plotId: 'plot1', cropId: 'tomato', type: CropEventType.lime, plannedDate: DateTime(2026, 4, 25), doneDate: DateTime(2026, 4, 25), note: '苦土石灰'),
  CropEvent(id: 'e_lime_okra', plotId: 'plot1', cropId: 'okra', type: CropEventType.lime, plannedDate: DateTime(2026, 4, 25), doneDate: DateTime(2026, 4, 25), note: '苦土石灰'),
  CropEvent(id: 'e_lime_moroheiya', plotId: 'plot1', cropId: 'moroheiya', type: CropEventType.lime, plannedDate: DateTime(2026, 4, 25), doneDate: DateTime(2026, 4, 25), note: '苦土石灰'),
  CropEvent(id: 'e_lime_edamame', plotId: 'plot1', cropId: 'edamame', type: CropEventType.lime, plannedDate: DateTime(2026, 4, 25), doneDate: DateTime(2026, 4, 25), note: '苦土石灰'),
  // ===== 区画2 =====
  // にんじん
  CropEvent(id: 'e_carrot_2', plotId: 'plot2', cropId: 'carrot', type: CropEventType.seeding, plannedDate: DateTime(2026, 5, 31), doneDate: DateTime(2026, 5, 31), note: '鶏糞・化成・油粕'),
  // かぼちゃ
  CropEvent(id: 'e_kabocha_1', plotId: 'plot2', cropId: 'kabocha', type: CropEventType.lime, plannedDate: DateTime(2026, 5, 18), doneDate: DateTime(2026, 5, 18), note: '苦土石灰'),
  CropEvent(id: 'e_kabocha_2', plotId: 'plot2', cropId: 'kabocha', type: CropEventType.seedling, plannedDate: DateTime(2026, 5, 31), doneDate: DateTime(2026, 5, 31), note: '鶏糞・化成・油粕（元肥）'),
  // 九条ネギ
  CropEvent(id: 'e_kyonegi_1', plotId: 'plot2', cropId: 'kyonegi', type: CropEventType.seedling, plannedDate: DateTime(2026, 6, 8), doneDate: DateTime(2026, 6, 8)),
  CropEvent(id: 'e_kyonegi_2', plotId: 'plot2', cropId: 'kyonegi', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 21), doneDate: DateTime(2026, 6, 21), note: 'ネギ肥料'),
  // にら
  CropEvent(id: 'e_nira_1', plotId: 'plot2', cropId: 'nira', type: CropEventType.topdress, plannedDate: DateTime(2026, 5, 27), doneDate: DateTime(2026, 5, 27), note: 'ネギ肥料'),
  CropEvent(id: 'e_nira_2', plotId: 'plot2', cropId: 'nira', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 21), doneDate: DateTime(2026, 6, 21), note: 'ネギ肥料'),
  // 赤しそ・青じそ
  CropEvent(id: 'e_akajiso_1', plotId: 'plot2', cropId: 'akajiso', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 18), doneDate: DateTime(2026, 6, 18), note: '化成'),
  CropEvent(id: 'e_aojiso_1', plotId: 'plot2', cropId: 'aojiso', type: CropEventType.topdress, plannedDate: DateTime(2026, 6, 18), doneDate: DateTime(2026, 6, 18), note: '化成'),
];

/// 天気予報の取得地点（岐阜市）。
const kWeatherLat = 35.42;
const kWeatherLon = 136.76;
const kWeatherPlaceName = '岐阜市';
