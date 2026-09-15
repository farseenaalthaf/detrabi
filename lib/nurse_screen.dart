import 'package:flutter/material.dart';
import 'main.dart';

class NurseScreen extends StatefulWidget {
  const NurseScreen({super.key});

  @override
  State<NurseScreen> createState() => _NurseScreenState();
}

class _NurseScreenState extends State<NurseScreen> {
  List<Map<String, dynamic>> _doses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoses();
  }

  Future<void> _loadDoses() async {
    // Get all doses not yet taken, along with the patient's name and incident info
    final data = await supabase
        .from('vaccination_schedules')
        .select('*, bite_incidents(animal_type, risk_category, user_id, profiles(full_name))')
        .eq('taken', false)
        .order('due_date');

    if (!mounted) return;
    setState(() {
      _doses = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _markAdministered(String doseId) async {
    await supabase.from('vaccination_schedules').update({
      'taken': true,
      'taken_at': DateTime.now().toIso8601String(),
    }).eq('id', doseId);

    _loadDoses();
  }

  Map<String, dynamic> _urgencyInfo(String dueDateStr) {
    final due = DateTime.tryParse(dueDateStr);
    if (due == null) return {'label': 'Due $dueDateStr', 'color': Colors.grey};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final daysDiff = dueDay.difference(today).inDays;

    if (daysDiff < 0) {
      return {'label': 'Overdue ${-daysDiff}d', 'color': Colors.red};
    } else if (daysDiff == 0) {
      return {'label': 'Due today', 'color': Colors.orange};
    } else {
      return {'label': 'Due $dueDateStr', 'color': Colors.green.shade700};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('Vaccination Counter', style: TextStyle(color: Color(0xFF0D3B3B))),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDoses,
        child: _doses.isEmpty
            ? const Center(child: Text('No pending doses.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _doses.length,
                itemBuilder: (context, index) {
                  final dose = _doses[index];
                  final incident = dose['bite_incidents'];
                  final patientName = incident?['profiles']?['full_name'] ?? 'Unknown patient';
                  final category = incident?['risk_category'] ?? '?';
                  final doseNumber = dose['dose_number'];
                  final dueDate = dose['due_date'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE6F3F1),
                          child: Text(
                            patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF0F4C4C), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$patientName · Dose $doseNumber',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Category $category',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 6),
                                  Builder(builder: (context) {
                                    final urgency = _urgencyInfo(dueDate);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (urgency['color'] as Color).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        urgency['label'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: urgency['color'],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _showLogDoseDialog(dose['id'], patientName, doseNumber),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C4C),
                          ),
                          child: const Text('Check in', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showLogDoseDialog(String doseId, String patientName, int doseNumber) {
    String? injectionSite;
    bool isSubmitting = false;
    final batchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Log dose — $patientName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Injection site'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Deltoid', 'Thigh (pediatric)'].map((site) {
                      final isSelected = injectionSite == site;
                      return ChoiceChip(
                        label: Text(site),
                        selected: isSelected,
                        onSelected: isSubmitting
                            ? null
                            : (_) => setDialogState(() => injectionSite = site),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: batchController,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Vaccine batch no.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (injectionSite == null || isSubmitting)
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await supabase.from('vaccination_schedules').update({
                              'taken': true,
                              'taken_at': DateTime.now().toIso8601String(),
                              'injection_site': injectionSite,
                              'vaccine_batch': batchController.text.trim(),
                            }).eq('id', doseId);

                            if (context.mounted) Navigator.of(context).pop();
                            await _loadDoses();
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to check in: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C4C)),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirm dose administered', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}