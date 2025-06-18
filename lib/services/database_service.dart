import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/omron_data.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'omron_data';

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'omron_data.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
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
        bodyAge INTEGER NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_patient_timestamp ON $_tableName (patientName, timestamp DESC)
    ''');
  }

  // Insert new record
  Future<int> insertOmronData(OmronData data) async {
    final db = await database;
    return await db.insert(_tableName, data.toMap());
  }

  // Get all records
  Future<List<OmronData>> getAllOmronData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Get records by patient name
  Future<List<OmronData>> getOmronDataByPatient(String patientName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'patientName = ?',
      whereArgs: [patientName],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Get records within date range
  Future<List<OmronData>> getOmronDataByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? patientName,
  }) async {
    final db = await database;
    
    String whereClause = 'timestamp BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ];

    if (patientName != null) {
      whereClause += ' AND patientName = ?';
      whereArgs.add(patientName);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return OmronData.fromMap(maps[i]);
    });
  }

  // Update record
  Future<int> updateOmronData(OmronData data) async {
    final db = await database;
    return await db.update(
      _tableName,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  // Delete record
  Future<int> deleteOmronData(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get unique patient names
  Future<List<String>> getPatientNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      columns: ['patientName'],
      distinct: true,
      orderBy: 'patientName ASC',
    );

    return maps.map((map) => map['patientName'] as String).toList();
  }

  // Get latest record for patient
  Future<OmronData?> getLatestOmronData(String patientName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'patientName = ?',
      whereArgs: [patientName],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return OmronData.fromMap(maps.first);
    }
    return null;
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics({String? patientName}) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (patientName != null) {
      whereClause = 'WHERE patientName = ?';
      whereArgs.add(patientName);
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalRecords,
        AVG(weight) as avgWeight,
        AVG(bodyFatPercentage) as avgBodyFat,
        AVG(bmi) as avgBMI,
        AVG(skeletalMusclePercentage) as avgMuscle,
        AVG(visceralFatLevel) as avgVisceralFat,
        MIN(timestamp) as firstRecord,
        MAX(timestamp) as lastRecord
      FROM $_tableName $whereClause
    ''', whereArgs);

    if (result.isNotEmpty) {
      return result.first;
    }
    return {};
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
