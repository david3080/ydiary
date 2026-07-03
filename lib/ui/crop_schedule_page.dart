import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/weather_api.dart';
import '../domain/models.dart';
import '../state/providers.dart';

const _green = Color(0xFF4C9A52);
const _weekdayJp = ['月', '火', '水', '木', '金', '土', '日'];

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
String _fmt(DateTime d) =>
    '${d.year}/${d.month}/${d.day}(${_weekdayJp[d.weekday - 1]})';
String _fmtShort(DateTime d) => '${d.month}/${d.day}(${_weekdayJp[d.weekday - 1]})';

enum _StatusFilter { all, planned, done, overdue }

/// 作付け（区画×野菜）ごとの作業スケジュール。
/// カレンダー（天気＋予定アイコン）＋全期間の予定リスト（状態/作業で絞り込み）。
class PlantingSchedulePage extends ConsumerStatefulWidget {
  final String plotId;
  final String cropId;
  const PlantingSchedulePage({
    super.key,
    required this.plotId,
    required this.cropId,
  });

  @override
  ConsumerState<PlantingSchedulePage> createState() =>
      _PlantingSchedulePageState();
}

class _PlantingSchedulePageState extends ConsumerState<PlantingSchedulePage> {
  DateTime _focused = DateTime.now();
  DateTime _selected = _dayKey(DateTime.now());
  _StatusFilter _status = _StatusFilter.all;
  final Set<CropEventType> _types = {};

  PlantingKey get _key => (plotId: widget.plotId, cropId: widget.cropId);

  bool _match(CropEvent e, DateTime today) {
    switch (_status) {
      case _StatusFilter.planned:
        if (e.isDone) return false;
      case _StatusFilter.done:
        if (!e.isDone) return false;
      case _StatusFilter.overdue:
        if (e.isDone || !e.plannedDate.isBefore(today)) return false;
      case _StatusFilter.all:
        break;
    }
    if (_types.isNotEmpty && !_types.contains(e.type)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final crop = ref.watch(cropsProvider)[widget.cropId]!;
    final plots = ref.watch(plotsProvider);
    final plotName = plots
        .firstWhere((p) => p.id == widget.plotId,
            orElse: () => plots.first)
        .name;
    final events = ref.watch(eventsForPlantingProvider(_key));
    final weatherAsync = ref.watch(weatherProvider);
    final today = _dayKey(DateTime.now());

    final filtered = events.where((e) => _match(e, today)).toList();

    final eventsByDay = <DateTime, List<CropEvent>>{};
    for (final e in filtered) {
      eventsByDay.putIfAbsent(_dayKey(e.plannedDate), () => []).add(e);
    }
    final weatherByDay = <DateTime, DailyWeather>{
      for (final w in (weatherAsync.value ?? const <DailyWeather>[]))
        _dayKey(w.date): w,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Text('${crop.icon} ${crop.name}（$plotName）',
            style: const TextStyle(fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('予定を追加'),
        onPressed: () => _addEvent(context),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          TableCalendar<CropEvent>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focused,
            currentDay: today,
            selectedDayPredicate: (d) => isSameDay(_selected, d),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: '月'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            rowHeight: 60,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selected, focused) => setState(() {
              _selected = _dayKey(selected);
              _focused = focused;
            }),
            onPageChanged: (focused) => setState(() => _focused = focused),
            calendarBuilders: CalendarBuilders<CropEvent>(
              defaultBuilder: (context, day, _) =>
                  _cell(day, weatherByDay, eventsByDay),
              todayBuilder: (context, day, _) =>
                  _cell(day, weatherByDay, eventsByDay, today: true),
              selectedBuilder: (context, day, _) =>
                  _cell(day, weatherByDay, eventsByDay, selected: true),
              outsideBuilder: (context, day, _) =>
                  _cell(day, weatherByDay, eventsByDay, outside: true),
            ),
          ),
          const Divider(height: 1),
          _filters(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('予定一覧（${filtered.length}件）',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('条件に合う予定はありません',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
            )
          else
            ..._buildList(filtered),
        ],
      ),
    );
  }

  /// 全期間の予定を日付ヘッダー付きで時系列に並べる。
  List<Widget> _buildList(List<CropEvent> list) {
    final widgets = <Widget>[];
    DateTime? last;
    for (final e in list) {
      final d = _dayKey(e.plannedDate);
      if (last == null || d != last) {
        final isSel = d == _selected;
        widgets.add(Container(
          width: double.infinity,
          color: isSel ? const Color(0xFFE3F0E4) : null,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
          child: Text(_fmt(d),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSel ? _green : const Color(0xFF666666),
              )),
        ));
        last = d;
      }
      widgets.add(_eventTile(e));
    }
    return widgets;
  }

  Widget _filters() {
    Widget statusChip(String label, _StatusFilter v) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            selected: _status == v,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => setState(() => _status = v),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Wrap(
            children: [
              statusChip('すべて', _StatusFilter.all),
              statusChip('予定', _StatusFilter.planned),
              statusChip('実施済み', _StatusFilter.done),
              statusChip('遅れ', _StatusFilter.overdue),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              for (final t in CropEventType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(t.label, style: const TextStyle(fontSize: 12)),
                    avatar: Icon(t.icon, size: 16, color: t.color),
                    selected: _types.contains(t),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (s) =>
                        setState(() => s ? _types.add(t) : _types.remove(t)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(
    DateTime day,
    Map<DateTime, DailyWeather> weatherByDay,
    Map<DateTime, List<CropEvent>> eventsByDay, {
    bool today = false,
    bool selected = false,
    bool outside = false,
  }) {
    final key = _dayKey(day);
    final w = weatherByDay[key];
    final evs = eventsByDay[key] ?? const [];

    return Container(
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? _green
            : today
                ? const Color(0xFFE3F0E4)
                : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}',
              style: TextStyle(
                fontSize: 12,
                height: 1.0,
                color: selected
                    ? Colors.white
                    : outside
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF333333),
              )),
          SizedBox(
            height: 20,
            child: w == null
                ? null
                : Center(
                    child: Text(weatherGlyph(w.weatherCode).icon,
                        style: const TextStyle(fontSize: 17)),
                  ),
          ),
          Wrap(
            spacing: 1,
            alignment: WrapAlignment.center,
            children: [
              for (final e in evs.take(3))
                Icon(e.type.icon,
                    size: 12,
                    color: e.isDone
                        ? const Color(0xFFAAAAAA)
                        : (selected ? Colors.white : e.type.color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eventTile(CropEvent e) {
    final notifier = ref.read(cropEventsProvider.notifier);
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: e.type.color.withValues(alpha: 0.18),
        child: Icon(e.type.icon, color: e.type.color, size: 18),
      ),
      title: Row(
        children: [
          Text(e.type.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 8),
          if (e.isDone)
            _badge('実施済み', const Color(0xFFE3F0E4), _green)
          else if (e.plannedDate.isBefore(_dayKey(DateTime.now())))
            _badge('遅れ', const Color(0xFFF6E0DE), const Color(0xFFB5453B)),
        ],
      ),
      subtitle: Text(
        e.isDone
            ? '予定 ${_fmtShort(e.plannedDate)}・実施 ${_fmtShort(e.doneDate!)}'
            : '予定 ${_fmtShort(e.plannedDate)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: e.isDone ? '未実施に戻す' : '実施済みにする',
            icon: Icon(
              e.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: e.isDone ? _green : const Color(0xFFBBBBBB),
            ),
            onPressed: () async {
              if (e.isDone) {
                notifier.markUndone(e.id);
              } else {
                final d = await _pickDate(e.plannedDate);
                if (d != null) notifier.markDone(e.id, d);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'reschedule') {
                final d = await _pickDate(e.plannedDate);
                if (d != null) {
                  notifier.reschedule(e.id, d);
                  setState(() {
                    _selected = _dayKey(d);
                    _focused = d;
                  });
                }
              } else if (v == 'delete') {
                notifier.remove(e.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reschedule', child: Text('予定を変更')),
              PopupMenuItem(value: 'delete', child: Text('削除')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 10, color: fg)),
      );

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030, 12, 31),
      );

  Future<void> _addEvent(BuildContext context) async {
    CropEventType type = CropEventType.values.first;
    DateTime date = _selected;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('予定を追加',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('作業',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in CropEventType.values)
                    ChoiceChip(
                      label: Text(t.label),
                      avatar: Icon(t.icon, size: 16, color: t.color),
                      selected: type == t,
                      onSelected: (_) => setModalState(() => type = t),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('予定日 ',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  Text(_fmtShort(date),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () async {
                      final d = await _pickDate(date);
                      if (d != null) setModalState(() => date = d);
                    },
                    child: const Text('日付を選ぶ'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _green),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('追加'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      ref
          .read(cropEventsProvider.notifier)
          .add(widget.plotId, widget.cropId, type, date);
      setState(() {
        _selected = _dayKey(date);
        _focused = date;
      });
    }
  }
}
