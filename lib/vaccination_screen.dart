import 'package:flutter/material.dart';
import 'main.dart';

class VaccinationScreen extends StatefulWidget {
  final String incidentId;
  const VaccinationScreen({super.key, required this.incidentId});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  List<Map<String, dynamic>> _doses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoses();
  }

  Future<void> _loadDoses() async {
    final data = await supabase
        .from('vaccination_schedules')
        .select()
        .eq('incident_id', widget.incidentId)
        .order('dose_number');

    setState(() {
      _doses = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final takenCount = _doses.where((d) => d['taken'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('Vaccination Plan', style: TextStyle(color: Color(0xFF0D3B3B))),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDoses,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('OVERALL PROGRESS', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    '$takenCount / ${_doses.length} doses',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B)),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _doses.isEmpty ? 0 : takenCount / _doses.length,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF1C8C7C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Informational note — doses are confirmed by clinical staff, not the patient
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Doses are marked complete by clinical staff at your vaccination visit.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ..._doses.map((dose) {
              final taken = dose['taken'] == true;
              final doseNumber = dose['dose_number'];
              final dueDate = dose['due_date'] ?? '';
              final takenAt = dose['taken_at'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: taken ? Colors.green[200]! : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: taken ? Colors.green : Colors.grey[300],
                      child: taken
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text('$doseNumber', style: const TextStyle(color: Colors.black54)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dose $doseNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            taken
                                ? 'Administered${takenAt != null ? ' · ${takenAt.toString().split('T')[0]}' : ''}'
                                : 'Due $dueDate',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (!taken)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Pending', style: TextStyle(fontSize: 11, color: Colors.orange[800])),
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