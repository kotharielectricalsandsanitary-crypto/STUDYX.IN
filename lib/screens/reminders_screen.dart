import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/scheduled_reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const _bg = Color(0xFF090909), _card = Color(0xFF151515), _blue = Color(0xFF4F8CFF), _muted = Color(0xFFB8B8B8);
  static const _storageKey = 'studyx_scheduled_reminders_v1';
  final _title = TextEditingController(text: 'Study time!');
  final _body = TextEditingController(text: 'Open StudyX and start your study session.');
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  bool _daily = true, _loading = true, _saving = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _title.dispose(); _body.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      await ScheduledReminderService.instance.initialize();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      final list = raw == null ? <dynamic>[] : jsonDecode(raw) as List;
      if (!mounted) return;
      setState(() { _items = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(); _loading = false; });
    } catch (e) { if (mounted) { setState(() => _loading = false); _msg('Notification setup failed: $e'); } }
  }

  Future<void> _persist() async => (await SharedPreferences.getInstance()).setString(_storageKey, jsonEncode(_items));
  void _msg(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time, helpText: 'Choose reminder time');
    if (value != null && mounted) setState(() => _time = value);
  }

  Future<void> _add() async {
    final title = _title.text.trim(), body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) { _msg('Enter both a title and a message.'); return; }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final id = DateTime.now().microsecondsSinceEpoch % 2000000000;
      await ScheduledReminderService.instance.schedule(id: id, title: title, body: body, hour: _time.hour, minute: _time.minute, repeatDaily: _daily);
      _items.add({'id': id, 'title': title, 'body': body, 'hour': _time.hour, 'minute': _time.minute, 'daily': _daily});
      await _persist();
      if (mounted) setState(() {});
      _msg(_daily ? 'Daily reminder set for ${_time.format(context)}.' : 'One-time reminder set for ${_time.format(context)}.');
    } catch (e) { _msg('Could not schedule reminder: $e'); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    try {
      await ScheduledReminderService.instance.cancel(id);
      _items.removeWhere((e) => e['id'] == id);
      await _persist();
      if (mounted) setState(() {});
      _msg('Reminder deleted.');
    } catch (e) { _msg('Could not delete reminder: $e'); }
  }

  Future<void> _test() async {
    try { await ScheduledReminderService.instance.showTestNotification(); _msg('Test notification sent. Check your notification shade.'); }
    catch (e) { _msg('Test notification failed: $e'); }
  }

  String _timeLabel(Map<String, dynamic> item) => TimeOfDay(hour: item['hour'] as int? ?? 0, minute: item['minute'] as int? ?? 0).format(context);
  InputDecoration _decoration(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(color: _muted), filled: true, fillColor: const Color(0xFF202020), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _blue)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(title: const Text('Study Reminders'), backgroundColor: _bg, foregroundColor: Colors.white),
    body: _loading ? const Center(child: CircularProgressIndicator(color: _blue)) : ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.notifications_active, color: _blue), SizedBox(width: 10), Text('Create a reminder', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8), const Text('Scheduled reminders can arrive while StudyX is closed.', style: TextStyle(color: _muted)), const SizedBox(height: 16),
        TextField(controller: _title, style: const TextStyle(color: Colors.white), decoration: _decoration('Notification title')),
        const SizedBox(height: 12), TextField(controller: _body, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: _decoration('Notification message')),
        const SizedBox(height: 12), InkWell(onTap: _pickTime, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF202020), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.schedule, color: _blue), const SizedBox(width: 12), const Expanded(child: Text('Reminder time', style: TextStyle(color: Colors.white))), Text(_time.format(context), style: const TextStyle(color: _blue, fontWeight: FontWeight.bold, fontSize: 17)), const Icon(Icons.chevron_right, color: _muted)]))),
        SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: _blue, title: const Text('Repeat every day', style: TextStyle(color: Colors.white)), subtitle: Text(_daily ? 'Notify daily at this time' : 'Notify once at the next occurrence of this time', style: const TextStyle(color: _muted)), value: _daily, onChanged: (v) => setState(() => _daily = v)),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _saving ? null : _add, icon: const Icon(Icons.add_alarm), label: Text(_saving ? 'Scheduling...' : 'Schedule reminder'), style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(height: 8), OutlinedButton.icon(onPressed: _test, icon: const Icon(Icons.notifications), label: const Text('Send test notification now'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), minimumSize: const Size.fromHeight(46))),
      ])),
      const SizedBox(height: 22), Row(children: [const Expanded(child: Text('Your reminders', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))), Text('${_items.length}', style: const TextStyle(color: _muted))]), const SizedBox(height: 10),
      if (_items.isEmpty) Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)), child: const Text('No reminders yet. Add one above.', style: TextStyle(color: _muted))),
      ..._items.map((item) => Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF202B40), child: Icon(Icons.alarm, color: _blue)), title: Text(item['title'] as String? ?? 'Study reminder', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), subtitle: Text('${_timeLabel(item)} • ${(item['daily'] as bool? ?? false) ? 'Daily' : 'One time'}\n${item['body'] ?? ''}', style: const TextStyle(color: _muted, height: 1.5)), isThreeLine: true, trailing: IconButton(tooltip: 'Delete reminder', onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline, color: Colors.redAccent))))),
      const SizedBox(height: 12), const Text('If reminders arrive late, allow StudyX notifications and set its battery use to Unrestricted in Android settings.', style: TextStyle(color: _muted, height: 1.5, fontSize: 12)),
    ]),
  );
}
