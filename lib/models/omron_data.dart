class OmronData {
  final int? id;
  final DateTime timestamp;
  final String patientName;
  final String? whatsappNumber;
  final int age;
  final String gender;
  final double height;
  
  // 11 Fitur Lengkap Omron HBF-375
  final double weight;
  final double bodyFatPercentage;
  final double bmi;
  final double skeletalMusclePercentage;
  final double visceralFatLevel;
  final int restingMetabolism;
  final int bodyAge;
  
  // Fitur tambahan yang belum ada
  final double subcutaneousFatPercentage;
  final Map<String, double> segmentalSubcutaneousFat;
  final Map<String, double> segmentalSkeletalMuscle;
  final double sameAgeComparison;
  
  // FIELD BARU: Status pengiriman WhatsApp
  final bool isWhatsAppSent;
  final DateTime? whatsappSentAt; // Timestamp kapan dikirim
  
  // Additional calculated fields
  final String bmiCategory;
  final String bodyFatCategory;
  final String overallAssessment;
  final String sameAgeCategory;

  OmronData({
    this.id,
    required this.timestamp,
    required this.patientName,
    this.whatsappNumber,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.bodyFatPercentage,
    required this.bmi,
    required this.skeletalMusclePercentage,
    required this.visceralFatLevel,
    required this.restingMetabolism,
    required this.bodyAge,
    required this.subcutaneousFatPercentage,
    required this.segmentalSubcutaneousFat,
    required this.segmentalSkeletalMuscle,
    required this.sameAgeComparison,
    this.isWhatsAppSent = false, // DEFAULT FALSE
    this.whatsappSentAt, // FIELD BARU
  }) : bmiCategory = _getBMICategory(bmi),
       bodyFatCategory = _getBodyFatCategory(bodyFatPercentage, gender),
       overallAssessment = _getOverallAssessment(bmi, bodyFatPercentage, visceralFatLevel),
       sameAgeCategory = _getSameAgeCategory(sameAgeComparison);

  // [Semua method static tetap sama...]
  static String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  static String _getBodyFatCategory(double bodyFat, String gender) {
    if (gender.toLowerCase() == 'male') {
      if (bodyFat < 6) return 'Essential Fat';
      if (bodyFat < 14) return 'Athletes';
      if (bodyFat < 18) return 'Fitness';
      if (bodyFat < 25) return 'Average';
      return 'Obese';
    } else {
      if (bodyFat < 14) return 'Essential Fat';
      if (bodyFat < 21) return 'Athletes';
      if (bodyFat < 25) return 'Fitness';
      if (bodyFat < 32) return 'Average';
      return 'Obese';
    }
  }

  static String _getSameAgeCategory(double percentile) {
    if (percentile >= 90) return 'Excellent';
    if (percentile >= 75) return 'Good';
    if (percentile >= 50) return 'Average';
    if (percentile >= 25) return 'Below Average';
    return 'Poor';
  }

  static String _getOverallAssessment(double bmi, double bodyFat, double visceralFat) {
    int score = 0;
    
    if (bmi >= 18.5 && bmi < 25.0) score += 2;
    else if (bmi >= 25.0 && bmi < 30.0) score += 1;
    
    if (bodyFat >= 10 && bodyFat <= 25) score += 2;
    else if (bodyFat > 25 && bodyFat <= 32) score += 1;
    
    if (visceralFat <= 9.0) score += 2;
    else if (visceralFat <= 14.0) score += 1;
    
    if (score >= 5) return 'Excellent';
    if (score >= 3) return 'Good';
    if (score >= 1) return 'Fair';
    return 'Needs Improvement';
  }

  // Helper methods tetap sama...
  String get segmentalSubcutaneousFatJson {
    return '{"trunk": ${segmentalSubcutaneousFat['trunk']}, "rightArm": ${segmentalSubcutaneousFat['rightArm']}, "leftArm": ${segmentalSubcutaneousFat['leftArm']}, "rightLeg": ${segmentalSubcutaneousFat['rightLeg']}, "leftLeg": ${segmentalSubcutaneousFat['leftLeg']}}';
  }

  String get segmentalSkeletalMuscleJson {
    return '{"trunk": ${segmentalSkeletalMuscle['trunk']}, "rightArm": ${segmentalSkeletalMuscle['rightArm']}, "leftArm": ${segmentalSkeletalMuscle['leftArm']}, "rightLeg": ${segmentalSkeletalMuscle['rightLeg']}, "leftLeg": ${segmentalSkeletalMuscle['leftLeg']}}';
  }

  static Map<String, double> _parseSegmentalData(String jsonString) {
    try {
      final cleanJson = jsonString.replaceAll(RegExp(r'[{}"]'), '');
      final pairs = cleanJson.split(', ');
      Map<String, double> result = {};
      
      for (String pair in pairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          result[keyValue[0]] = double.tryParse(keyValue[1]) ?? 0.0;
        }
      }
      return result;
    } catch (e) {
      return {
        'trunk': 0.0,
        'rightArm': 0.0,
        'leftArm': 0.0,
        'rightLeg': 0.0,
        'leftLeg': 0.0,
      };
    }
  }

  static double parseDecimalInput(String input) {
    if (input.isEmpty) return 0.0;
    String normalizedInput = input.replaceAll(',', '.');
    return double.tryParse(normalizedInput) ?? 0.0;
  }

  // UPDATE: Convert to Map dengan field baru
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'patientName': patientName,
      'whatsappNumber': whatsappNumber,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'bmi': bmi,
      'skeletalMusclePercentage': skeletalMusclePercentage,
      'visceralFatLevel': visceralFatLevel,
      'restingMetabolism': restingMetabolism,
      'bodyAge': bodyAge,
      'subcutaneousFatPercentage': subcutaneousFatPercentage,
      'segmentalSubcutaneousFat': segmentalSubcutaneousFatJson,
      'segmentalSkeletalMuscle': segmentalSkeletalMuscleJson,
      'sameAgeComparison': sameAgeComparison,
      'isWhatsAppSent': isWhatsAppSent ? 1 : 0, // SQLite boolean as integer
      'whatsappSentAt': whatsappSentAt?.millisecondsSinceEpoch, // FIELD BARU
    };
  }

  // UPDATE: Create from Map dengan field baru
  factory OmronData.fromMap(Map<String, dynamic> map) {
    return OmronData(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      patientName: map['patientName'],
      whatsappNumber: map['whatsappNumber'],
      age: map['age'],
      gender: map['gender'],
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      bodyFatPercentage: (map['bodyFatPercentage'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      skeletalMusclePercentage: (map['skeletalMusclePercentage'] as num).toDouble(),
      visceralFatLevel: (map['visceralFatLevel'] as num).toDouble(),
      restingMetabolism: map['restingMetabolism'],
      bodyAge: map['bodyAge'],
      subcutaneousFatPercentage: ((map['subcutaneousFatPercentage'] ?? 0.0) as num).toDouble(),
      segmentalSubcutaneousFat: _parseSegmentalData(map['segmentalSubcutaneousFat'] ?? '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}'),
      segmentalSkeletalMuscle: _parseSegmentalData(map['segmentalSkeletalMuscle'] ?? '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}'),
      sameAgeComparison: ((map['sameAgeComparison'] ?? 50.0) as num).toDouble(),
      isWhatsAppSent: (map['isWhatsAppSent'] ?? 0) == 1, // FIELD BARU
      whatsappSentAt: map['whatsappSentAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['whatsappSentAt']) 
        : null, // FIELD BARU
    );
  }

  // UPDATE: Create copy dengan field baru
  OmronData copyWith({
    int? id,
    DateTime? timestamp,
    String? patientName,
    String? whatsappNumber,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? bodyFatPercentage,
    double? bmi,
    double? skeletalMusclePercentage,
    double? visceralFatLevel,
    int? restingMetabolism,
    int? bodyAge,
    double? subcutaneousFatPercentage,
    Map<String, double>? segmentalSubcutaneousFat,
    Map<String, double>? segmentalSkeletalMuscle,
    double? sameAgeComparison,
    bool? isWhatsAppSent, // PARAMETER BARU
    DateTime? whatsappSentAt, // PARAMETER BARU
  }) {
    return OmronData(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      patientName: patientName ?? this.patientName,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      bmi: bmi ?? this.bmi,
      skeletalMusclePercentage: skeletalMusclePercentage ?? this.skeletalMusclePercentage,
      visceralFatLevel: visceralFatLevel ?? this.visceralFatLevel,
      restingMetabolism: restingMetabolism ?? this.restingMetabolism,
      bodyAge: bodyAge ?? this.bodyAge,
      subcutaneousFatPercentage: subcutaneousFatPercentage ?? this.subcutaneousFatPercentage,
      segmentalSubcutaneousFat: segmentalSubcutaneousFat ?? this.segmentalSubcutaneousFat,
      segmentalSkeletalMuscle: segmentalSkeletalMuscle ?? this.segmentalSkeletalMuscle,
      sameAgeComparison: sameAgeComparison ?? this.sameAgeComparison,
      isWhatsAppSent: isWhatsAppSent ?? this.isWhatsAppSent, // COPYWITH SUPPORT
      whatsappSentAt: whatsappSentAt ?? this.whatsappSentAt, // COPYWITH SUPPORT
    );
  }

  // METHOD BARU: Mark sebagai terkirim WhatsApp
  OmronData markAsWhatsAppSent() {
    return copyWith(
      isWhatsAppSent: true,
      whatsappSentAt: DateTime.now(),
    );
  }

  // METHOD BARU: Reset status WhatsApp
  OmronData resetWhatsAppStatus() {
    return copyWith(
      isWhatsAppSent: false,
      whatsappSentAt: null,
    );
  }

  // [Semua method lainnya tetap sama...]
  static double calculateSameAgeComparison(double bodyFat, int age, String gender) {
    Map<String, Map<String, List<double>>> referenceData = {
      'Male': {
        '18-29': [10.0, 15.0, 20.0, 25.0],
        '30-39': [12.0, 17.0, 22.0, 27.0],
        '40-49': [14.0, 19.0, 24.0, 29.0],
        '50-59': [16.0, 21.0, 26.0, 31.0],
        '60+': [18.0, 23.0, 28.0, 33.0],
      },
      'Female': {
        '18-29': [17.0, 22.0, 27.0, 32.0],
        '30-39': [19.0, 24.0, 29.0, 34.0],
        '40-49': [21.0, 26.0, 31.0, 36.0],
        '50-59': [23.0, 28.0, 33.0, 38.0],
        '60+': [25.0, 30.0, 35.0, 40.0],
      },
    };

    String ageGroup;
    if (age < 30) ageGroup = '18-29';
    else if (age < 40) ageGroup = '30-39';
    else if (age < 50) ageGroup = '40-49';
    else if (age < 60) ageGroup = '50-59';
    else ageGroup = '60+';

    List<double> percentiles = referenceData[gender]?[ageGroup] ?? [15.0, 20.0, 25.0, 30.0];

    if (bodyFat <= percentiles[0]) return 25.0;
    if (bodyFat <= percentiles[1]) return 50.0;
    if (bodyFat <= percentiles[2]) return 75.0;
    if (bodyFat <= percentiles[3]) return 90.0;
    return 95.0;
  }

  static Map<String, double> calculateSegmentalSubcutaneousFat(double totalBodyFat) {
    return {
      'trunk': totalBodyFat * 0.4,
      'rightArm': totalBodyFat * 0.15,
      'leftArm': totalBodyFat * 0.15,
      'rightLeg': totalBodyFat * 0.15,
      'leftLeg': totalBodyFat * 0.15,
    };
  }

  static Map<String, double> calculateSegmentalSkeletalMuscle(double totalMuscle) {
    return {
      'trunk': totalMuscle * 0.35,
      'rightArm': totalMuscle * 0.175,
      'leftArm': totalMuscle * 0.175,
      'rightLeg': totalMuscle * 0.15,
      'leftLeg': totalMuscle * 0.15,
    };
  }
}