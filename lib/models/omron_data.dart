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
  
  // Fitur tambahan yang belum ada - UPDATED STRUCTURE
  final double subcutaneousFatPercentage;
  final Map<String, double> segmentalSubcutaneousFat; // wholeBody, trunk, arms, legs
  final Map<String, double> segmentalSkeletalMuscle;  // wholeBody, trunk, arms, legs
  final double sameAgeComparison;
  
  // FIELD BARU: Status pengiriman WhatsApp
  final bool isWhatsAppSent;
  final DateTime? whatsappSentAt;
  
  // Additional calculated fields - FIXED: Konsisten dengan kategori
  final String bmiCategory;
  final String bodyFatCategory;
  final String overallAssessment;
  final String sameAgeCategory;
  final String bodyAgeAssessment; // BARU: Penilaian usia tubuh vs usia asli

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
    this.isWhatsAppSent = false,
    this.whatsappSentAt,
  }) : bmiCategory = _getBMICategory(bmi),
       bodyFatCategory = _getBodyFatCategory(bodyFatPercentage, gender),
       overallAssessment = _getOverallAssessment(bmi, bodyFatPercentage, visceralFatLevel),
       sameAgeCategory = _getSameAgeCategory(sameAgeComparison),
       bodyAgeAssessment = _getBodyAgeAssessment(bodyAge, age); // BARU

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

  // FIXED: Konsisten dengan yang diharapkan di UI
  static String _getSameAgeCategory(double percentile) {
    if (percentile >= 90) return 'Excellent';
    if (percentile >= 75) return 'Good';
    if (percentile >= 50) return 'Average';
    if (percentile >= 25) return 'Below Average';
    return 'Poor';
  }

  // FIXED: Konsisten dengan yang diharapkan di UI
  static String _getOverallAssessment(double bmi, double bodyFat, double visceralFat) {
    int score = 0;
    
    if (bmi >= 18.5 && bmi < 25.0) score += 2;
    else if (bmi >= 25.0 && bmi < 30.0) score += 1;
    
    if (bodyFat >= 10 && bodyFat <= 25) score += 2;
    else if (bodyFat > 25 && bodyFat <= 32) score += 1;
    
    if (visceralFat <= 9.0) score += 2;
    else if (visceralFat <= 14.0) score += 1;
    
    if (score >= 5) return 'Sangat Baik';
    if (score >= 3) return 'Baik';
    if (score >= 1) return 'Cukup';
    return 'Perlu Diperbaiki';
  }

  // BARU: Penilaian usia tubuh vs usia asli
  static String _getBodyAgeAssessment(int bodyAge, int actualAge) {
    final int difference = bodyAge - actualAge;
    
    if (difference <= -10) return 'Sangat Muda'; // Body age 10+ tahun lebih muda
    if (difference <= -5) return 'Lebih Muda';   // Body age 5-10 tahun lebih muda
    if (difference <= -2) return 'Sedikit Muda'; // Body age 2-5 tahun lebih muda
    if (difference <= 2) return 'Sesuai Usia';   // Body age ±2 tahun dari usia asli
    if (difference <= 5) return 'Sedikit Tua';   // Body age 2-5 tahun lebih tua
    if (difference <= 10) return 'Lebih Tua';    // Body age 5-10 tahun lebih tua
    return 'Sangat Tua';                         // Body age 10+ tahun lebih tua
  }

  // HELPER: Get body age assessment description (tanpa Color)
  static String getBodyAgeAssessmentDescription(String assessment, int bodyAge, int actualAge) {
    final int difference = bodyAge - actualAge;
    final String diffText = difference > 0 ? '+${difference}' : '${difference}';
    
    switch (assessment) {
      case 'Sangat Muda':
        return 'Luar biasa! Usia tubuh Anda ${diffText} tahun dari usia sebenarnya. Pertahankan gaya hidup sehat ini.';
      case 'Lebih Muda':
        return 'Bagus! Usia tubuh Anda ${diffText} tahun dari usia sebenarnya. Kondisi fisik sangat baik.';
      case 'Sedikit Muda':
        return 'Baik! Usia tubuh Anda ${diffText} tahun dari usia sebenarnya. Terus jaga pola hidup sehat.';
      case 'Sesuai Usia':
        return 'Normal. Usia tubuh sesuai dengan usia kronologis Anda (${diffText} tahun).';
      case 'Sedikit Tua':
        return 'Perhatian. Usia tubuh Anda ${diffText} tahun dari usia sebenarnya. Tingkatkan aktivitas fisik.';
      case 'Lebih Tua':
        return 'Perlu perbaikan. Usia tubuh Anda ${diffText} tahun dari usia sebenarnya. Konsultasi dengan ahli kesehatan.';
      case 'Sangat Tua':
        return 'Memerlukan perhatian serius. Usia tubuh Anda ${diffText} tahun dari usia sebenarnya. Segera konsultasi medis.';
      default:
        return 'Perbedaan usia tubuh: ${diffText} tahun dari usia sebenarnya.';
    }
  }

  // UPDATED: Helper methods dengan struktur baru
  String get segmentalSubcutaneousFatJson {
    return '{"wholeBody": ${segmentalSubcutaneousFat['wholeBody'] ?? 0.0}, "trunk": ${segmentalSubcutaneousFat['trunk'] ?? 0.0}, "arms": ${segmentalSubcutaneousFat['arms'] ?? 0.0}, "legs": ${segmentalSubcutaneousFat['legs'] ?? 0.0}}';
  }

  String get segmentalSkeletalMuscleJson {
    return '{"wholeBody": ${segmentalSkeletalMuscle['wholeBody'] ?? 0.0}, "trunk": ${segmentalSkeletalMuscle['trunk'] ?? 0.0}, "arms": ${segmentalSkeletalMuscle['arms'] ?? 0.0}, "legs": ${segmentalSkeletalMuscle['legs'] ?? 0.0}}';
  }

  // UPDATED: Parse method dengan struktur baru dan null safety
  static Map<String, double> _parseSegmentalData(String? jsonString) {
    // Default values jika null atau kosong
    final Map<String, double> defaultValues = {
      'wholeBody': 0.0,
      'trunk': 0.0,
      'arms': 0.0,
      'legs': 0.0,
    };
    
    if (jsonString == null || jsonString.isEmpty) {
      return defaultValues;
    }
    
    try {
      final cleanJson = jsonString.replaceAll(RegExp(r'[{}"]'), '');
      final pairs = cleanJson.split(', ');
      Map<String, double> result = {};
      
      for (String pair in pairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = double.tryParse(keyValue[1].trim()) ?? 0.0;
          result[key] = value;
        }
      }
      
      // Ensure all required keys exist with default values
      for (String key in defaultValues.keys) {
        if (!result.containsKey(key)) {
          result[key] = defaultValues[key]!;
        }
      }
      
      return result;
    } catch (e) {
      print('Error parsing segmental data: $e');
      return defaultValues;
    }
  }

  static double parseDecimalInput(String input) {
    if (input.isEmpty) return 0.0;
    String normalizedInput = input.replaceAll(',', '.');
    return double.tryParse(normalizedInput) ?? 0.0;
  }

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
      'isWhatsAppSent': isWhatsAppSent ? 1 : 0,
      'whatsappSentAt': whatsappSentAt?.millisecondsSinceEpoch,
    };
  }

  // UPDATED: fromMap method dengan null safety
  factory OmronData.fromMap(Map<String, dynamic> map) {
    return OmronData(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      patientName: map['patientName'] ?? '',
      whatsappNumber: map['whatsappNumber'],
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'Male',
      height: ((map['height'] ?? 0.0) as num).toDouble(),
      weight: ((map['weight'] ?? 0.0) as num).toDouble(),
      bodyFatPercentage: ((map['bodyFatPercentage'] ?? 0.0) as num).toDouble(),
      bmi: ((map['bmi'] ?? 0.0) as num).toDouble(),
      skeletalMusclePercentage: ((map['skeletalMusclePercentage'] ?? 0.0) as num).toDouble(),
      visceralFatLevel: ((map['visceralFatLevel'] ?? 0.0) as num).toDouble(),
      restingMetabolism: map['restingMetabolism'] ?? 0,
      bodyAge: map['bodyAge'] ?? 0,
      subcutaneousFatPercentage: ((map['subcutaneousFatPercentage'] ?? 0.0) as num).toDouble(),
      segmentalSubcutaneousFat: _parseSegmentalData(map['segmentalSubcutaneousFat']),
      segmentalSkeletalMuscle: _parseSegmentalData(map['segmentalSkeletalMuscle']),
      sameAgeComparison: ((map['sameAgeComparison'] ?? 50.0) as num).toDouble(),
      isWhatsAppSent: (map['isWhatsAppSent'] ?? 0) == 1,
      whatsappSentAt: map['whatsappSentAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['whatsappSentAt']) 
        : null,
    );
  }

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
    bool? isWhatsAppSent,
    DateTime? whatsappSentAt,
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
      isWhatsAppSent: isWhatsAppSent ?? this.isWhatsAppSent,
      whatsappSentAt: whatsappSentAt ?? this.whatsappSentAt,
    );
  }

  OmronData markAsWhatsAppSent() {
    return copyWith(
      isWhatsAppSent: true,
      whatsappSentAt: DateTime.now(),
    );
  }

  OmronData resetWhatsAppStatus() {
    return copyWith(
      isWhatsAppSent: false,
      whatsappSentAt: null,
    );
  }

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

  // UPDATED: Calculation methods dengan struktur baru
  static Map<String, double> calculateSegmentalSubcutaneousFat(double totalBodyFat) {
    return {
      'wholeBody': totalBodyFat,
      'trunk': totalBodyFat * 0.4,
      'arms': totalBodyFat * 0.3,  // Gabungan kedua lengan
      'legs': totalBodyFat * 0.3,  // Gabungan kedua kaki
    };
  }

  static Map<String, double> calculateSegmentalSkeletalMuscle(double totalMuscle) {
    return {
      'wholeBody': totalMuscle,
      'trunk': totalMuscle * 0.35,
      'arms': totalMuscle * 0.35,  // Gabungan kedua lengan
      'legs': totalMuscle * 0.3,   // Gabungan kedua kaki
    };
  }
}