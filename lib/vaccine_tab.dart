import 'package:flutter/material.dart';
import 'main.dart';
import 'vaccination_screen.dart';

class VaccineTab extends StatefulWidget {
  const VaccineTab({super.key});

  @override
  State<VaccineTab> createState() => _VaccineTabState();
}

class _VaccineTabState extends State<VaccineTab> {
  String? _activeIncidentId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _findActiveIncident();
  }

  Future<void> _findActiveIncident() async {
    if (mounted) setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser!.id;

    // Find this user's incidents that actually have a vaccination schedule,
    // newest first, and use the most recent one
    final incidents = await supabase
        .from('bite_incidents')
        .select('id')
        .eq('user_id', userId)
        .neq('risk_category', 'I')
        .order('created_at', ascending: false)
        .limit(1);

    if (!mounted) return;
    setState(() {
      _activeIncidentId = incidents.isNotEmpty ? incidents[0]['id'] : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeIncidentId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F9F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F9F8),
          elevation: 0,
          title: const Text('Vaccination Plan', style: TextStyle(color: Color(0xFF0D3B3B))),
        ),
        body: RefreshIndicator(
          onRefresh: _findActiveIncident,
          child: ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Text('No active vaccination plan.', style: TextStyle(color: Colors.grey[600])),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return VaccinationScreen(incidentId: _activeIncidentId!);
  }
}