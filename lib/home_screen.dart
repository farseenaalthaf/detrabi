import 'package:flutter/material.dart';
import 'main.dart';
import 'assessment_screen.dart';
import 'clinic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = '';
  List<Map<String, dynamic>> _incidents = [];
  List<Map<String, dynamic>> _dueDoses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = supabase.auth.currentUser!.id;

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final incidents = await supabase
        .from('bite_incidents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Get this user's incident IDs, then find due/overdue doses linked to them
    final incidentIds = incidents.map((i) => i['id']).toList();
    List<Map<String, dynamic>> dueDoses = [];

    if (incidentIds.isNotEmpty) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final doses = await supabase
          .from('vaccination_schedules')
          .select()
          .filter('incident_id', 'in', incidentIds)
          .eq('taken', false)
          .lte('due_date', today)
          .order('due_date');

      dueDoses = List<Map<String, dynamic>>.from(doses);
    }

    setState(() {
      _fullName = profile['full_name'] ?? 'there';
      _incidents = List<Map<String, dynamic>>.from(incidents);
      _dueDoses = dueDoses;
      _isLoading = false;
    });
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'I':
        return Colors.green;
      case 'II':
        return Colors.orange;
      case 'III':
        return Colors.red;
      default:
        return Colors.grey;
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
        title: Text(
          'Good afternoon, $_fullName',
          style: const TextStyle(color: Color(0xFF0D3B3B), fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital_outlined, color: Color(0xFF0D3B3B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClinicsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0D3B3B)),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dose reminder banner — only shows if something is due/overdue
            if (_dueDoses.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dueDoses.length == 1
                            ? 'You have 1 vaccine dose due today or overdue.'
                            : 'You have ${_dueDoses.length} vaccine doses due today or overdue.',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7A4A00)),
                      ),
                    ),
                  ],
                ),
              ),

            // Emergency CTA banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "EMERGENCY? DON'T WAIT",
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Report a bite incident now',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AssessmentScreen()),
                      ).then((_) => _loadData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[700],
                    ),
                    child: const Text('+ New Incident'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Recent Incidents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B)),
            ),
            const SizedBox(height: 8),

            if (_incidents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No incidents reported yet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ..._incidents.map((incident) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${incident['animal_type'] ?? 'Unknown'} — ${incident['bite_location'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categoryColor(incident['risk_category']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Cat ${incident['risk_category'] ?? '?'}',
                          style: TextStyle(
                            color: _categoryColor(incident['risk_category']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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