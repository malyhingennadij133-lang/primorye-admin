import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() => runApp(const PrimoryeAdminFullApp());

const String kSupabaseUrl = 'https://irwfyswmawiamejmisjg.supabase.co';
const String kSupabaseKey = 'sb_publishable_9Y3IES6sn7s1onvGlkCaNg_hsISZNc1';

class PrimoryeAdminFullApp extends StatelessWidget {
  const PrimoryeAdminFullApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Приморье Суперапп • Панель Администратора',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFF59E0B),
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

  final List<Map<String, dynamic>> _services = [
    {'id': 1, 'title': 'Грузчики', 'rate': 700, 'min_hours': 2, 'max_qty': 30, 'active': true, 'icon': Icons.groups_rounded, 'subservices': ['Квартирный переезд', 'Офисный переезд', 'Подъём стройматериалов', 'Разгрузка фур']},
    {'id': 2, 'title': 'Разнорабочие', 'rate': 650, 'min_hours': 4, 'max_qty': 30, 'active': true, 'icon': Icons.engineering_rounded, 'subservices': ['Уборка территории', 'Земельные работы', 'Помощь на стройке', 'Складские работы']},
    {'id': 3, 'title': 'Тяжёлые работы', 'rate': 900, 'min_hours': 2, 'max_qty': 20, 'active': true, 'icon': Icons.fitness_center_rounded, 'subservices': ['Такелаж сейфов и станков', 'Перенос пианино', 'Банкоматы и терминалы']},
    {'id': 4, 'title': 'Универсалы', 'rate': 750, 'min_hours': 2, 'max_qty': 25, 'active': true, 'icon': Icons.handyman_rounded, 'subservices': ['Сборка/разборка мебели', 'Упаковка вещей', 'Мелкий бытовой ремонт']},
    {'id': 5, 'title': 'Грузовое такси', 'rate': 1400, 'min_hours': 2, 'max_qty': 10, 'active': true, 'icon': Icons.local_shipping_rounded, 'subservices': ['Бортовой грузовик 1.5т', 'Фургон / Будка 3т', 'Грузовик 5т с гидробортом', 'Рефрижератор']},
    {'id': 6, 'title': 'Спецтехника', 'rate': 2500, 'min_hours': 3, 'max_qty': 10, 'active': true, 'icon': Icons.agriculture_rounded, 'subservices': ['Кран-борт (манипулятор)', 'Автовышка', 'Мини-экскаватор', 'Самосвал', 'Автокран']},
    {'id': 7, 'title': 'Интернет-мастер', 'rate': 1200, 'min_hours': 1, 'max_qty': 5, 'active': true, 'icon': Icons.router_rounded, 'subservices': ['Настройка роутера и Wi-Fi', 'Прокладка кабеля', 'Видеонаблюдение']},
  ];
  final List<Map<String, dynamic>> _districts = [
    {'city': 'Владивосток', 'coef': 1.15, 'delivery_fee': 300, 'active': true},
    {'city': 'Артём', 'coef': 1.00, 'delivery_fee': 0, 'active': true},
    {'city': 'Уссурийск', 'coef': 1.00, 'delivery_fee': 0, 'active': true},
    {'city': 'Находка', 'coef': 1.05, 'delivery_fee': 200, 'active': true},
    {'city': 'Большой Камень', 'coef': 1.10, 'delivery_fee': 250, 'active': true},
    {'city': 'Спасск-Дальний', 'coef': 0.95, 'delivery_fee': 0, 'active': true},
    {'city': 'Арсеньев', 'coef': 0.95, 'delivery_fee': 0, 'active': true},
    {'city': 'Партизанск', 'coef': 0.95, 'delivery_fee': 0, 'active': true},
  ];

  double _executorCommission = 10.0;
  bool _payCash = true;
  bool _payCardTransfer = true;
  bool _payCorporateInvoice = true;
  bool _autoCloseOnMaxWorkers = true;

  final _companyCtrl = TextEditingController(text: 'ИП / ООО');
  final _innCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _bikCtrl = TextEditingController();
  final _bankCtrl = TextEditingController(text: 'СберБанк');
  final _sbpCtrl = TextEditingController(text: '+7 (914) ');
  final _phoneCtrl = TextEditingController(text: '+7 (914) 000-00-00');
  final _bannerCtrl = TextEditingController(text: 'Подача грузчиков и спецтехники по Приморью за 30 минут!');

  List<Map<String, dynamic>> _orders = [];

  final List<Map<String, dynamic>> _executors = [
    {'name': 'Алексей К.', 'role': 'Бригадир грузчиков (до 15 чел.)', 'city': 'Артём', 'balance': '4 250 ₽', 'verified': true},
    {'name': 'Дмитрий В.', 'role': 'Водитель (Кран-борт 5т)', 'city': 'Владивосток', 'balance': '8 900 ₽', 'verified': true},
    {'name': 'Сергей М.', 'role': 'Разнорабочий / Такелаж', 'city': 'Уссурийск', 'balance': '1 100 ₽', 'verified': false},
  ];

  Map<String, String> get _headers => {'apikey': kSupabaseKey, 'Authorization': 'Bearer $kSupabaseKey', 'Content-Type': 'application/json', 'Prefer': 'return=representation'};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final req = await html.HttpRequest.request('$kSupabaseUrl/rest/v1/orders?select=*&order=created_at.desc', method: 'GET', requestHeaders: _headers);
      if (req.status == 200 && req.responseText != null && mounted) {
        setState(() => _orders = (jsonDecode(req.responseText!) as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _syncAll() async {
    setState(() => _syncing = true);
    try {
      for (int i = 0; i < _services.length; i++) {
        final s = _services[i];
        await html.HttpRequest.request('$kSupabaseUrl/rest/v1/services', method: 'POST', requestHeaders: _headers, sendData: jsonEncode({'title': s['title'], 'rate': s['rate'], 'max_qty': s['max_qty'], 'sort_order': i + 1}));
      }
      await html.HttpRequest.request('$kSupabaseUrl/rest/v1/app_settings', method: 'POST', requestHeaders: _headers, sendData: jsonEncode({'key': 'billing_and_phone', 'value': jsonEncode({'phone': _phoneCtrl.text, 'company': _companyCtrl.text, 'inn': _innCtrl.text, 'account': _accountCtrl.text, 'bik': _bikCtrl.text, 'bank': _bankCtrl.text, 'sbp': _sbpCtrl.text, 'commission': _executorCommission})}));
    } catch (_) {}
    await _loadOrders();
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Все услуги, реквизиты счёта и телефон сохранены в базу Supabase!'), backgroundColor: Color(0xFF16A34A)));
    }
  }
  Color _accentColor = const Color(0xFFF59E0B);
  Color _cardColor = Colors.white;
  bool _darkThemePreview = false;

  void _openServiceDialog({Map<String, dynamic>? existing, int? index}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final rateCtrl = TextEditingController(text: '${existing?['rate'] ?? 700}');
    final maxQtyCtrl = TextEditingController(text: '${existing?['max_qty'] ?? 30}');
    final subsCtrl = TextEditingController(text: existing != null ? (existing['subservices'] as List).join(', ') : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Новая услуга' : 'Настройка: ${existing['title']}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название услуги', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Тариф (₽/час)', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: maxQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Макс. чел. (до 30)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: subsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Подуслуги (через запятую)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final item = {
                'id': existing?['id'] ?? DateTime.now().millisecondsSinceEpoch,
                'title': title,
                'rate': int.tryParse(rateCtrl.text.trim()) ?? 700,
                'min_hours': 2,
                'max_qty': int.tryParse(maxQtyCtrl.text.trim()) ?? 30,
                'active': existing?['active'] ?? true,
                'icon': existing?['icon'] ?? Icons.work_rounded,
                'subservices': subsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
              };
              setState(() => index != null ? _services[index] = item : _services.add(item));
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = [
      {'icon': Icons.grid_view_rounded, 'label': 'Витрина услуг и подуслуг'},
      {'icon': Icons.location_city_rounded, 'label': 'Тарифы по округам Приморья'},
      {'icon': Icons.account_balance_rounded, 'label': 'Счета, СБП и комиссия 10%'},
      {'icon': Icons.list_alt_rounded, 'label': 'Лента активных заявок'},
      {'icon': Icons.badge_rounded, 'label': 'Исполнители и модерация'},
      {'icon': Icons.palette_rounded, 'label': 'Дизайн, цвета и телефон'},
    ];

    return Scaffold(
      backgroundColor: _darkThemePreview ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: _accentColor, size: 28),
            const SizedBox(width: 10),
            const Text('ПРИМОРЬЕ СУПЕРАПП • Панель Администратора', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: _syncing ? null : _syncAll,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Опубликовать в базу'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF1F2937),
            child: ListView(
              children: [
                const SizedBox(height: 10),
                for (int i = 0; i < menu.length; i++)
                  ListTile(
                    selected: _selectedIndex == i,
                    selectedTileColor: _accentColor,
                    leading: Icon(menu[i]['icon'] as IconData, color: _selectedIndex == i ? Colors.black : Colors.white70),
                    title: Text(menu[i]['label'] as String, style: TextStyle(fontSize: 14, color: _selectedIndex == i ? Colors.black : Colors.white, fontWeight: FontWeight.w600)),
                    onTap: () => setState(() => _selectedIndex = i),
                  ),
              ],
            ),
          ),
          Expanded(padding: const EdgeInsets.all(20), child: _buildTab()),
        ],
      ),
    );
  }
  Widget _buildTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildServicesTab();
      case 1:
        return _buildDistrictsTab();
      case 2:
        return _buildBillingTab();
      case 3:
        return _buildOrdersTab();
      case 4:
        return _buildExecutorsTab();
      default:
        return _buildSettingsTab();
    }
  }

  Widget _buildServicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Витрина услуг, подуслуги и порядок карточек', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkThemePreview ? Colors.white : Colors.black)),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.black),
              onPressed: () => _openServiceDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Добавить услугу'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _services.length,
            itemBuilder: (_, i) {
              final s = _services[i];
              final subs = (s['subservices'] as List).cast<String>();
              return Card(
                color: _cardColor,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: _accentColor.withOpacity(0.2), child: Icon(s['icon'] as IconData, color: _accentColor)),
                  title: Text('${i + 1}. ${s['title']} — ${s['rate']} ₽/час (до ${s['max_qty']} чел.)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subs.isEmpty ? 'Без подуслуг' : 'Подуслуги: ${subs.join(' • ')}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: i == 0 ? null : () => setState(() => _services.insert(i - 1, _services.removeAt(i))), icon: const Icon(Icons.arrow_upward_rounded)),
                      IconButton(onPressed: i == _services.length - 1 ? null : () => setState(() => _services.insert(i + 1, _services.removeAt(i))), icon: const Icon(Icons.arrow_downward_rounded)),
                      Switch(value: s['active'] as bool, onChanged: (v) => setState(() => s['active'] = v)),
                      OutlinedButton(onPressed: () => _openServiceDialog(existing: s, index: i), child: const Text('Настроить')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Тарифы по городам Приморского края', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkThemePreview ? Colors.white : Colors.black)),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            color: _cardColor,
            child: ListView.separated(
              itemCount: _districts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = _districts[i];
                return ListTile(
                  leading: Icon(Icons.location_on_rounded, color: _accentColor),
                  title: Text('${d['city']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Коэффициент: x${d['coef']} • Подача: ${d['delivery_fee']} ₽'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(onPressed: () => setState(() => d['coef'] = double.parse(((d['coef'] as double) + 0.05).toStringAsFixed(2))), child: const Text('+0.05')),
                      const SizedBox(width: 6),
                      OutlinedButton(onPressed: () => setState(() => d['coef'] = double.parse(((d['coef'] as double) - 0.05).clamp(0.5, 3.0).toStringAsFixed(2))), child: const Text('-0.05')),
                      const SizedBox(width: 8),
                      Switch(value: d['active'] as bool, onChanged: (v) => setState(() => d['active'] = v)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildBillingTab() {
    return ListView(
      children: [
        Text('Привязка счетов (ИП / ООО), СБП и комиссия платформы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkThemePreview ? Colors.white : Colors.black)),
        const SizedBox(height: 12),
        Card(
          color: _cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Получатель (ИП / ООО)', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _innCtrl, decoration: const InputDecoration(labelText: 'ИНН', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(flex: 2, child: TextField(controller: _accountCtrl, decoration: const InputDecoration(labelText: 'Расчётный счёт (20 цифр)', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _bikCtrl, decoration: const InputDecoration(labelText: 'БИК банка', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: _bankCtrl, decoration: const InputDecoration(labelText: 'Наименование банка', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _sbpCtrl, decoration: const InputDecoration(labelText: 'Телефон СБП / Карты', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 16),
                Text('Комиссия сервиса с исполнителей: ${_executorCommission.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(value: _executorCommission, min: 0, max: 30, divisions: 30, onChanged: (v) => setState(() => _executorCommission = v)),
                SwitchListTile(title: const Text('Наличный расчёт'), value: _payCash, onChanged: (v) => setState(() => _payCash = v)),
                SwitchListTile(title: const Text('Перевод на карту / СБП'), value: _payCardTransfer, onChanged: (v) => setState(() => _payCardTransfer = v)),
                SwitchListTile(title: const Text('Безналичный расчёт по счёту (с Актом)'), value: _payCorporateInvoice, onChanged: (v) => setState(() => _payCorporateInvoice = v)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text('Лента заявок (${_orders.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkThemePreview ? Colors.white : Colors.black)), const Spacer(), OutlinedButton(onPressed: _loadOrders, child: const Text('Обновить'))]),
        const SizedBox(height: 10),
        Expanded(
          child: Card(
            color: _cardColor,
            child: _orders.isEmpty
                ? const Center(child: Text('Заявок пока нет'))
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      return ListTile(title: Text('${o['service'] ?? 'Заказ'} — ${o['price'] ?? 0} ₽'), subtitle: Text('${o['city'] ?? ''} • ${o['address'] ?? ''} • ${o['client_phone'] ?? ''}'));
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutorsTab() {
    return Card(
      color: _cardColor,
      child: ListView.builder(
        itemCount: _executors.length,
        itemBuilder: (_, i) {
          final ex = _executors[i];
          final v = ex['verified'] as bool;
          return ListTile(
            title: Text('${ex['name']} (${ex['city']})', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${ex['role']} • Баланс: ${ex['balance']}'),
            trailing: FilledButton(onPressed: () => setState(() => ex['verified'] = !v), child: Text(v ? 'Заблокировать' : 'Одобрить')),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab() {
    final accents = [const Color(0xFFF59E0B), const Color(0xFF16A34A), const Color(0xFF2563EB), const Color(0xFFDC2626), const Color(0xFF7C3AED)];
    return Card(
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Цвет кнопок и акцентов в приложении:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: accents.map((c) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => setState(() => _accentColor = c),
                  child: CircleAvatar(backgroundColor: c, radius: 18, child: _accentColor == c ? const Icon(Icons.check, color: Colors.white) : null),
                ),
              )).toList(),
            ),
            const SizedBox(height: 14),
            SwitchListTile(title: const Text('Предпросмотр ночной темы оформления'), value: _darkThemePreview, onChanged: (v) => setState(() => _darkThemePreview = v)),
            const SizedBox(height: 10),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Привязанный номер телефона диспетчерской', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _bannerCtrl, decoration: const InputDecoration(labelText: 'Текст баннера в приложении', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SwitchListTile(title: const Text('Автоматически закрывать набор при достижении лимита (до 30 чел.)'), value: _autoCloseOnMaxWorkers, onChanged: (v) => setState(() => _autoCloseOnMaxWorkers = v)),
          ],
        ),
      ),
    );
  }
}
