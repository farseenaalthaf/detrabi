import 'package:flutter/material.dart';
import 'main.dart';

class PharmacistScreen extends StatefulWidget {
  const PharmacistScreen({super.key});

  @override
  State<PharmacistScreen> createState() => _PharmacistScreenState();
}

class _PharmacistScreenState extends State<PharmacistScreen> {
  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    final data = await supabase.from('clinics').select().order('name');
    setState(() {
      _clinics = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _toggleStock(String id, bool current) async {
    await supabase.from('clinics').update({'pep_in_stock': !current}).eq('id', id);
    _loadClinics();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final lowStockCount = _clinics.where((c) => c['pep_in_stock'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('PEP Inventory', style: TextStyle(color: Color(0xFF0D3B3B))),
      ),
      body: RefreshIndicator(
        onRefresh: _loadClinics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('$lowStockCount clinics out of stock', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ..._clinics.map((clinic) {
              final inStock = clinic['pep_in_stock'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(clinic['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(inStock ? 'In stock' : 'Low stock',
                        style: TextStyle(color: inStock ? Colors.green[700] : Colors.red[700], fontSize: 12)),
                    Switch(
                      value: inStock,
                      activeColor: const Color(0xFF0F4C4C),
                      onChanged: (_) => _toggleStock(clinic['id'], inStock),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}