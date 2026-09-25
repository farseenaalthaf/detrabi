import 'package:flutter/material.dart';
import 'main.dart';

class NurseScreen extends StatefulWidget {
  const NurseScreen({super.key});

  @override
  State<NurseScreen> createState() => _NurseScreenState();
}

class _NurseScreenState extends State<NurseScreen> {
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  int _severityRank(String? category) {
    switch (category) {
      case 'III':
        return 3;
      case 'II':
        return 2;
      case 'I':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _loadCases() async {
    final data = await supabase
        .from('bite_incidents')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false);

    var cases = List<Map<String, dynamic>>.from(data);

    cases.sort((a, b) {
      final aConfirmed = a['confirmed'] == true;
      final bConfirmed = b['confirmed'] == true;
      if (aConfirmed != bConfirmed) {
        return aConfirmed ? 1 : -1;
      }

      final severityCompare = _severityRank(b['risk_category'])
          .compareTo(_severityRank(a['risk_category']));
      if (severityCompare != 0) return severityCompare;

      final aCreated = a['created_at'] ?? '';
      final bCreated = b['created_at'] ?? '';
      return bCreated.toString().compareTo(aCreated.toString());
    });

    if (!mounted) return;
    setState(() {
      _cases = cases;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'I':
        return Colors.green;
      case 'II':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _openReviewDialog(Map<String, dynamic> caseItem) {
    String? overrideCategory = caseItem['risk_category'];
    bool isSubmitting = false;
    final notesController = TextEditingController(text: caseItem['clinical_notes'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(caseItem['profiles']?['full_name'] ?? 'Patient'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Self-assessed: Category ${caseItem['risk_category']}',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    const Text('Confirm or override category'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['I', 'II', 'III'].map((cat) {
                        return ChoiceChip(
                          label: Text('Cat $cat'),
                          selected: overrideCategory == cat,
                          onSelected: isSubmitting
                              ? null
                              : (_) => setDialogState(() => overrideCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Clinical notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await supabase.from('bite_incidents').update({
                              'risk_category': overrideCategory,
                              'clinical_notes': notesController.text.trim(),
                              'confirmed': true,
                            }).eq('id', caseItem['id']);

                            if (context.mounted) Navigator.of(context).pop();
                            await _loadCases();
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to confirm: $e')),
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
                      : const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pending = _cases.where((c) => c['confirmed'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('Case Queue', style: TextStyle(color: Color(0xFF0D3B3B))),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0D3B3B)),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('$pending pending', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ..._cases.map((c) {
              final confirmed = c['confirmed'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (!confirmed && c['risk_category'] == 'III')
                        ? Colors.red[200]!
                        : Colors.grey[200]!,
                    width: (!confirmed && c['risk_category'] == 'III') ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['profiles']?['full_name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            confirmed ? 'Confirmed' : 'Awaiting review',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor(c['risk_category']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Cat ${c['risk_category']}',
                          style: TextStyle(color: _categoryColor(c['risk_category']), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _openReviewDialog(c),
                      child: Text(confirmed ? 'View' : 'Review'),
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
