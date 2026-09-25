import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Position? _userLocation;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getUserLocation();
    await _loadClinics();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = 'Location services are off.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationError = 'Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Location permission permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _userLocation = position);
    } catch (e) {
      setState(() => _locationError = 'Could not get your location.');
    }
  }

  Future<void> _loadClinics() async {
    final data = await supabase.from('clinics').select().order('name');
    var clinics = List<Map<String, dynamic>>.from(data);

    if (_userLocation != null) {
      for (var clinic in clinics) {
        final lat = clinic['latitude'];
        final lng = clinic['longitude'];
        if (lat != null && lng != null) {
          final distanceMeters = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            (lat as num).toDouble(),
            (lng as num).toDouble(),
          );
          clinic['distanceKm'] = distanceMeters / 1000;
        } else {
          clinic['distanceKm'] = null;
        }
      }
      clinics.sort((a, b) {
        final da = a['distanceKm'];
        final db = b['distanceKm'];
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }

    setState(() {
      _clinics = clinics;
      _isLoading = false;
    });
  }

  Future<void> _openDirections(double lat, double lng, String name) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Lowercases and collapses any run of repeated letters down to one.
  // This makes "kuttipuram" match "Kuttippuram" and similar typo/spelling
  // variants where a letter is doubled or not.
  String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'(.)\1+'), r'$1');
  }

  List<Map<String, dynamic>> get _filteredClinics {
    if (_searchQuery.isEmpty) return _clinics;
    final normalizedQuery = _normalize(_searchQuery);
    return _clinics.where((c) {
      final name = (c['name'] ?? '').toString();
      final city = (c['city'] ?? c['area'] ?? '').toString();
      return _normalize(name).contains(normalizedQuery) ||
          _normalize(city).contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stockedCount = _filteredClinics.where((c) => c['pep_in_stock'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        title: const Text('Clinic Locator', style: TextStyle(color: Color(0xFF0D3B3B))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search clinics or area',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_locationError!, style: TextStyle(color: Colors.orange[800], fontSize: 12)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$stockedCount clinics with PEP stock nearby', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredClinics.isEmpty
                ? const Center(child: Text('No clinics found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredClinics.length,
                    itemBuilder: (context, index) {
                      final clinic = _filteredClinics[index];
                      final inStock = clinic['pep_in_stock'] == true;
                      final distanceKm = clinic['distanceKm'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFE6F3F1),
                                  child: Icon(Icons.local_hospital, color: Color(0xFF0F4C4C)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(clinic['name'] ?? 'Unnamed clinic', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        distanceKm != null
                                            ? '${distanceKm.toStringAsFixed(1)} km · ${clinic['hours'] ?? ''}'
                                            : clinic['hours'] ?? '',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: inStock ? Colors.green[50] : Colors.red[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    inStock ? 'PEP in stock' : 'Out of stock',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: inStock ? Colors.green[800] : Colors.red[800]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openDirections(
                                  (clinic['latitude'] as num).toDouble(),
                                  (clinic['longitude'] as num).toDouble(),
                                  clinic['name'] ?? '',
                                ),
                                icon: const Icon(Icons.directions, size: 18),
                                label: const Text('Get Directions'),
                                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F4C4C)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
