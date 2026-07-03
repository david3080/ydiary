import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models.dart';
import 'seed_data.dart';

/// Open-Meteo から1週間の日別予報を取得する（APIキー不要・CORS対応）。
Future<List<DailyWeather>> fetchWeeklyForecast() async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '$kWeatherLat',
    'longitude': '$kWeatherLon',
    'daily':
        'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
    'timezone': 'Asia/Tokyo',
    'forecast_days': '16', // Open-Meteo無料枠の最大（先の方は精度が落ちる目安）
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('天気の取得に失敗しました (${res.statusCode})');
  }

  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final daily = json['daily'] as Map<String, dynamic>;
  final times = (daily['time'] as List).cast<String>();
  final codes = (daily['weather_code'] as List);
  final tMax = (daily['temperature_2m_max'] as List);
  final tMin = (daily['temperature_2m_min'] as List);
  final pop = (daily['precipitation_probability_max'] as List);

  return [
    for (var i = 0; i < times.length; i++)
      DailyWeather(
        date: DateTime.parse(times[i]),
        weatherCode: (codes[i] as num).toInt(),
        tempMax: (tMax[i] as num).toDouble(),
        tempMin: (tMin[i] as num).toDouble(),
        precipProbability: pop[i] == null ? 0 : (pop[i] as num).toInt(),
      ),
  ];
}

/// WMO weather code → 絵文字とラベル。
({String icon, String label}) weatherGlyph(int code) {
  if (code == 0) return (icon: '☀️', label: '快晴');
  if (code <= 2) return (icon: '🌤️', label: '晴れ');
  if (code == 3) return (icon: '☁️', label: 'くもり');
  if (code == 45 || code == 48) return (icon: '🌫️', label: '霧');
  if (code >= 51 && code <= 57) return (icon: '🌦️', label: '霧雨');
  if (code >= 61 && code <= 67) return (icon: '🌧️', label: '雨');
  if (code >= 71 && code <= 77) return (icon: '🌨️', label: '雪');
  if (code >= 80 && code <= 82) return (icon: '🌧️', label: 'にわか雨');
  if (code >= 85 && code <= 86) return (icon: '🌨️', label: 'にわか雪');
  if (code >= 95) return (icon: '⛈️', label: '雷雨');
  return (icon: '🌡️', label: '—');
}
