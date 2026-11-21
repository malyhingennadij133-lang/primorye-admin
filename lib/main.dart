import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

const String sbUrl = 'https://supabase.co';
const String sbKey = 'sb_publishable_q8Q4n2v9X7kLm3pR6tW1yZ_primorye_anon_key';

void main() => runApp(const PrimoryeAdminApp());

class PrimoryeAdminApp extends StatelessWidget {
  const PrimoryeAdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Работа Тут — Панель Администратора',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121417),
        primaryColor: const Color(0xFFFFCC00),
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;
  bool _loading = false;
  bool _autoClose30 = true;
  double _surgeCoef = 1.0;

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _services = [
    {'id': 1, 'title': 'Грузчики', 'parent_title': '', 'rate': 750, 'min_hours': 2, 'max_qty': 30, 'sort_order': 1},
    {'id': 2, 'title': 'Грузовое такси', 'parent_title': '', 'rate': 1400, 'min_hours': 2, 'max_qty': 10, 'sort_order': 2},
    {'id': 3, 'title': 'Разнорабочие', 'parent_title': '', 'rate': 650, 'min_hours': 4, 'max_qty': 30, 'sort_order': 3},
    {'id': 4, 'title': 'Клининг / Уборка', 'parent_title': '', 'rate': 900, 'min_hours': 3, 'max_qty': 15, 'sort_order': 4},
    {'id': 5, 'title': 'Спецтехника', 'parent_title': '', 'rate': 3500, 'min_hours': 4, 'max_qty': 5, 'sort_order': 5},
    {'id': 6, 'title': 'Тяжёлые работы (такелаж)', 'parent_title': '', 'rate': 1100, 'min_hours': 2, 'max_qty': 20, 'sort_order': 6},
    {'id': 7, 'title': 'Вывоз строительного мусора', 'parent_title': '', 'rate': 2800, 'min_hours': 2, 'max_qty': 10, 'sort_order': 7},
    {'id': 8, 'title': 'Сборка и разборка мебели', 'parent_title': '', 'rate': 850, 'min_hours': 2, 'max_qty': 10, 'sort_order': 8},
    {'id': 9, 'title': 'Универсалы / Мастер на час', 'parent_title': '', 'rate': 950, 'min_hours': 2, 'max_qty': 10, 'sort_order': 9},
    {'id': 10, 'title': 'Земельные и дачные работы', 'parent_title': '', 'rate': 750, 'min_hours': 4, 'max_qty': 30, 'sort_order': 10},
    {'id': 11, 'title': 'Интернет-мастер', 'parent_title': '', 'rate': 1000, 'min_hours': 1, 'max_qty': 5, 'sort_order': 11},
  ];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _blacklist = [];

  final _newSvcTitle = TextEditingController();
  final _newSvcParent = TextEditingController();
  final _newSvcRate = TextEditingController(text: '800');
  final _newSvcHours = TextEditingController(text: '2');
  final _newSvcMax = TextEditingController(text: '30');
  final _newBlPhone = TextEditingController();
  final _newBlReason = TextEditingController(text: 'Неоплата / ложный вызов');

  @override
  void initState() {
    super.initState();
    _syncAll();
  }

  Map<String, String> get _headers => {
    'apikey': sbKey,
    'Authorization': 'Bearer $sbKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  Future<List<Map<String, dynamic>>> _getTable(String query) async {
    try {
      final req = await html.HttpRequest.request('$sbUrl/rest/v1/$query', method: 'GET', requestHeaders: _headers);
      if (req.status == 200 && req.responseText != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(req.responseText!));
      }
    } catch (_) {}
    return [];
  }

  Future<void> _syncAll() async {
    setState(() => _loading = true);
    final c = await _getTable('cities?select=*&order=city.asc');
    final s = await _getTable('services?select=*&order=parent_title.asc,sort_order.asc');
    final o = await _getTable('orders?select=*&order=id.desc');
    final w = await _getTable('workers?select=*&order=id.desc');
    final b = await _getTable('blacklist?select=*&order=id.desc');
    setState(() {
      if (c.isNotEmpty) _cities = c;
      if (s.isNotEmpty) _services = s;
      _orders = o;
      _workers = w;
      _blacklist = b;
      _loading = false;
    });
  }

  Future<void> _addService() async {
    final title = _newSvcTitle.text.trim();
    if (title.isEmpty) return;
    final body = jsonEncode({
      'title': title,
      'parent_title': _newSvcParent.text.trim(),
      'rate': int.tryParse(_newSvcRate.text) ?? 800,
      'min_hours': int.tryParse(_newSvcHours.text) ?? 2,
      'max_qty': int.tryParse(_newSvcMax.text) ?? 30,
      'sort_order': _services.length + 1,
      'active': true,
    });
    await html.HttpRequest.request('$sbUrl/rest/v1/services', method: 'POST', requestHeaders: _headers, sendData: body);
    _newSvcTitle.clear();
    _newSvcParent.clear();
    await _syncAll();
  }

  Future<void> _moveService(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _services.length) return;
    final a = _services[index];
    final b = _services[target];
    final orderA = a['sort_order'] ?? (index + 1);
    final orderB = b['sort_order'] ?? (target + 1);
    if (a['id'] != null && b['id'] != null) {
      await html.HttpRequest.request('$sbUrl/rest/v1/services?id=eq.${a['id']}',
          method: 'PATCH', requestHeaders: _headers, sendData: jsonEncode({'sort_order': orderB}));
      await html.HttpRequest.request('$sbUrl/rest/v1/services?id=eq.${b['id']}',
          method: 'PATCH', requestHeaders: _headers, sendData: jsonEncode({'sort_order': orderA}));
      await _syncAll();
    } else {
      setState(() {
        final tmp = _services[index];
        _services[index] = _services[target];
        _services[target] = tmp;
      });
    }
  }

  Future<void> _updateRate(Map<String, dynamic> svc, int newRate) async {
    if (svc['id'] == null) return;
    await html.HttpRequest.request('$sbUrl/rest/v1/services?id=eq.${svc['id']}',
        method: 'PATCH', requestHeaders: _headers, sendData: jsonEncode({'rate': newRate}));
    await _syncAll();
  }

  Future<void> _addBlacklist() async {
    final ph = _newBlPhone.text.trim();
    if (ph.isEmpty) return;
    await html.HttpRequest.request('$sbUrl/rest/v1/blacklist',
        method: 'POST',
        requestHeaders: _headers,
        sendData: jsonEncode({'phone': ph, 'reason': _newBlReason.text.trim()}));
    _newBlPhone.clear();
    await _syncAll();
  }

  Future<void> _removeBlacklist(int id) async {
    await html.HttpRequest.request('$sbUrl/rest/v1/blacklist?id=eq.$id', method: 'DELETE', requestHeaders: _headers);
    await _syncAll();
  }
  @override
  Widget build(BuildContext context) {
    final menu = [
      '1. Дашборд и выручка',
      '2. Эфир заказов (до 30 чел.)',
      '3. Живая карта GPS',
      '4. Услуги, цены и порядок',
      '5. Города РФ и Приморье (${_cities.length})',
      '6. Исполнители и фотоконтроль',
      '7. Чёрный список (${_blacklist.length})',
      '8. Балансы и комиссия 10%',
      '9. Коэффициент спроса',
      '10. Настройки системы',
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 270,
            color: const Color(0xFF1A1D22),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  color: const Color(0xFFFFCC00),
                  width: double.infinity,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('РАБОТА ТУТ • АДМИН', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 17)),
                      Text('Центр управления • Приморье и РФ', style: TextStyle(color: Colors.black87, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: menu.length,
                    itemBuilder: (_, i) => ListTile(
                      selected: _tab == i,
                      selectedTileColor: const Color(0xFFFFCC00).withOpacity(0.18),
                      title: Text(menu[i], style: TextStyle(color: _tab == i ? const Color(0xFFFFCC00) : Colors.white70, fontSize: 13, fontWeight: _tab == i ? FontWeight.bold : FontWeight.normal)),
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black, minimumSize: const Size.fromHeight(42)),
                    onPressed: _syncAll,
                    icon: const Icon(Icons.sync),
                    label: Text(_loading ? 'Загрузка...' : 'Обновить из облака'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        final sum = _orders.fold<int>(0, (p, e) => p + ((e['total_sum'] ?? 0) as int));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Оперативная сводка системы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _statCard('Городов в базе', '${_cities.isEmpty ? 96 : _cities.length}', Colors.amber),
                _statCard('Услуг и подуслуг', '${_services.length}', Colors.greenAccent),
                _statCard('Заказов в эфире', '${_orders.length}', Colors.lightBlueAccent),
                _statCard('Исполнителей онлайн', '${_workers.length}', Colors.orangeAccent),
                _statCard('Оборот заказов', '$sum ₽', Colors.purpleAccent),
              ],
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Живой эфир заказов (автозакрытие при наборе до 30 чел.)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(children: [
                  const Text('Автозакрытие бригады: '),
                  Switch(value: _autoClose30, activeColor: const Color(0xFFFFCC00), onChanged: (v) => setState(() => _autoClose30 = v)),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _orders.isEmpty
                  ? const Center(child: Text('Активных заказов пока нет — новые заявки из телефона и диспетчерской появятся здесь автоматически.'))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (_, i) {
                        final o = _orders[i];
                        final hired = o['hired_workers'] ?? 0;
                        final need = o['needed_workers'] ?? 1;
                        return Card(
                          color: const Color(0xFF1E2229),
                          child: ListTile(
                            title: Text('#${o['id']} • ${o['service_title']} (${o['city']}) — ${o['address']}'),
                            subtitle: Text('Набрано: $hired из $need чел. • Сумма: ${o['total_sum']} ₽ • Тел: ${o['client_phone']}'),
                            trailing: Chip(
                              label: Text(hired >= need && _autoClose30 ? 'Закрыт (набран)' : '${o['status']}'),
                              backgroundColor: hired >= need ? Colors.green.shade800 : Colors.amber.shade800,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Живая карта GPS и геопозиция исполнителей', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _workers.isEmpty
                  ? const Center(child: Text('Исполнители появятся здесь, как только выйдут на смену в мобильном приложении.'))
                  : ListView.builder(
                      itemCount: _workers.length,
                      itemBuilder: (_, i) {
                        final w = _workers[i];
                        return Card(
                          color: const Color(0xFF1E2229),
                          child: ListTile(
                            leading: const Icon(Icons.location_on, color: Color(0xFFFFCC00)),
                            title: Text('${w['name']} (${w['role']}) — ${w['city']}'),
                            subtitle: Text('GPS: ${w['lat']}, ${w['lng']} • Тел: ${w['phone']}'),
                            trailing: Text('${w['status']}', style: const TextStyle(color: Colors.greenAccent)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Услуги, подуслуги и порядок квадратов на телефоне', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFF1E2229),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: 210, child: TextField(controller: _newSvcTitle, decoration: const InputDecoration(labelText: 'Название услуги', border: OutlineInputBorder(), isDense: true))),
                    SizedBox(width: 190, child: TextField(controller: _newSvcParent, decoration: const InputDecoration(labelText: 'Категория (пусто = главная)', border: OutlineInputBorder(), isDense: true))),
                    SizedBox(width: 110, child: TextField(controller: _newSvcRate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Цена ₽/ч', border: OutlineInputBorder(), isDense: true))),
                    SizedBox(width: 100, child: TextField(controller: _newSvcHours, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Мин. часов', border: OutlineInputBorder(), isDense: true))),
                    SizedBox(width: 100, child: TextField(controller: _newSvcMax, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Макс. чел', border: OutlineInputBorder(), isDense: true))),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black),
                      onPressed: _addService,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить услугу'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _services.length,
                itemBuilder: (_, i) {
                  final s = _services[i];
                  final parent = (s['parent_title'] ?? '').toString();
                  return Card(
                    color: const Color(0xFF1E2229),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: const Color(0xFFFFCC00), child: Text('${i + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                      title: Text(parent.isEmpty ? '${s['title']}' : '${s['title']}  [внутри: $parent]', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Ставка: ${s['rate']} ₽/ч • Мин: ${s['min_hours']} ч • До ${s['max_qty']} чел.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(tooltip: 'Поднять выше', icon: const Icon(Icons.arrow_upward, color: Colors.amber), onPressed: () => _moveService(i, -1)),
                          IconButton(tooltip: 'Опустить ниже', icon: const Icon(Icons.arrow_downward, color: Colors.amber), onPressed: () => _moveService(i, 1)),
                          IconButton(tooltip: '+50 ₽ к ставке', icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent), onPressed: () => _updateRate(s, ((s['rate'] ?? 750) as int) + 50)),
                          IconButton(tooltip: '-50 ₽ от ставки', icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _updateRate(s, ((s['rate'] ?? 750) as int) - 50)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Справочник городов РФ и Приморского края (${_cities.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _cities.length,
                itemBuilder: (_, i) {
                  final c = _cities[i];
                  return Card(
                    color: const Color(0xFF1E2229),
                    child: ListTile(
                      title: Text('${c['city']} (${c['region']})'),
                      trailing: Text('Коэф: ×${c['coef']}', style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Исполнители и фотоконтроль паспорта', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _workers.isEmpty
                  ? const Center(child: Text('Зарегистрированные исполнители появятся здесь.'))
                  : ListView.builder(
                      itemCount: _workers.length,
                      itemBuilder: (_, i) {
                        final w = _workers[i];
                        return Card(
                          color: const Color(0xFF1E2229),
                          child: ListTile(
                            title: Text('${w['name']} • ${w['phone']}'),
                            subtitle: Text('Специализация: ${w['role']} • Рейтинг: ${w['rating']} ★ • Баланс: ${w['balance']} ₽'),
                            trailing: Icon(w['docs_ok'] == true ? Icons.verified : Icons.pending, color: w['docs_ok'] == true ? Colors.greenAccent : Colors.orange),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Общий чёрный список телефонов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 220, child: TextField(controller: _newBlPhone, decoration: const InputDecoration(labelText: 'Телефон (+7...)', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _newBlReason, decoration: const InputDecoration(labelText: 'Причина блокировки', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: _addBlacklist,
                  icon: const Icon(Icons.block),
                  label: const Text('Внести в ЧС'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _blacklist.length,
                itemBuilder: (_, i) {
                  final b = _blacklist[i];
                  return Card(
                    color: const Color(0xFF1E2229),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.redAccent),
                      title: Text('${b['phone']}'),
                      subtitle: Text('${b['reason']}'),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.white70), onPressed: () => _removeBlacklist(b['id'])),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 7:
        return const Center(child: Text('Раздел балансов и автоматического удержания комиссии сервиса 10% с выполненных смен.', style: TextStyle(fontSize: 16)));

      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Повышающий коэффициент спроса: ×${_surgeCoef.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Slider(value: _surgeCoef, min: 1.0, max: 2.0, divisions: 10, activeColor: const Color(0xFFFFCC00), onChanged: (v) => setState(() => _surgeCoef = v)),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Настройки подключения к облаку Supabase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Адрес сервера: $sbUrl'),
            const Text('Максимальный размер бригады на одну заявку: 30 человек (автозакрытие включено)'),
          ],
        );
    }
  }

  Widget _statCard(String title, String val, Color c) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E2229), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(color: c, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
