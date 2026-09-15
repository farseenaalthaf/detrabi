import 'package:flutter/material.dart';
import 'vaccination_screen.dart';

class TriageScreen extends StatelessWidget {
  final String category;
  final String incidentId;

  const TriageScreen({super.key, required this.category, required this.incidentId});

  String get _urgencyText {
    switch (category) {
      case 'III':
        return 'Seek care immediately';
      case 'II':
        return 'Seek care within 24 hours';
      default:
        return 'Wash the area — no urgent care needed';
    }
  }

  List<Map<String, String>> get _firstAidSteps {
    return [
      {
        'title': 'Wash immediately',
        'detail': 'Running water + soap, gently scrub for at least 15 minutes.',
      },
      {
        'title': 'Apply antiseptic',
        'detail': 'Povidone-iodine or 70% alcohol if available. Do not bandage tightly.',
      },
      {
        'title': 'Do not suture immediately',
        'detail': 'Deep wounds should be left open or only loosely approximated by a doctor.',
      },
    ];
  }

  List<String> get _warningSigns {
    return [
      'Increasing redness, swelling, or pus at the wound site',
      'Fever, headache, or unusual sensations near the bite',
      'Difficulty swallowing or excessive salivation',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('Triage Guidance', style: TextStyle(color: Color(0xFF0D3B3B))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Urgency banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _urgencyText,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A4A00)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Step-by-step first aid',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B)),
          ),
          const SizedBox(height: 12),

          ..._firstAidSteps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF0F4C4C),
                    child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(step['detail']!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text(
            'Watch for warning signs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B)),
          ),
          const SizedBox(height: 12),

          ..._warningSigns.map((sign) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(sign, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VaccinationScreen(incidentId: incidentId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C4C),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text("I've completed first aid", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}