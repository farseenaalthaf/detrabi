import 'package:flutter/material.dart';
import 'main.dart';
import 'vaccination_screen.dart';
import 'triage_screen.dart';

class ResultScreen extends StatefulWidget {
  final String category;
  final String incidentId;
  final bool priorVaccination;

  const ResultScreen({
    super.key,
    required this.category,
    required this.incidentId,
    required this.priorVaccination,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _scheduleCreated = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != 'I') {
      _createVaccinationSchedule();
    }
  }

  Future<void> _createVaccinationSchedule() async {
    setState(() => _isCreating = true);

    try {
      final existing = await supabase
          .from('vaccination_schedules')
          .select()
          .eq('incident_id', widget.incidentId);

      if (existing.isEmpty) {
        // Previously vaccinated -> shorter 2-dose booster (Day 0, Day 3)
        // Never vaccinated -> full 5-dose primary series
        final doseDays = widget.priorVaccination ? [0, 3] : [0, 3, 7, 14, 28];
        final today = DateTime.now();

        final rows = doseDays.asMap().entries.map((entry) {
          final doseNumber = entry.key + 1;
          final dayOffset = entry.value;
          final dueDate = today.add(Duration(days: dayOffset));
          return {
            'incident_id': widget.incidentId,
            'dose_number': doseNumber,
            'due_date': dueDate.toIso8601String().split('T')[0],
            'taken': false,
          };
        }).toList();

        await supabase.from('vaccination_schedules').insert(rows);
      }

      setState(() {
        _scheduleCreated = true;
        _isCreating = false;
      });
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color get _color {
    switch (widget.category) {
      case 'I':
        return Colors.green;
      case 'II':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String get _description {
    switch (widget.category) {
      case 'I':
        return 'Touching or feeding animals, licks on intact skin. No treatment needed beyond washing.';
      case 'II':
        return 'Minor scratches or nibbles without bleeding. PEP vaccination recommended.';
      default:
        return 'Bites/scratches that break skin, or contact with mucous membrane. Urgent PEP + immunoglobulin required.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: _color.withOpacity(0.15),
                child: Text(
                  widget.category,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _color),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Category ${widget.category} Exposure',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B)),
              ),
              const SizedBox(height: 8),
              Text(
                _description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              if (widget.priorVaccination && widget.category != 'I') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Previously vaccinated — abbreviated 2-dose booster applies',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              if (widget.category != 'I')
                ElevatedButton(
                  onPressed: (_isCreating || !_scheduleCreated)
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TriageScreen(category: widget.category,
                             incidentId: widget.incidentId,),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C4C),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('View Triage Guidance', style: TextStyle(color: Colors.white)),
                ),

              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}