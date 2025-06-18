import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/omron_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'omron_hbf375.db');
    return await openDatabase(
      path,
      version: 2, // Increased version untuk update schema
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE omron_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        patientName TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        bodyFatPercentage REAL NOT NULL,
        bmi REAL NOT NULL,
        skeletalMusclePercentage REAL NOT NULL,
        visceralFatLevel INTEGER NOT NULL,
        restingMetabolism INTEGER NOT NULL,
        bodyAge INTEGER NOT NULL,
        subcutaneousFatPercentage REAL NOT NULL DEFAULT 0.0,
        segmentalSubcutaneousFat TEXT NOT NULL DEFAULT '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}',
        segmentalSkeletalMuscle TEXT NOT NULL DEFAULT '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}',
        sameAgeComparison REAL NOT NULL DEFAULT 50.0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_patient_name ON omron_data(patientName)');
    await db.execute('CREATE INDEX idx_timestamp ON omron_data(timestamp)');
    await db.execute('CREATE INDEX idx_patient_timestamp ON omron_data(patientName, timestamp)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE omron_data ADD COLUMN subcutaneousFatPercentage REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE omron_data ADD COLUMN segmentalSubcutaneousFat TEXT NOT NULL DEFAULT \'{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}\'');
      await db.execute('ALTER TABLE omron_data ADD COLUMN segmentalSkeletalMuscle TEXT NOT NULL DEFAULT \'{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}\'');
      await db.execute('ALTER TABLE omron_data ADD COLUMN sameAgeComparison REAL NOT NULL DEFAULT 50.0');
      
      // Create new indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_patient_name ON omron_data(patientName)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_timestamp ON omron_data(timestamp)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_patient_timestamp ON omron_data(patientName, timestamp)');
    }
  }

  // Insert new Omron data
  Future<int> insertOmronData(OmronData data) async {
    final db = await database;
    return await db.insert('omron_data', data.toMap());
  }

  // Get all Omron data (ordered by timestamp desc)
  Future<List<OmronData>> getAllOmronData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Get Omron data by patient name
  Future<List<OmronData>> getOmronDataByPatient(String patientName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: 'patientName = ?',
      whereArgs: [patientName],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Get Omron data with pagination
  Future<List<OmronData>> getOmronDataPaginated({
    int limit = 20,
    int offset = 0,
    String? patientName,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (patientName != null && patientName.isNotEmpty) {
      whereClause = 'WHERE patientName = ?';
      whereArgs.add(patientName);
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM omron_data 
      $whereClause
      ORDER BY timestamp DESC 
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Get Omron data by date range
  Future<List<OmronData>> getOmronDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? patientName,
  }) async {
    final db = await database;
    
    String whereClause = 'timestamp BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ];
    
    if (patientName != null && patientName.isNotEmpty) {
      whereClause += ' AND patientName = ?';
      whereArgs.add(patientName);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Get single Omron data by ID
  Future<OmronData?> getOmronDataById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return OmronData.fromMap(maps.first);
    }
    return null;
  }

  // Update Omron data
  Future<int> updateOmronData(OmronData data) async {
    final db = await database;
    return await db.update(
      'omron_data',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  // Delete Omron data
  Future<int> deleteOmronData(int id) async {
    final db = await database;
    return await db.delete(
      'omron_data',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all data for a patient
  Future<int> deletePatientData(String patientName) async {
    final db = await database;
    return await db.delete(
      'omron_data',
      where: 'patientName = ?',
      whereArgs: [patientName],
    );
  }

  // Get all unique patient names
  Future<List<String>> getPatientNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT patientName FROM omron_data ORDER BY patientName ASC'
    );

    return List.generate(maps.length, (i) {
      return maps[i]['patientName'] as String;
    });
  }

  // Get patient statistics
  Future<Map<String, dynamic>> getPatientStatistics(String patientName) async {
    final db = await database;
    
    // Get count and date range
    final countResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_records,
        MIN(timestamp) as first_record,
        MAX(timestamp) as last_record,
        AVG(weight) as avg_weight,
        MIN(weight) as min_weight,
        MAX(weight) as max_weight,
        AVG(bmi) as avg_bmi,
        AVG(bodyFatPercentage) as avg_body_fat,
        AVG(skeletalMusclePercentage) as avg_muscle,
        AVG(visceralFatLevel) as avg_visceral_fat,
        AVG(subcutaneousFatPercentage) as avg_subcutaneous_fat,
        AVG(sameAgeComparison) as avg_same_age_comparison
      FROM omron_data 
      WHERE patientName = ?
    ''', [patientName]);

    if (countResult.isNotEmpty) {
      final result = countResult.first;
      return {
        'totalRecords': result['total_records'] as int,
        'firstRecord': result['first_record'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(result['first_record'] as int)
          : null,
        'lastRecord': result['last_record'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(result['last_record'] as int)
          : null,
        'avgWeight': (result['avg_weight'] as double?)?.toDouble() ?? 0.0,
        'minWeight': (result['min_weight'] as double?)?.toDouble() ?? 0.0,
        'maxWeight': (result['max_weight'] as double?)?.toDouble() ?? 0.0,
        'avgBmi': (result['avg_bmi'] as double?)?.toDouble() ?? 0.0,
        'avgBodyFat': (result['avg_body_fat'] as double?)?.toDouble() ?? 0.0,
        'avgMuscle': (result['avg_muscle'] as double?)?.toDouble() ?? 0.0,
        'avgVisceralFat': (result['avg_visceral_fat'] as double?)?.toDouble() ?? 0.0,
        'avgSubcutaneousFat': (result['avg_subcutaneous_fat'] as double?)?.toDouble() ?? 0.0,
        'avgSameAgeComparison': (result['avg_same_age_comparison'] as double?)?.toDouble() ?? 50.0,
      };
    }
    
    return {
      'totalRecords': 0,
      'firstRecord': null,
      'lastRecord': null,
      'avgWeight': 0.0,
      'minWeight': 0.0,
      'maxWeight': 0.0,
      'avgBmi': 0.0,
      'avgBodyFat': 0.0,
      'avgMuscle': 0.0,
      'avgVisceralFat': 0.0,
      'avgSubcutaneousFat': 0.0,
      'avgSameAgeComparison': 50.0,
    };
  }

  // Get overall statistics
  Future<Map<String, dynamic>> getOverallStatistics() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT patientName) as total_patients,
        MIN(timestamp) as first_record,
        MAX(timestamp) as last_record,
        AVG(weight) as avg_weight,
        AVG(bmi) as avg_bmi,
        AVG(bodyFatPercentage) as avg_body_fat,
        AVG(skeletalMusclePercentage) as avg_muscle,
        AVG(visceralFatLevel) as avg_visceral_fat,
        AVG(subcutaneousFatPercentage) as avg_subcutaneous_fat,
        AVG(sameAgeComparison) as avg_same_age_comparison
      FROM omron_data
    ''');

    if (result.isNotEmpty) {
      final stats = result.first;
      return {
        'totalRecords': stats['total_records'] as int,
        'totalPatients': stats['total_patients'] as int,
        'firstRecord': stats['first_record'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(stats['first_record'] as int)
          : null,
        'lastRecord': stats['last_record'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(stats['last_record'] as int)
          : null,
        'avgWeight': (stats['avg_weight'] as double?)?.toDouble() ?? 0.0,
        'avgBmi': (stats['avg_bmi'] as double?)?.toDouble() ?? 0.0,
        'avgBodyFat': (stats['avg_body_fat'] as double?)?.toDouble() ?? 0.0,
        'avgMuscle': (stats['avg_muscle'] as double?)?.toDouble() ?? 0.0,
        'avgVisceralFat': (stats['avg_visceral_fat'] as double?)?.toDouble() ?? 0.0,
        'avgSubcutaneousFat': (stats['avg_subcutaneous_fat'] as double?)?.toDouble() ?? 0.0,
        'avgSameAgeComparison': (stats['avg_same_age_comparison'] as double?)?.toDouble() ?? 50.0,
      };
    }
    
    return {
      'totalRecords': 0,
      'totalPatients': 0,
      'firstRecord': null,
      'lastRecord': null,
      'avgWeight': 0.0,
      'avgBmi': 0.0,
      'avgBodyFat': 0.0,
      'avgMuscle': 0.0,
      'avgVisceralFat': 0.0,
      'avgSubcutaneousFat': 0.0,
      'avgSameAgeComparison': 50.0,
    };
  }

  // Search functionality
  Future<List<OmronData>> searchOmronData({
    String? patientName,
    double? minWeight,
    double? maxWeight,
    double? minBmi,
    double? maxBmi,
    double? minBodyFat,
    double? maxBodyFat,
    int? minAge,
    int? maxAge,
    String? gender,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> args = [];
    
    if (patientName != null && patientName.isNotEmpty) {
      conditions.add('patientName LIKE ?');
      args.add('%$patientName%');
    }
    
    if (minWeight != null) {
      conditions.add('weight >= ?');
      args.add(minWeight);
    }
    
    if (maxWeight != null) {
      conditions.add('weight <= ?');
      args.add(maxWeight);
    }
    
    if (minBmi != null) {
      conditions.add('bmi >= ?');
      args.add(minBmi);
    }
    
    if (maxBmi != null) {
      conditions.add('bmi <= ?');
      args.add(maxBmi);
    }
    
    if (minBodyFat != null) {
      conditions.add('bodyFatPercentage >= ?');
      args.add(minBodyFat);
    }
    
    if (maxBodyFat != null) {
      conditions.add('bodyFatPercentage <= ?');
      args.add(maxBodyFat);
    }
    
    if (minAge != null) {
      conditions.add('age >= ?');
      args.add(minAge);
    }
    
    if (maxAge != null) {
      conditions.add('age <= ?');
      args.add(maxAge);
    }
    
    if (gender != null && gender.isNotEmpty) {
      conditions.add('gender = ?');
      args.add(gender);
    }
    
    if (startDate != null) {
      conditions.add('timestamp >= ?');
      args.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      conditions.add('timestamp <= ?');
      args.add(endDate.millisecondsSinceEpoch);
    }
    
    String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM omron_data 
      $whereClause
      ORDER BY timestamp DESC
    ''', args);

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Export data as CSV string
  Future<String> exportDataAsCSV({String? patientName}) async {
    List<OmronData> data;
    
    if (patientName != null && patientName.isNotEmpty) {
      data = await getOmronDataByPatient(patientName);
    } else {
      data = await getAllOmronData();
    }
    
    StringBuffer csv = StringBuffer();
    
    // CSV Header
    csv.writeln('ID,Timestamp,Patient Name,Age,Gender,Height,Weight,Body Fat %,BMI,'
        'Skeletal Muscle %,Visceral Fat Level,Resting Metabolism,Body Age,'
        'Subcutaneous Fat %,Trunk Sub Fat,Right Arm Sub Fat,Left Arm Sub Fat,'
        'Right Leg Sub Fat,Left Leg Sub Fat,Trunk Muscle,Right Arm Muscle,'
        'Left Arm Muscle,Right Leg Muscle,Left Leg Muscle,Same Age Comparison,'
        'BMI Category,Body Fat Category,Overall Assessment,Same Age Category');
    
    // CSV Data
    for (OmronData item in data) {
      csv.writeln('${item.id},${item.timestamp.toIso8601String()},'
          '"${item.patientName}",${item.age},"${item.gender}",${item.height},'
          '${item.weight},${item.bodyFatPercentage},${item.bmi},'
          '${item.skeletalMusclePercentage},${item.visceralFatLevel},'
          '${item.restingMetabolism},${item.bodyAge},${item.subcutaneousFatPercentage},'
          '${item.segmentalSubcutaneousFat['trunk']},'
          '${item.segmentalSubcutaneousFat['rightArm']},'
          '${item.segmentalSubcutaneousFat['leftArm']},'
          '${item.segmentalSubcutaneousFat['rightLeg']},'
          '${item.segmentalSubcutaneousFat['leftLeg']},'
          '${item.segmentalSkeletalMuscle['trunk']},'
          '${item.segmentalSkeletalMuscle['rightArm']},'
          '${item.segmentalSkeletalMuscle['leftArm']},'
          '${item.segmentalSkeletalMuscle['rightLeg']},'
          '${item.segmentalSkeletalMuscle['leftLeg']},'
          '${item.sameAgeComparison},"${item.bmiCategory}",'
          '"${item.bodyFatCategory}","${item.overallAssessment}",'
          '"${item.sameAgeCategory}"');
    }
    
    return csv.toString();
  }

  // Backup database
  Future<List<Map<String, dynamic>>> backupDatabase() async {
    final db = await database;
    return await db.query('omron_data', orderBy: 'timestamp ASC');
  }

  // Restore database from backup
  Future<int> restoreDatabase(List<Map<String, dynamic>> backupData) async {
    final db = await database;
    
    // Clear existing data
    await db.delete('omron_data');
    
    int restoredCount = 0;
    
    // Insert backup data
    for (Map<String, dynamic> item in backupData) {
      // Remove id to let database auto-increment
      item.remove('id');
      await db.insert('omron_data', item);
      restoredCount++;
    }
    
    return restoredCount;
  }

  // Clear all data
  Future<int> clearAllData() async {
    final db = await database;
    return await db.delete('omron_data');
  }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name != 'android_metadata' AND name != 'sqlite_sequence'"
    );
    
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
    );
    
    final version = await db.getVersion();
    final path = db.path;
    
    return {
      'version': version,
      'path': path,
      'tables': tables.map((t) => t['name']).toList(),
      'indexes': indexes.map((i) => i['name']).toList(),
    };
  }

  // Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}