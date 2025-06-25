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
      version: 5, // NAIK VERSION UNTUK FIELD WHATSAPP STATUS
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
        whatsappNumber TEXT,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        bodyFatPercentage REAL NOT NULL,
        bmi REAL NOT NULL,
        skeletalMusclePercentage REAL NOT NULL,
        visceralFatLevel REAL NOT NULL,
        restingMetabolism INTEGER NOT NULL,
        bodyAge INTEGER NOT NULL,
        subcutaneousFatPercentage REAL NOT NULL DEFAULT 0.0,
        segmentalSubcutaneousFat TEXT NOT NULL DEFAULT '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}',
        segmentalSkeletalMuscle TEXT NOT NULL DEFAULT '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}',
        sameAgeComparison REAL NOT NULL DEFAULT 50.0,
        isWhatsAppSent INTEGER NOT NULL DEFAULT 0,
        whatsappSentAt INTEGER
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_patient_name ON omron_data(patientName)');
    await db.execute('CREATE INDEX idx_timestamp ON omron_data(timestamp)');
    await db.execute('CREATE INDEX idx_patient_timestamp ON omron_data(patientName, timestamp)');
    await db.execute('CREATE INDEX idx_whatsapp ON omron_data(whatsappNumber)');
    await db.execute('CREATE INDEX idx_whatsapp_sent ON omron_data(isWhatsAppSent)'); // INDEX BARU
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE omron_data ADD COLUMN subcutaneousFatPercentage REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE omron_data ADD COLUMN segmentalSubcutaneousFat TEXT NOT NULL DEFAULT \'{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}\'');
      await db.execute('ALTER TABLE omron_data ADD COLUMN segmentalSkeletalMuscle TEXT NOT NULL DEFAULT \'{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}\'');
      await db.execute('ALTER TABLE omron_data ADD COLUMN sameAgeComparison REAL NOT NULL DEFAULT 50.0');
    }
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE omron_data ADD COLUMN whatsappNumber TEXT');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_whatsapp ON omron_data(whatsappNumber)');
    }
    
    if (oldVersion < 4) {
      // Upgrade visceral fat ke REAL
      await db.execute('''
        CREATE TABLE omron_data_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          patientName TEXT NOT NULL,
          whatsappNumber TEXT,
          age INTEGER NOT NULL,
          gender TEXT NOT NULL,
          height REAL NOT NULL,
          weight REAL NOT NULL,
          bodyFatPercentage REAL NOT NULL,
          bmi REAL NOT NULL,
          skeletalMusclePercentage REAL NOT NULL,
          visceralFatLevel REAL NOT NULL,
          restingMetabolism INTEGER NOT NULL,
          bodyAge INTEGER NOT NULL,
          subcutaneousFatPercentage REAL NOT NULL DEFAULT 0.0,
          segmentalSubcutaneousFat TEXT NOT NULL DEFAULT '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}',
          segmentalSkeletalMuscle TEXT NOT NULL DEFAULT '{"trunk": 0.0, "rightArm": 0.0, "leftArm": 0.0, "rightLeg": 0.0, "leftLeg": 0.0}',
          sameAgeComparison REAL NOT NULL DEFAULT 50.0
        )
      ''');
      
      await db.execute('''
        INSERT INTO omron_data_new 
        SELECT 
          id, timestamp, patientName, whatsappNumber, age, gender, height, weight,
          bodyFatPercentage, bmi, skeletalMusclePercentage, CAST(visceralFatLevel AS REAL) as visceralFatLevel,
          restingMetabolism, bodyAge, subcutaneousFatPercentage, segmentalSubcutaneousFat,
          segmentalSkeletalMuscle, sameAgeComparison
        FROM omron_data
      ''');
      
      await db.execute('DROP TABLE omron_data');
      await db.execute('ALTER TABLE omron_data_new RENAME TO omron_data');
    }
    
    // UPGRADE BARU: Tambah field WhatsApp status
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE omron_data ADD COLUMN isWhatsAppSent INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE omron_data ADD COLUMN whatsappSentAt INTEGER');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_whatsapp_sent ON omron_data(isWhatsAppSent)');
    }
    
    // Create indexes if they don't exist
    await db.execute('CREATE INDEX IF NOT EXISTS idx_patient_name ON omron_data(patientName)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_timestamp ON omron_data(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_patient_timestamp ON omron_data(patientName, timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_whatsapp ON omron_data(whatsappNumber)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_whatsapp_sent ON omron_data(isWhatsAppSent)');
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

  // Get Omron data by WhatsApp number
  Future<List<OmronData>> getOmronDataByWhatsApp(String whatsappNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: 'whatsappNumber = ?',
      whereArgs: [whatsappNumber],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // METHOD BARU: Update status WhatsApp pengiriman
  Future<int> updateWhatsAppSentStatus(int id, {required bool isSent}) async {
    final db = await database;
    return await db.update(
      'omron_data',
      {
        'isWhatsAppSent': isSent ? 1 : 0,
        'whatsappSentAt': isSent ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // METHOD BARU: Batch update status WhatsApp untuk multiple records
  Future<void> batchUpdateWhatsAppStatus(List<int> ids, {required bool isSent}) async {
    final db = await database;
    final batch = db.batch();
    
    for (int id in ids) {
      batch.update(
        'omron_data',
        {
          'isWhatsAppSent': isSent ? 1 : 0,
          'whatsappSentAt': isSent ? DateTime.now().millisecondsSinceEpoch : null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit();
  }

  // METHOD BARU: Get data yang belum dikirim WhatsApp
  Future<List<OmronData>> getUnsentWhatsAppData({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: 'isWhatsAppSent = 0 AND whatsappNumber IS NOT NULL AND whatsappNumber != ""',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // METHOD BARU: Get data yang sudah dikirim WhatsApp
  Future<List<OmronData>> getSentWhatsAppData({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: 'isWhatsAppSent = 1',
      orderBy: 'whatsappSentAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // METHOD BARU: Get statistik WhatsApp
  Future<Map<String, dynamic>> getWhatsAppStatistics() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_records,
        SUM(CASE WHEN whatsappNumber IS NOT NULL AND whatsappNumber != "" THEN 1 ELSE 0 END) as with_whatsapp,
        SUM(CASE WHEN isWhatsAppSent = 1 THEN 1 ELSE 0 END) as sent_whatsapp,
        SUM(CASE WHEN isWhatsAppSent = 0 AND whatsappNumber IS NOT NULL AND whatsappNumber != "" THEN 1 ELSE 0 END) as pending_whatsapp
      FROM omron_data
    ''');

    if (result.isNotEmpty) {
      final stats = result.first;
      return {
        'totalRecords': stats['total_records'] as int,
        'withWhatsApp': stats['with_whatsapp'] as int,
        'sentWhatsApp': stats['sent_whatsapp'] as int,
        'pendingWhatsApp': stats['pending_whatsapp'] as int,
      };
    }
    
    return {
      'totalRecords': 0,
      'withWhatsApp': 0,
      'sentWhatsApp': 0,
      'pendingWhatsApp': 0,
    };
  }

  // Get latest data with WhatsApp number
  Future<List<OmronData>> getLatestDataWithWhatsApp({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: 'whatsappNumber IS NOT NULL AND whatsappNumber != ""',
      orderBy: 'timestamp DESC',
      limit: limit,
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
    bool? whatsappSentStatus, // PARAMETER BARU
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    if (patientName != null && patientName.isNotEmpty) {
      conditions.add('patientName = ?');
      whereArgs.add(patientName);
    }
    
    // FILTER BARU: berdasarkan status WhatsApp
    if (whatsappSentStatus != null) {
      conditions.add('isWhatsAppSent = ?');
      whereArgs.add(whatsappSentStatus ? 1 : 0);
    }
    
    String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    
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
    bool? whatsappSentStatus, // PARAMETER BARU
  }) async {
    final db = await database;
    
    List<String> conditions = ['timestamp BETWEEN ? AND ?'];
    List<dynamic> whereArgs = [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ];
    
    if (patientName != null && patientName.isNotEmpty) {
      conditions.add('patientName = ?');
      whereArgs.add(patientName);
    }
    
    // FILTER BARU: berdasarkan status WhatsApp
    if (whatsappSentStatus != null) {
      conditions.add('isWhatsAppSent = ?');
      whereArgs.add(whatsappSentStatus ? 1 : 0);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'omron_data',
      where: conditions.join(' AND '),
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

  // Update WhatsApp number for existing patient
  Future<int> updateWhatsAppNumber(String patientName, String? whatsappNumber) async {
    final db = await database;
    return await db.update(
      'omron_data',
      {'whatsappNumber': whatsappNumber},
      where: 'patientName = ?',
      whereArgs: [patientName],
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

  // Get all unique WhatsApp numbers
  Future<List<String>> getWhatsAppNumbers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT whatsappNumber FROM omron_data WHERE whatsappNumber IS NOT NULL AND whatsappNumber != "" ORDER BY whatsappNumber ASC'
    );

    return List.generate(maps.length, (i) {
      return maps[i]['whatsappNumber'] as String;
    });
  }

  // Get patient info with WhatsApp
  Future<List<Map<String, dynamic>>> getPatientsWithWhatsApp() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        patientName,
        whatsappNumber,
        COUNT(*) as recordCount,
        MAX(timestamp) as lastRecord,
        SUM(CASE WHEN isWhatsAppSent = 1 THEN 1 ELSE 0 END) as sentCount,
        SUM(CASE WHEN isWhatsAppSent = 0 THEN 1 ELSE 0 END) as pendingCount
      FROM omron_data 
      WHERE whatsappNumber IS NOT NULL AND whatsappNumber != ""
      GROUP BY patientName, whatsappNumber
      ORDER BY lastRecord DESC
    ''');

    return maps.map((map) => {
      'patientName': map['patientName'] as String,
      'whatsappNumber': map['whatsappNumber'] as String,
      'recordCount': map['recordCount'] as int,
      'lastRecord': DateTime.fromMillisecondsSinceEpoch(map['lastRecord'] as int),
      'sentCount': map['sentCount'] as int, // FIELD BARU
      'pendingCount': map['pendingCount'] as int, // FIELD BARU
    }).toList();
  }

  // Get patient statistics - UPDATED dengan WhatsApp stats
  Future<Map<String, dynamic>> getPatientStatistics(String patientName) async {
    final db = await database;
    
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
        AVG(sameAgeComparison) as avg_same_age_comparison,
        whatsappNumber,
        SUM(CASE WHEN isWhatsAppSent = 1 THEN 1 ELSE 0 END) as sent_whatsapp,
        SUM(CASE WHEN isWhatsAppSent = 0 AND whatsappNumber IS NOT NULL THEN 1 ELSE 0 END) as pending_whatsapp
      FROM omron_data 
      WHERE patientName = ?
      GROUP BY whatsappNumber
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
        'whatsappNumber': result['whatsappNumber'] as String?,
        'sentWhatsApp': result['sent_whatsapp'] as int, // FIELD BARU
        'pendingWhatsApp': result['pending_whatsapp'] as int, // FIELD BARU
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
      'whatsappNumber': null,
      'sentWhatsApp': 0,
      'pendingWhatsApp': 0,
    };
  }

  // Get overall statistics - UPDATED dengan WhatsApp stats
  Future<Map<String, dynamic>> getOverallStatistics() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT patientName) as total_patients,
        COUNT(DISTINCT whatsappNumber) as total_whatsapp,
        MIN(timestamp) as first_record,
        MAX(timestamp) as last_record,
        AVG(weight) as avg_weight,
        AVG(bmi) as avg_bmi,
        AVG(bodyFatPercentage) as avg_body_fat,
        AVG(skeletalMusclePercentage) as avg_muscle,
        AVG(visceralFatLevel) as avg_visceral_fat,
        AVG(subcutaneousFatPercentage) as avg_subcutaneous_fat,
        AVG(sameAgeComparison) as avg_same_age_comparison,
        SUM(CASE WHEN isWhatsAppSent = 1 THEN 1 ELSE 0 END) as sent_whatsapp,
        SUM(CASE WHEN isWhatsAppSent = 0 AND whatsappNumber IS NOT NULL THEN 1 ELSE 0 END) as pending_whatsapp
      FROM omron_data
    ''');

    if (result.isNotEmpty) {
      final stats = result.first;
      return {
        'totalRecords': stats['total_records'] as int,
        'totalPatients': stats['total_patients'] as int,
        'totalWhatsApp': stats['total_whatsapp'] as int,
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
        'sentWhatsApp': stats['sent_whatsapp'] as int, // FIELD BARU
        'pendingWhatsApp': stats['pending_whatsapp'] as int, // FIELD BARU
      };
    }
    
    return {
      'totalRecords': 0,
      'totalPatients': 0,
      'totalWhatsApp': 0,
      'firstRecord': null,
      'lastRecord': null,
      'avgWeight': 0.0,
      'avgBmi': 0.0,
      'avgBodyFat': 0.0,
      'avgMuscle': 0.0,
      'avgVisceralFat': 0.0,
      'avgSubcutaneousFat': 0.0,
      'avgSameAgeComparison': 50.0,
      'sentWhatsApp': 0,
      'pendingWhatsApp': 0,
    };
  }

  // Search functionality - UPDATED dengan filter WhatsApp status
  Future<List<OmronData>> searchOmronData({
    String? patientName,
    String? whatsappNumber,
    double? minWeight,
    double? maxWeight,
    double? minBmi,
    double? maxBmi,
    double? minBodyFat,
    double? maxBodyFat,
    double? minVisceralFat,
    double? maxVisceralFat,
    int? minAge,
    int? maxAge,
    String? gender,
    DateTime? startDate,
    DateTime? endDate,
    bool? whatsappSentStatus, // PARAMETER BARU
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> args = [];
    
    if (patientName != null && patientName.isNotEmpty) {
      conditions.add('patientName LIKE ?');
      args.add('%$patientName%');
    }
    
    if (whatsappNumber != null && whatsappNumber.isNotEmpty) {
      conditions.add('whatsappNumber LIKE ?');
      args.add('%$whatsappNumber%');
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
    
    if (minVisceralFat != null) {
      conditions.add('visceralFatLevel >= ?');
      args.add(minVisceralFat);
    }
    
    if (maxVisceralFat != null) {
      conditions.add('visceralFatLevel <= ?');
      args.add(maxVisceralFat);
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
    
    // FILTER BARU: berdasarkan status WhatsApp
    if (whatsappSentStatus != null) {
      conditions.add('isWhatsAppSent = ?');
      args.add(whatsappSentStatus ? 1 : 0);
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

  // Export data as CSV string - UPDATED dengan WhatsApp status
  Future<String> exportDataAsCSV({String? patientName}) async {
    List<OmronData> data;
    
    if (patientName != null && patientName.isNotEmpty) {
      data = await getOmronDataByPatient(patientName);
    } else {
      data = await getAllOmronData();
    }
    
    StringBuffer csv = StringBuffer();
    
    // CSV Header - TAMBAH WHATSAPP STATUS COLUMNS
    csv.writeln('ID,Timestamp,Patient Name,WhatsApp Number,Age,Gender,Height,Weight,Body Fat %,BMI,'
        'Skeletal Muscle %,Visceral Fat Level,Resting Metabolism,Body Age,'
        'Subcutaneous Fat %,Trunk Sub Fat,Right Arm Sub Fat,Left Arm Sub Fat,'
        'Right Leg Sub Fat,Left Leg Sub Fat,Trunk Muscle,Right Arm Muscle,'
        'Left Arm Muscle,Right Leg Muscle,Left Leg Muscle,Same Age Comparison,'
        'BMI Category,Body Fat Category,Overall Assessment,Same Age Category,'
        'WhatsApp Sent,WhatsApp Sent At');
    
    // CSV Data
    for (OmronData item in data) {
      csv.writeln('${item.id},${item.timestamp.toIso8601String()},'
          '"${item.patientName}","${item.whatsappNumber ?? ''}",'
          '${item.age},"${item.gender}",${item.height},'
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
          '"${item.sameAgeCategory}","${item.isWhatsAppSent ? 'Yes' : 'No'}",'
          '"${item.whatsappSentAt?.toIso8601String() ?? ''}"');
    }
    
    return csv.toString();
  }

  // [Method lainnya tetap sama: backupDatabase, restoreDatabase, clearAllData, getDatabaseInfo, closeDatabase]
  Future<List<Map<String, dynamic>>> backupDatabase() async {
    final db = await database;
    return await db.query('omron_data', orderBy: 'timestamp ASC');
  }

  Future<int> restoreDatabase(List<Map<String, dynamic>> backupData) async {
    final db = await database;
    
    await db.delete('omron_data');
    
    int restoredCount = 0;
    
    for (Map<String, dynamic> item in backupData) {
      item.remove('id');
      await db.insert('omron_data', item);
      restoredCount++;
    }
    
    return restoredCount;
  }

  Future<int> clearAllData() async {
    final db = await database;
    return await db.delete('omron_data');
  }

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

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}