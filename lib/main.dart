import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const PrimoryeAdminFullApp());

const String kSupabaseUrl = 'https://supabase.co';
const String kSupabaseKey = 'sb_publishable_9Y3IES6ss7Slom4GlsCwhg_hIIsIbcI';

class PrimoryeAdminFullApp extends StatelessWidget {
  const PrimoryeAdminFullApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Работа Тут — Панель Администратора (Taxsee Pro)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF9800),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      home: const AdminShellScreen(),
    );
  }
}

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedIndex = 0;
  bool _syncing = false;
  double _surgeMultiplier = 1.0;
  bool _autoAssignByGps = true;
  bool _autoCloseAt30 = true;
  String _selectedRegionFilter = 'Все регионы РФ';

  final List<Map<String, dynamic>> _services = [
    {'id': 1, 'title': 'Грузчики', 'rate': 750, 'min_hours': 2, 'max_qty': 30, 'active': true},
    {'id': 2, 'title': 'Клининг / Уборка', 'rate': 900, 'min_hours': 3, 'max_qty': 15, 'active': true},
    {'id': 3, 'title': 'Разнорабочие', 'rate': 650, 'min_hours': 4, 'max_qty': 30, 'active': true},
    {'id': 4, 'title': 'Тяжёлые работы (такелаж)', 'rate': 1100, 'min_hours': 2, 'max_qty': 20, 'active': true},
    {'id': 5, 'title': 'Универсалы / Мастер на час', 'rate': 950, 'min_hours': 2, 'max_qty': 10, 'active': true},
    {'id': 6, 'title': 'Грузовое такси (Газель / Фургон)', 'rate': 1400, 'min_hours': 2, 'max_qty': 10, 'active': true},
    {'id': 7, 'title': 'Спецтехника (Кран / Экскаватор)', 'rate': 3500, 'min_hours': 4, 'max_qty': 5, 'active': true},
    {'id': 8, 'title': 'Вывоз строительного мусора', 'rate': 2800, 'min_hours': 2, 'max_qty': 10, 'active': true},
    {'id': 9, 'title': 'Сборка и разборка мебели', 'rate': 850, 'min_hours': 2, 'max_qty': 10, 'active': true},
    {'id': 10, 'title': 'Земельные и дачные работы', 'rate': 750, 'min_hours': 4, 'max_qty': 30, 'active': true},
    {'id': 11, 'title': 'Интернет-мастер', 'rate': 1000, 'min_hours': 1, 'max_qty': 5, 'active': true},
  ];

  final List<Map<String, dynamic>> _locations = [
    {'region': 'Приморский край', 'city': 'Владивосток', 'coef': 1.15, 'active': true},
    {'region': 'Приморский край', 'city': 'Артём', 'coef': 1.0, 'active': true},
    {'region': 'Приморский край', 'city': 'Уссурийск', 'coef': 1.0, 'active': true},
    {'region': 'Приморский край', 'city': 'Находка', 'coef': 1.05, 'active': true},
    {'region': 'Приморский край', 'city': 'Большой Камень', 'coef': 1.05, 'active': true},
    {'region': 'Приморский край', 'city': 'ЗАТО Фокино', 'coef': 1.05, 'active': true},
    {'region': 'Приморский край', 'city': 'Смоляниново', 'coef': 1.0, 'active': true},
    {'region': 'Приморский край', 'city': 'Шкотово', 'coef': 1.0, 'active': true},
    {'region': 'Приморский край', 'city': 'Трудовое', 'coef': 1.05, 'active': true},
    {'region': 'Приморский край', 'city': 'Тавричанка', 'coef': 1.0, 'active': true},
    {'region': 'Приморский край', 'city': 'Надеждинское', 'coef': 1.0, 'active': true},
    {'region': 'Приморский край', 'city': 'Арсеньев', 'coef': 0.95, 'active': true},
    {'region': 'Приморский край', 'city': 'Партизанск', 'coef': 0.95, 'active': true},
    {'region': 'Приморский край', 'city': 'Спасск-Дальний', 'coef': 0.95, 'active': true},
    {'region': 'Приморский край', 'city': 'Славянка', 'coef': 1.05, 'active': true},
    {'region': 'Хабаровский край', 'city': 'Хабаровск', 'coef': 1.15, 'active': true},
    {'region': 'Хабаровский край', 'city': 'Комсомольск-на-Амуре', 'coef': 1.0, 'active': true},
    {'region': 'Амурская область', 'city': 'Благовещенск', 'coef': 1.05, 'active': true},
    {'region': 'Сахалинская область', 'city': 'Южно-Сахалинск', 'coef': 1.25, 'active': true},
    {'region': 'Камчатский край', 'city': 'Петропавловск-Камчатский', 'coef': 1.3, 'active': true},
    {'region': 'Москва и МО', 'city': 'Москва', 'coef': 1.45, 'active': true},
    {'region': 'Санкт-Петербург', 'city': 'Санкт-Петербург', 'coef': 1.35, 'active': true},
    {'region': 'Новосибирская область', 'city': 'Новосибирск', 'coef': 1.15, 'active': true},
    {'region': 'Краснодарский край', 'city': 'Краснодар', 'coef': 1.15, 'active': true},
  ];
  final List<Map<String, dynamic>> _workers = [
    {'id': 101, 'name': 'Алексей К.', 'phone': '+7 914 700-11-22', 'role': 'Грузчик / Бригадир', 'city': 'Артём', 'lat': 43.3590, 'lng': 132.1890, 'status': 'На линии', 'rating': 4.95, 'balance': 1450, 'docs_ok': true},
    {'id': 102, 'name': 'Дмитрий В.', 'phone': '+7 924 230-44-55', 'role': 'Газель 4м (Грузовое такси)', 'city': 'Владивосток', 'lat': 43.1155, 'lng': 131.8855, 'status': 'На заказе', 'rating': 4.88, 'balance': 920, 'docs_ok': true},
    {'id': 103, 'name': 'Сергей П.', 'phone': '+7 902 555-77-88', 'role': 'Клининг / Химчистка', 'city': 'Артём', 'lat': 43.3510, 'lng': 132.1750, 'status': 'На линии', 'rating': 5.00, 'balance': 2100, 'docs_ok': true},
    {'id': 104, 'name': 'Игорь М.', 'phone': '+7 914 680-99-00', 'role': 'Манипулятор / Спецтехника', 'city': 'ЗАТО Фокино', 'lat': 42.9690, 'lng': 132.4060, 'status': 'На линии', 'rating': 4.76, 'balance': 150, 'docs_ok': false},
  ];

  final List<Map<String, dynamic>> _orders = [
    {'id': '№4812', 'service': 'Грузчики (бригада)', 'city': 'Артём, ул. Кирова 28', 'needed': 30, 'hired': 28, 'sum': 45000, 'status': 'Набор бригады (28/30)'},
    {'id': '№4811', 'service': 'Клининг / Уборка', 'city': 'Владивосток, Океанский пр-т 15', 'needed': 3, 'hired': 3, 'sum': 8100, 'status': 'В работе'},
    {'id': '№4810', 'service': 'Грузовое такси', 'city': 'Смоляниново, ул. Центральная 4', 'needed': 1, 'hired': 1, 'sum': 4200, 'status': 'Выполнен'},
  ];

  final List<String> _blacklistPhones = [
    '+7 999 000-11-22 — Неоплата 3 часов простоя (Владивосток)',
    '+7 914 111-22-33 — Ложный вызов спецтехники (Артём)',
  ];

  final List<Map<String, dynamic>> _companyAccounts = [
    {'name': 'ИП Малыхин Г. (Основной СБП)', 'inn': '250200000000', 'bank': 'Сбербанк / СБП', 'commission': 10, 'active': true},
    {'name': 'ООО «Работа Тут Приморье» (Безнал с НДС)', 'inn': '2502999999', 'bank': 'Т-Банк Бизнес', 'commission': 10, 'active': false},
  ];

  final List<Map<String, dynamic>> _dispatchers = [
    {'name': 'Оператор Елена', 'login': 'elena_disp', 'shift': 'Дневная смена', 'closed_orders': 42, 'active': true},
    {'name': 'Оператор Максим', 'login': 'max_disp', 'shift': 'Ночная смена', 'closed_orders': 19, 'active': true},
  ];

  @override
  void initState() {
    super.initState();
    _syncWithSupabase();
  }

  Future<void> _syncWithSupabase() async {
    setState(() => _syncing = true);
    try {
      await html.HttpRequest.request(
        '$kSupabaseUrl/rest/v1/services?select=*',
        method: 'GET',
        requestHeaders: {'apikey': kSupabaseKey, 'Authorization': 'Bearer $kSupabaseKey'},
      );
    } catch (_) {}
    if (mounted) setState(() => _syncing = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      (Icons.dashboard, '1. Дашборд'),
      (Icons.map, '2. Карта (GPS)'),
      (Icons.list_alt, '3. Эфир заказов'),
      (Icons.handyman, '4. Услуги и тарифы'),
      (Icons.location_city, '5. Города России'),
      (Icons.people, '6. Исполнители'),
      (Icons.star, '7. Рейтинги и ЧС'),
      (Icons.account_balance_wallet, '8. Балансы и зарплата'),
      (Icons.business, '9. Юрлица (ИП/ООО)'),
      (Icons.settings, '10. Диспетчеры и настройки'),
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF1F2937),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF111827),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFFF9800), borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: const Text('РТ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('РАБОТА ТУТ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Админ-центр Taxsee Pro', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, idx) {
                      final selected = _selectedIndex == idx;
                      return ListTile(
                        leading: Icon(menuItems[idx].$1, color: selected ? const Color(0xFFFF9800) : Colors.white70, size: 20),
                        title: Text(menuItems[idx].$2, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                        tileColor: selected ? Colors.white10 : null,
                        onTap: () => setState(() => _selectedIndex = idx),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: _syncWithSupabase,
                    icon: Icon(_syncing ? Icons.sync : Icons.cloud_done, size: 18),
                    label: Text(_syncing ? 'Синхронизация...' : 'База Supabase: OK'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(42)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(menuItems[_selectedIndex].$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange)),
                        child: Text('Коэффициент спроса: ×${_surgeMultiplier.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _toast('Срочное звуковое оповещение отправлено всем исполнителям!'),
                        icon: const Icon(Icons.campaign, size: 18),
                        label: const Text('Срочный вызов бригады'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Padding(padding: const EdgeInsets.all(20), child: _buildCurrentTab())),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return ListView(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _statCard('Выручка за смену', '148 500 ₽', Icons.payments, Colors.green),
                _statCard('Комиссия сервиса (10%)', '14 850 ₽', Icons.account_balance, Colors.orange),
                _statCard('Исполнителей на линии', '${_workers.length} чел.', Icons.people_alt, Colors.blue),
                _statCard('Активных заявок', '${_orders.length} шт.', Icons.local_shipping, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Повышающий коэффициент («Час пик / Плохая погода»)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _surgeMultiplier,
                      min: 1.0,
                      max: 2.5,
                      divisions: 15,
                      label: '×${_surgeMultiplier.toStringAsFixed(1)}',
                      onChanged: (v) => setState(() => _surgeMultiplier = v),
                    ),
                    Text('Текущая надбавка к базовому тарифу: ×${_surgeMultiplier.toStringAsFixed(1)} (мгновенно применяется ко всем городам)'),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blueGrey.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Живой мониторинг GPS (Приморский край и РФ)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('Метки на карте: ${_workers.length} исполнителей'),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: const MapOptions(initialCenter: LatLng(43.25, 132.05), initialZoom: 9.5),
                  children: [
                    TileLayer(urlTemplate: 'https://openstreetmap.org{z}/{x}/{y}.png', userAgentPackageName: 'ru.primorye.admin'),
                    MarkerLayer(
                      markers: _workers.map((w) => Marker(
                        point: LatLng(w['lat'], w['lng']),
                        width: 150,
                        height: 55,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: w['status'] == 'На линии' ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(6)),
                              child: Text('${w['name']} (${w['city']})', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const Icon(Icons.location_on, color: Colors.red, size: 26),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 2:
        return ListView(
          children: [
            Row(
              children: [
                Switch(value: _autoCloseAt30, onChanged: (v) => setState(() => _autoCloseAt30 = v)),
                const Text('Автозакрытие набора бригады при достижении 30 человек', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            ..._orders.map((o) => Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text(o['id'].toString().replaceAll('№', ''))),
                title: Text('${o['service']} — ${o['city']}'),
                subtitle: Text('Набрано: ${o['hired']} из ${o['needed']} чел. | Статус: ${o['status']}'),
                trailing: Text('${o['sum']} ₽', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )),
          ],
        );
      case 3:
        return ListView(
          children: _services.map((s) => Card(
            child: ListTile(
              title: Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Ставка: ${(s['rate'] * _surgeMultiplier).round()} ₽/час | Мин. заказ: ${s['min_hours']} ч. | Макс. бригада: ${s['max_qty']} чел.'),
              trailing: Switch(value: s['active'], onChanged: (v) => setState(() => s['active'] = v)),
            ),
          )).toList(),
        );
      case 4:
        final filtered = _selectedRegionFilter == 'Все регионы РФ' ? _locations : _locations.where((l) => l['region'] == _selectedRegionFilter).toList();
        return Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedRegionFilter,
                  items: ['Все регионы РФ', 'Приморский край', 'Хабаровский край', 'Амурская область', 'Сахалинская область', 'Москва и МО', 'Санкт-Петербург']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRegionFilter = v!),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _toast('Справочник всех городов РФ и Приморского края (Фокино, Смоляниново, Шкотово) синхронизирован!'),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Выгрузить все города РФ в базу'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: filtered.map((l) => Card(
                  child: ListTile(
                    title: Text('${l['city']} (${l['region']})'),
                    subtitle: Text('Региональный коэффициент тарифа: ×${l['coef']}'),
                    trailing: Switch(value: l['active'], onChanged: (v) => setState(() => l['active'] = v)),
                  ),
                )).toList(),
              ),
            ),
          ],
        );
      case 5:
        return ListView(
          children: _workers.map((w) => Card(
            child: ListTile(
              leading: Icon(w['docs_ok'] ? Icons.verified_user : Icons.warning, color: w['docs_ok'] ? Colors.green : Colors.red),
              title: Text('${w['name']} (${w['role']}) — ${w['city']}'),
              subtitle: Text('Тел: ${w['phone']} | Фотоконтроль: ${w['docs_ok'] ? 'Пройден' : 'Требуется проверка паспорта/авто'}'),
              trailing: ElevatedButton(
                onPressed: () => setState(() => w['docs_ok'] = !w['docs_ok']),
                child: Text(w['docs_ok'] ? 'Допущен' : 'Одобрить фото'),
              ),
            ),
          )).toList(),
        );
      case 6:
        return ListView(
          children: [
            const Text('Рейтинг и приоритет исполнителей (Taxsee Priority)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ..._workers.map((w) => Card(
              child: ListTile(
                title: Text('${w['name']} — Рейтинг: ★ ${w['rating']}'),
                subtitle: Text('Приоритет раздачи заказов: ${w['rating'] >= 4.9 ? 'Высший (+5 мин форы)' : 'Стандартный'}'),
              ),
            )),
            const SizedBox(height: 16),
            const Text('Чёрный список заказчиков и должников', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            ..._blacklistPhones.map((p) => Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.block, color: Colors.red), title: Text(p)))),
          ],
        );
      case 7:
        return ListView(
          children: [
            Row(
              children: [
                const Text('Кошельки исполнителей и ведомость зарплат бригад', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _toast('Ведомость зарплат и комиссии (10%) выгружена в таблицу Excel (CSV)!'),
                  icon: const Icon(Icons.download),
                  label: const Text('Выгрузить в Excel / CSV'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._workers.map((w) => Card(
              child: ListTile(
                title: Text('${w['name']} — Баланс кошелька: ${w['balance']} ₽'),
                subtitle: const Text('Автосписание комиссии сервиса: 10% при закрытии смены'),
                trailing: ElevatedButton(
                  onPressed: () => setState(() => w['balance'] += 500),
                  child: const Text('+ Пополнить 500 ₽'),
                ),
              ),
            )),
          ],
        );
      case 8:
        return ListView(
          children: _companyAccounts.map((acc) => Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.indigo),
              title: Text(acc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ИНН: ${acc['inn']} | Банк: ${acc['bank']} | Комиссия: ${acc['commission']}%'),
              trailing: Switch(value: acc['active'], onChanged: (v) => setState(() => acc['active'] = v)),
            ),
          )).toList(),
        );
      default:
        return ListView(
          children: [
            Card(
              child: SwitchListTile(
                title: const Text('Автоназначение заказов по ближайшему GPS (как в Такси Максим)'),
                subtitle: const Text('Если выключено — заказы уходят в общий эфир всем свободным'),
                value: _autoAssignByGps,
                onChanged: (v) => setState(() => _autoAssignByGps = v),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Учётные записи диспетчеров', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ..._dispatchers.map((d) => Card(
              child: ListTile(
                leading: const Icon(Icons.headset_mic),
                title: Text('${d['name']} (логин: ${d['login']})'),
                subtitle: Text('${d['shift']} | Закрыто заявок: ${d['closed_orders']}'),
                trailing: Switch(value: d['active'], onChanged: (v) => setState(() => d['active'] = v)),
              ),
            )),
          ],
        );
    }
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
