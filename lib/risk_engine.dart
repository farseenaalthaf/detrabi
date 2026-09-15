class RiskEngine {
  /// Takes the stepper answers and returns 'I', 'II', or 'III'
  static String calculateCategory({
    required String woundSeverity,
    required String behavior,
    required String animalType,
  }) {
    String category;

    // Base category from wound severity
    if (woundSeverity == 'intact_skin') {
      category = 'I';
    } else if (woundSeverity == 'minor_scratch') {
      category = 'II';
    } else {
      // 'bleeding_bite' or 'mucous_membrane'
      category = 'III';
    }

    // Upgrade to III if the animal behaved suspiciously,
    // even if the wound itself looked minor
    final highRiskBehavior = behavior == 'unprovoked' || behavior == 'sick_abnormal';
    if (category == 'II' && highRiskBehavior) {
      category = 'III';
    }

    // Species-specific WHO exceptions, applied last so they override the above

    // Rodents/rabbits almost never carry rabies — cap at Category I
    // unless the wound itself was already severe (still flag for consultation).
    if (animalType == 'rodent' && category != 'III') {
      category = 'I';
    }

    // Bat exposure is treated as high-risk even from minor/unnoticed contact,
    // since bat bites can be very small and easy to miss.
    if (animalType == 'bat') {
      category = 'III';
    }

    return category;
  }
}