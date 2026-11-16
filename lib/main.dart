import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

const String supabaseUrl = 'https://supabase.co';
const String supabaseKey = 'sb_publishable_9Y3IES6sn7s1onvGikCaNg_hsISZNc1';

void main() => runApp(const PrimoryeAdminWindowsApp());

class PrimoryeAdminWindowsApp extends StatelessWidget {
  const PrimoryeAdminWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Приморье • Панель Администратора (Windows)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFFE2E8F0),
      ),
      home: const AdminWorkspaceScreen(),
    );
  }
}

class AdminWorkspaceScreen extends StatefulWidget {
  const AdminWorkspaceScreen({super.key});

  @override
  State<AdminWorkspaceScreen> createState() => _AdminWorkspaceScreenState();
}

class _AdminWorkspaceScreenState extends State<AdminWorkspaceScreen> {
  bool _loading = true;
  String _status = 'Подключение к облаку...';
  List<Map<String, dynamic>> _tariffs = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _loading = true;
      _status = 'Синхронизация тарифов...';
    });
    try {
      final res = await html.HttpRequest.request(
        '$supabaseUrl/rest/v1/service_tariffs?select=*&order=sort_order.asc',
        requestHeaders: {'apikey': supabaseKey, 'Authorization': 'Bearer $supabaseKey'},
      );
      setState(() {
        _tariffs = res.status == 200 ? (jsonDecode(res.responseText!) as List).cast<Map<String, dynamic>>() : [];
        _status = 'Система онлайн • Услуг: ${_tariffs.length}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка связи с БД';
        _loading = false;
      });
    }
  }

  Future<void> _patchService(String id, Map<String, dynamic> updates) async {
    await html.HttpRequest.request(
      '$supabaseUrl/rest/v1/service_tariffs?id=eq.$id',
      method: 'PATCH',
      requestHeaders: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
      sendData: jsonEncode(updates),
    );
    await _fetchServices();
  }

  Future<void> _createNewService(Map<String, dynamic> newService) async {
    await html.HttpRequest.request(
      '$supabaseUrl/rest/v1/service_tariffs',
      method: 'POST',
      requestHeaders: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      sendData: jsonEncode(newService),
    );
    await _fetchServices();
  }
  void _showAddServiceDialog() {
    final idCtrl = TextEditingController(text: 'srv_${DateTime.now().millisecondsSinceEpoch % 10000}');
    final titleCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: '🌐');
    final rateCtrl = TextEditingController(text: '800');
    final maxCtrl = TextEditingController(text: '10');
    String? parentId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Добавить услугу или подуслугу'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  value: parentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Куда добавить', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Главный экран (основной квадрат)')),
                    ..._tariffs.where((t) => t['parent_id'] == null).map(
                          (t) => DropdownMenuItem(value: t['id'].toString(), child: Text('Внутрь раздела: ${t['title']}')),
                        ),
                  ],
                  onChanged: (v) => setDlgState(() => parentId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название (напр. Интернет-мастер)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  SizedBox(width: 90, child: TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Значок', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ставка ₽/ч', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Макс. кол-во', border: OutlineInputBorder()))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await _createNewService({
                  'id': idCtrl.text.trim(),
                  'title': titleCtrl.text.trim(),
                  'icon': iconCtrl.text.trim().isEmpty ? '🛠️' : iconCtrl.text.trim(),
                  'unit_label': 'Ед.',
                  'max_slider_count': int.tryParse(maxCtrl.text) ?? 10,
                  'base_rate': double.tryParse(rateCtrl.text) ?? 500,
                  'is_active': true,
                  if (parentId != null) 'parent_id': parentId,
                });
              },
              child: const Text('Сохранить в облако'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDialog(Map<String, dynamic> item) {
    final titleCtrl = TextEditingController(text: item['title'].toString());
    final rateCtrl = TextEditingController(text: (item['base_rate'] as num).round().toString());
    final orderCtrl = TextEditingController(text: (item['sort_order'] ?? 10).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Настройка: ${item['title']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название услуги', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Базовая цена ₽/ч', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Порядковый номер квадрата (1, 2, 3...)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _patchService(item['id'].toString(), {
                'title': titleCtrl.text.trim(),
                'base_rate': double.tryParse(rateCtrl.text) ?? item['base_rate'],
                'sort_order': int.tryParse(orderCtrl.text) ?? 10,
              });
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(children: [
          const Icon(Icons.admin_panel_settings, color: Color(0xFFFFC107)),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Приморье • Панель Администратора (Windows)',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: Text(_status, style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
          ),
        ]),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black),
            onPressed: _showAddServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Добавить услугу', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Обновить из облака', onPressed: _fetchServices),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildDesktopServicesGrid(),
    );
  }

  Widget _buildDesktopServicesGrid() {
    if (_tariffs.isEmpty) {
      return const Center(child: Text('Нажмите «+ Добавить услугу» вверху справа, чтобы создать первую услугу.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _tariffs.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (ctx, i) {
        final item = _tariffs[i];
        final bool active = item['is_active'] == true;
        return Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(item['icon'] ?? '🛠️', style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Цена: ${(item['base_rate'] as num).round()} ₽/ч • Поз: ${item['sort_order'] ?? '-'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit), tooltip: 'Изменить цену и порядок', onPressed: () => _showEditServiceDialog(item)),
                Switch(value: active, onChanged: (v) => _patchService(item['id'].toString(), {'is_active': v})),
              ],
            ),
          ),
        );
      },
    );
  }
}
