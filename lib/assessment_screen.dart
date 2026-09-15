import 'package:flutter/material.dart';
import 'main.dart';
import 'risk_engine.dart';
import 'result_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _step = 0;
  bool _isSubmitting = false;
  bool _isAdvancing = false; // brief lock during the auto-advance animation
  String? _submitError;

  String? animalType;
  String? behavior;
  String? boundLocation;
  String? woundSeverity;
  bool? priorVaccination;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': "What type of animal was involved?",
      'key': 'animalType',
      'options': ['Dog', 'Cat', 'Monkey', 'Bat', 'Rodent / Rabbit', 'Other'],
    },
    {
      'title': "What was the animal's behavior?",
      'key': 'behavior',
      'options': [
        'Unprovoked attack',
        'Provoked (e.g. feeding, petting)',
        'Animal appeared sick / abnormal',
        'Normal / unknown behavior',
      ],
    },
    {
      'title': "Where on the body did it happen?",
      'key': 'boundLocation',
      'options': ['Hand / arm', 'Leg / foot', 'Face / neck', 'Other'],
    },
    {
      'title': "How severe was the wound?",
      'key': 'woundSeverity',
      'options': [
        'Just a touch/lick on intact skin',
        'Minor scratch or nibble, no bleeding',
        'Bleeding bite or deep wound',
        'Contact with mucous membrane (eyes/mouth)',
      ],
    },
    {
      'title': "Has the person been vaccinated for rabies before?",
      'key': 'priorVaccination',
      'options': ['Yes', 'No'],
    },
  ];

  String _codeFor(String key, String option) {
    if (key == 'behavior') {
      if (option.startsWith('Unprovoked')) return 'unprovoked';
      if (option.startsWith('Provoked')) return 'provoked';
      if (option.startsWith('Animal appeared')) return 'sick_abnormal';
      return 'normal';
    }
    if (key == 'woundSeverity') {
      if (option.startsWith('Just a touch')) return 'intact_skin';
      if (option.startsWith('Minor scratch')) return 'minor_scratch';
      if (option.startsWith('Bleeding')) return 'bleeding_bite';
      return 'mucous_membrane';
    }
    if (key == 'animalType') {
      if (option == 'Bat') return 'bat';
      if (option == 'Rodent / Rabbit') return 'rodent';
      if (option == 'Dog') return 'dog';
      if (option == 'Cat') return 'cat';
      if (option == 'Monkey') return 'monkey';
      return 'other';
    }
    return option;
  }

  dynamic _currentAnswer() {
    switch (_steps[_step]['key']) {
      case 'animalType':
        return animalType;
      case 'behavior':
        return behavior;
      case 'boundLocation':
        return boundLocation;
      case 'woundSeverity':
        return woundSeverity;
      case 'priorVaccination':
        return priorVaccination == null ? null : (priorVaccination! ? 'Yes' : 'No');
      default:
        return null;
    }
  }

  // Selecting an option immediately records the answer and auto-advances
  // to the next step (or submits, on the final step) — no separate
  // "Continue" tap required. A very short lock (150ms) prevents a rapid
  // double-tap from registering two selections during the transition.
  Future<void> _selectOption(String option) async {
    if (_isAdvancing || _isSubmitting) return;

    final key = _steps[_step]['key'];
    final code = _codeFor(key, option);

    setState(() {
      _isAdvancing = true;
      switch (key) {
        case 'animalType':
          animalType = code;
          break;
        case 'behavior':
          behavior = code;
          break;
        case 'boundLocation':
          boundLocation = code;
          break;
        case 'woundSeverity':
          woundSeverity = code;
          break;
        case 'priorVaccination':
          priorVaccination = code == 'Yes';
          break;
      }
    });

    // Short delay purely so the user sees their tap register (the option
    // highlights) before the screen moves on — keeps the flow feeling
    // responsive rather than instant-and-jarring.
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    if (_step < _steps.length - 1) {
      setState(() {
        _step++;
        _isAdvancing = false;
      });
    } else {
      setState(() => _isAdvancing = false);
      await _submit();
    }
  }

  void _goBack() {
    if (_isSubmitting) return;
    if (_step > 0) {
      setState(() {
        _step--;
        _submitError = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final category = RiskEngine.calculateCategory(
        woundSeverity: woundSeverity!,
        behavior: behavior!,
        animalType: animalType!,
      );

      final userId = supabase.auth.currentUser!.id;

      final inserted = await supabase.from('bite_incidents').insert({
        'user_id': userId,
        'animal_type': animalType,
        'behavior': behavior,
        'bite_location': boundLocation,
        'wound_severity': woundSeverity,
        'provoked': behavior == 'provoked',
        'prior_vaccination': priorVaccination,
        'risk_category': category,
      }).select().single();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            category: category,
            incidentId: inserted['id'],
            priorVaccination: priorVaccination ?? false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = 'Could not save your report. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If submission failed, show a focused retry screen rather than
    // dumping the user back into the questionnaire — every answer is
    // already captured, so retrying just re-sends the same submit.
    if (_submitError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F9F8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _submitError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF0D3B3B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C4C),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _submitError = null;
                    _step = _steps.length - 1;
                  }),
                  child: const Text('Back to Questionnaire'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isSubmitting) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F9F8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F4C4C)),
              SizedBox(height: 16),
              Text('Saving your report…', style: TextStyle(color: Color(0xFF0D3B3B))),
            ],
          ),
        ),
      );
    }

    final step = _steps[_step];
    final selected = _currentAnswer();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D3B3B)),
          onPressed: _goBack,
        ),
        title: Text(
          'Step ${_step + 1} of ${_steps.length}',
          style: const TextStyle(color: Color(0xFF0D3B3B), fontSize: 14),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / _steps.length,
              backgroundColor: Colors.grey[300],
              color: const Color(0xFF0F4C4C),
              minHeight: 6,
            ),
            const SizedBox(height: 24),
            Text(
              step['title'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D3B3B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap an answer to continue automatically.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: List<String>.from(step['options']).map((option) {
                  final isSelected = selected != null && _codeFor(step['key'], option) == selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectOption(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F4C4C).withOpacity(0.06) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F4C4C) : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? const Color(0xFF0F4C4C) : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}