import 'package:flutter/material.dart';
import 'main.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _userCount = 0;
  int _clinicCount = 0;
  int _incidentCount = 0;
  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _rules = [];
  bool _isLoading = true;

  // Tracks which user row currently has a role update in flight.
  String? _updatingUserId;

  final List<String> _roleOptions = const ['patient', 'nurse', 'doctor', 'pharmacist', 'admin'];

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    if (mounted) setState(() => _isLoading = true);

    final users = await supabase.from('profiles').select();
    final clinics = await supabase.from('clinics').select().order('name');
    final incidents = await supabase.from('bite_incidents').select();
    final rules = await supabase.from('risk_reference_rules').select().order('category');

    if (!mounted) return;
    setState(() {
      _userCount = users.length;
      _clinicCount = clinics.length;
      _incidentCount = incidents.length;
      _clinics = List<Map<String, dynamic>>.from(clinics);
      _rules = List<Map<String, dynamic>>.from(rules);
      _users = List<Map<String, dynamic>>.from(users)
        ..sort((a, b) => (a['full_name'] ?? '').toString().compareTo((b['full_name'] ?? '').toString()));
      _isLoading = false;
    });
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    setState(() => _updatingUserId = userId);
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      if (!mounted) return;
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _users[index] = {..._users[index], 'role': newRole};
        }
        _updatingUserId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingUserId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'doctor':
        return Colors.blue;
      case 'nurse':
        return Colors.teal;
      case 'pharmacist':
        return Colors.orange;
      default:
        return Colors.grey;
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

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B))),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ---------------- ADD CLINIC ----------------

  void _showAddClinicDialog() {
    final nameController = TextEditingController();
    final hoursController = TextEditingController(text: 'Open 24 hours');
    final latController = TextEditingController();
    final lngController = TextEditingController();
    bool pepInStock = false;
    bool isSubmitting = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Clinic'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(labelText: 'Clinic name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hoursController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(labelText: 'Hours (e.g. Open 24 hours)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            enabled: !isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: lngController,
                            enabled: !isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: pepInStock,
                          onChanged: isSubmitting
                              ? null
                              : (value) => setDialogState(() => pepInStock = value ?? false),
                        ),
                        const Text('PEP currently in stock'),
                      ],
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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
                          final name = nameController.text.trim();
                          final lat = double.tryParse(latController.text.trim());
                          final lng = double.tryParse(lngController.text.trim());

                          if (name.isEmpty || lat == null || lng == null) {
                            setDialogState(() {
                              errorText = 'Enter a name and valid numeric latitude/longitude.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorText = null;
                          });

                          try {
                            await supabase.from('clinics').insert({
                              'name': name,
                              'hours': hoursController.text.trim(),
                              'latitude': lat,
                              'longitude': lng,
                              'pep_in_stock': pepInStock,
                            });

                            if (context.mounted) Navigator.of(context).pop();
                            await _loadOverview();
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorText = 'Failed to add clinic: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C4C)),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Clinic', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- EDIT WHO GUIDELINE ----------------

  void _showEditRuleDialog(Map<String, dynamic> rule) {
    final descriptionController = TextEditingController(text: rule['description'] ?? '');
    bool requiresVaccine = rule['requires_vaccine'] == true;
    bool requiresImmunoglobulin = rule['requires_immunoglobulin'] == true;
    bool isSubmitting = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Category ${rule['category']} Guideline'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: descriptionController,
                      enabled: !isSubmitting,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: requiresVaccine,
                      onChanged: isSubmitting
                          ? null
                          : (value) => setDialogState(() => requiresVaccine = value ?? false),
                      title: const Text('Requires vaccine (PEP)'),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: requiresImmunoglobulin,
                      onChanged: isSubmitting
                          ? null
                          : (value) => setDialogState(() => requiresImmunoglobulin = value ?? false),
                      title: const Text('Requires immunoglobulin'),
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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
                          setDialogState(() {
                            isSubmitting = true;
                            errorText = null;
                          });
                          try {
                            await supabase.from('risk_reference_rules').update({
                              'description': descriptionController.text.trim(),
                              'requires_vaccine': requiresVaccine,
                              'requires_immunoglobulin': requiresImmunoglobulin,
                            }).eq('id', rule['id']);

                            if (context.mounted) Navigator.of(context).pop();
                            await _loadOverview();
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorText = 'Failed to save: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C4C)),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('System Overview', style: TextStyle(color: Color(0xFF0D3B3B))),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOverview,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _statCard('Registered users', '$_userCount'),
                const SizedBox(width: 10),
                _statCard('Partner clinics', '$_clinicCount'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard('Incidents assessed', '$_incidentCount'),
                const SizedBox(width: 10),
                _statCard(
                  'PEP-stocked clinics',
                  '${_clinics.where((c) => c['pep_in_stock'] == true).length}/$_clinicCount',
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Clinic Directory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B))),
                TextButton.icon(
                  onPressed: _showAddClinicDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Clinic'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ..._clinics.map((clinic) {
              final inStock = clinic['pep_in_stock'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(child: Text(clinic['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: inStock ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        inStock ? 'Stocked' : 'Low',
                        style: TextStyle(fontSize: 11, color: inStock ? Colors.green[800] : Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            const Text('WHO Risk Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B))),
            const SizedBox(height: 4),
            Text(
              'Edit the reference description and treatment requirements shown for each category.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            ..._rules.map((rule) {
              final category = rule['category'] ?? '?';
              final requiresVaccine = rule['requires_vaccine'] == true;
              final requiresImmunoglobulin = rule['requires_immunoglobulin'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _categoryColor(category).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Cat $category',
                              style: TextStyle(color: _categoryColor(category), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _showEditRuleDialog(rule),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rule['description'] ?? '', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(requiresVaccine ? 'Vaccine required' : 'No vaccine needed'),
                          backgroundColor: requiresVaccine ? Colors.orange[50] : Colors.grey[100],
                          labelStyle: TextStyle(fontSize: 11, color: requiresVaccine ? Colors.orange[800] : Colors.grey[700]),
                        ),
                        Chip(
                          label: Text(requiresImmunoglobulin ? 'Immunoglobulin required' : 'No immunoglobulin'),
                          backgroundColor: requiresImmunoglobulin ? Colors.red[50] : Colors.grey[100],
                          labelStyle: TextStyle(fontSize: 11, color: requiresImmunoglobulin ? Colors.red[800] : Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            const Text('Manage Users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B))),
            const SizedBox(height: 4),
            Text(
              'Change a user\'s role to grant or revoke staff access.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            ..._users.map((user) {
              final userId = user['id'] as String;
              final currentRole = (user['role'] ?? 'patient') as String;
              final isUpdatingThisRow = _updatingUserId == userId;

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
                    CircleAvatar(
                      backgroundColor: _roleColor(currentRole).withOpacity(0.15),
                      child: Text(
                        (user['full_name'] ?? '?').toString().isNotEmpty
                            ? (user['full_name'] ?? '?').toString()[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: _roleColor(currentRole), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user['full_name'] ?? 'Unnamed user',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isUpdatingThisRow)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentRole,
                            isDense: true,
                            items: _roleOptions.map((role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(
                                  role[0].toUpperCase() + role.substring(1),
                                  style: TextStyle(fontSize: 13, color: _roleColor(role)),
                                ),
                              );
                            }).toList(),
                            onChanged: (newRole) {
                              if (newRole != null && newRole != currentRole) {
                                _updateUserRole(userId, newRole);
                              }
                            },
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