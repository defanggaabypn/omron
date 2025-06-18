class OmronData {
  final int? id;
  final DateTime timestamp;
  final String patientName;
  final int age;
  final String gender;
  final double height;
  
  // 7 Fitness Indicators dari Omron HBF-516B
  final double weight;
  final double bodyFatPercentage;
  final double bmi;
  final double skeletalMusclePercentage;
  final int visceralFatLevel;
  final int restingMetabolism;
  final int bodyAge;
  
  // Additional calculated fields
  final String bmiCategory;
  final String bodyFatCategory;
  final String overallAssessment;

  OmronData({
    this.id,
    required this.timestamp,
    required this.patientName,
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
  }) : bmiCategory = _getBMICategory(bmi),
       bodyFatCategory = _getBodyFatCategory(bodyFatPercentage, gender),
       overallAssessment = _getOverallAssessment(bmi, bodyFatPercentage, visceralFatLevel);

  // BMI Categories
  static String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  // Body Fat Categories by Gender
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

  // Overall Health Assessment
  static String _getOverallAssessment(double bmi, double bodyFat, int visceralFat) {
    int score = 0;
    
    // BMI Score
    if (bmi >= 18.5 && bmi < 25.0) score += 2;
    else if (bmi >= 25.0 && bmi < 30.0) score += 1;
    
    // Body Fat Score (assuming average ranges)
    if (bodyFat >= 10 && bodyFat <= 25) score += 2;
    else if (bodyFat > 25 && bodyFat <= 32) score += 1;
    
    // Visceral Fat Score
    if (visceralFat <= 9) score += 2;
    else if (visceralFat <= 14) score += 1;
    
    if (score >= 5) return 'Excellent';
    if (score >= 3) return 'Good';
    if (score >= 1) return 'Fair';
    return 'Needs Improvement';
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'patientName': patientName,
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
    };
  }

  // Create from Map (database)
  factory OmronData.fromMap(Map<String, dynamic> map) {
    return OmronData(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      patientName: map['patientName'],
      age: map['age'],
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      bodyFatPercentage: map['bodyFatPercentage'],
      bmi: map['bmi'],
      skeletalMusclePercentage: map['skeletalMusclePercentage'],
      visceralFatLevel: map['visceralFatLevel'],
      restingMetabolism: map['restingMetabolism'],
      bodyAge: map['bodyAge'],
    );
  }

  // Create copy with updated values
  OmronData copyWith({
    int? id,
    DateTime? timestamp,
    String? patientName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? bodyFatPercentage,
    double? bmi,
    double? skeletalMusclePercentage,
    int? visceralFatLevel,
    int? restingMetabolism,
    int? bodyAge,
  }) {
    return OmronData(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      patientName: patientName ?? this.patientName,
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
    );
  }
}
