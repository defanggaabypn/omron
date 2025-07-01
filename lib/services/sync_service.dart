import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/omron_data.dart';
import 'api_service.dart';
import 'database_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  noInternet,
}

enum SyncType {
  patients,
  omronData,
  all,
}

class SyncResult {
  final bool success;
  final String message;
  final int? uploadedCount;
  final int? downloadedCount;
  final int? conflictCount;
  final DateTime timestamp;
  final SyncType type;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount,
    this.downloadedCount,
    this.conflictCount,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'uploadedCount': uploadedCount,
      'downloadedCount': downloadedCount,
      'conflictCount': conflictCount,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
    };
  }

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'],
      message: json['message'],
      uploadedCount: json['uploadedCount'],
      downloadedCount: json['downloadedCount'],
      conflictCount: json['conflictCount'],
      timestamp: DateTime.parse(json['timestamp']),
      type: SyncType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SyncType.all,
      ),
    );
  }
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  // Stream controllers untuk real-time updates
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  // Getters untuk streams
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get messageStream => _messageController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  Timer? _autoSyncTimer;
  bool _isAutoSyncEnabled = false;

  // Preferences keys
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const String _syncHistoryKey = 'sync_history';

  SyncStatus get currentStatus => _currentStatus;

  /// Initialize sync service
  Future<void> initialize() async {
    await _loadSettings();
    await _startAutoSyncIfEnabled();
  }

  /// Load sync settings from preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isAutoSyncEnabled = prefs.getBool(_autoSyncKey) ?? false;
  }

  /// Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Test actual internet connection
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Update progress
  void _updateProgress(double progress) {
    _progressController.add(progress);
  }

  /// Update message
  void _updateMessage(String message) {
    _messageController.add(message);
  }

  /// Sync all data (patients + omron data)
  Future<SyncResult> syncAll({bool forceSync = false}) async {
    if (_currentStatus == SyncStatus.syncing && !forceSync) {
      return SyncResult(
        success: false,
        message: 'Sinkronisasi sedang berjalan',
        timestamp: DateTime.now(),
        type: SyncType.all,
      );
    }

    _updateStatus(SyncStatus.syncing);
    _updateProgress(0.0);
    _updateMessage('Memulai sinkronisasi...');

    try {
      // Check internet connection
      if (!await _hasInternetConnection()) {
        _updateStatus(SyncStatus.noInternet);
        return SyncResult(
          success: false,
          message: 'Tidak ada koneksi internet',
          timestamp: DateTime.now(),
          type: SyncType.all,
        );
      }

      int totalUploaded = 0;
      int totalDownloaded = 0;
      int totalConflicts = 0;

      // Sync patients (50% of progress)
      _updateMessage('Sinkronisasi data pasien...');
      final patientResult = await syncPatients();
      totalUploaded += patientResult.uploadedCount ?? 0;
      totalDownloaded += patientResult.downloadedCount ?? 0;
      totalConflicts += patientResult.conflictCount ?? 0;
      _updateProgress(0.5);

      // Sync omron data (remaining 50%)
      _updateMessage('Sinkronisasi data Omron...');
      final omronResult = await syncOmronData();
      totalUploaded += omronResult.uploadedCount ?? 0;
      totalDownloaded += omronResult.downloadedCount ?? 0;
      totalConflicts += omronResult.conflictCount ?? 0;
      _updateProgress(1.0);

      final success = patientResult.success && omronResult.success;
      
      if (success) {
        await _saveLastSyncTime();
        _updateStatus(SyncStatus.success);
        _updateMessage('Sinkronisasi berhasil');
      } else {
        _updateStatus(SyncStatus.failed);
        _updateMessage('Sinkronisasi gagal sebagian');
      }

      final result = SyncResult(
        success: success,
        message: success 
          ? 'Sinkronisasi berhasil. Upload: $totalUploaded, Download: $totalDownloaded'
          : 'Sinkronisasi gagal sebagian',
        uploadedCount: totalUploaded,
        downloadedCount: totalDownloaded,
        conflictCount: totalConflicts,
        timestamp: DateTime.now(),
        type: SyncType.all,
      );

      await _saveSyncHistory(result);
      return result;

    } catch (e) {
      _updateStatus(SyncStatus.failed);
      _updateMessage('Error: $e');
      
      final result = SyncResult(
        success: false,
        message: 'Sinkronisasi gagal: $e',
        timestamp: DateTime.now(),
        type: SyncType.all,
      );
      
      await _saveSyncHistory(result);
      return result;
    }
  }

  /// Sync patients only - FIXED VERSION
  Future<SyncResult> syncPatients() async {
    try {
      _updateMessage('Mengunduh data pasien dari server...');
      
      // Get server patients - handle PaginatedResponse correctly
      final serverPatientsResponse = await _apiService.getPatients();
      final serverPatients = serverPatientsResponse.data; // Extract List<Patient> from PaginatedResponse
      
      int downloadedCount = 0;
      int conflictCount = 0;

      // Download and merge patients
      for (final serverPatient in serverPatients) {
        final existingPatient = await _databaseService.getPatientByWhatsApp(
          serverPatient.whatsapp // Use correct field name from Patient model
        );

        if (existingPatient != null) {
          // Check for conflicts - compare based on available fields
          if (_hasPatientConflict(existingPatient, serverPatient)) {
            conflictCount++;
            // Convert Patient to Map for database insertion
            await _databaseService.insertPatient(_patientToMap(serverPatient));
          }
        } else {
          // Convert Patient to Map for database insertion
          await _databaseService.insertPatient(_patientToMap(serverPatient));
          downloadedCount++;
        }
      }

      _updateMessage('Mengunggah data pasien ke server...');
      
      // Upload local patients that don't exist on server
      final localPatientsData = await _databaseService.getAllPatients();
      final localPatients = localPatientsData.map((data) => _mapToPatient(data)).toList();
      int uploadedCount = 0;

      for (final localPatient in localPatients) {
        if (!serverPatients.any((p) => p.whatsapp == localPatient.whatsapp)) {
          try {
            await _apiService.createPatient(localPatient);
            uploadedCount++;
          } catch (e) {
            debugPrint('Failed to upload patient ${localPatient.nama}: $e');
          }
        }
      }

      return SyncResult(
        success: true,
        message: 'Sinkronisasi pasien berhasil',
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        conflictCount: conflictCount,
        timestamp: DateTime.now(),
        type: SyncType.patients,
      );

    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Gagal sinkronisasi pasien: $e',
        timestamp: DateTime.now(),
        type: SyncType.patients,
      );
    }
  }

  /// Sync Omron data only - FIXED VERSION
  Future<SyncResult> syncOmronData() async {
    try {
      _updateMessage('Mengunduh data Omron dari server...');
      
      // Get server omron data - handle PaginatedResponse correctly
      final serverDataResponse = await _apiService.getOmronData();
      final serverData = serverDataResponse.data; // Extract List<OmronData> from PaginatedResponse
      
      int downloadedCount = 0;
      int conflictCount = 0;

      // Download and merge omron data
      for (final serverOmron in serverData) {
        if (serverOmron.id != null) {
          final existingData = await _databaseService.getOmronDataById(serverOmron.id!);

          if (existingData != null) {
            // Check for conflicts
            if (_hasOmronConflict(existingData, serverOmron)) {
              conflictCount++;
              // Update existing data
              await _databaseService.updateOmronData(serverOmron);
            }
          } else {
            await _databaseService.insertOmronData(serverOmron);
            downloadedCount++;
          }
        }
      }

      _updateMessage('Mengunggah data Omron ke server...');
      
      // Upload local omron data that don't exist on server
      final localData = await _databaseService.getAllOmronData();
      int uploadedCount = 0;

      for (final localOmron in localData) {
        if (localOmron.id == null || !serverData.any((d) => d.id == localOmron.id)) {
          try {
            await _apiService.createOmronData(localOmron);
            uploadedCount++;
          } catch (e) {
            debugPrint('Failed to upload omron data ${localOmron.id}: $e');
          }
        }
      }

      return SyncResult(
        success: true,
        message: 'Sinkronisasi data Omron berhasil',
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        conflictCount: conflictCount,
        timestamp: DateTime.now(),
        type: SyncType.omronData,
      );

    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Gagal sinkronisasi data Omron: $e',
        timestamp: DateTime.now(),
        type: SyncType.omronData,
      );
    }
  }

  /// Helper: Convert Patient model to Map for database insertion
  Map<String, dynamic> _patientToMap(Patient patient) {
    return {
      'nama': patient.nama,
      'whatsapp': patient.whatsapp,
      'usia': patient.usia,
      'gender': patient.gender,
      'tinggi': patient.tinggi,
      'created_at': patient.createdAt.toIso8601String(),
      'server_id': patient.id?.toString(),
    };
  }

  /// Helper: Convert Map from database to Patient model
  Patient _mapToPatient(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      nama: map['nama'],
      whatsapp: map['whatsapp'],
      usia: map['usia'],
      gender: map['gender'],
      tinggi: map['tinggi'].toDouble(),
      createdAt: map['created_at'] is DateTime 
        ? map['created_at'] 
        : DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      isSynced: map['is_synced'] ?? false,
    );
  }

  /// Check if there's a conflict between local and server patient data
  bool _hasPatientConflict(Map<String, dynamic> localData, Patient serverPatient) {
    // Compare key fields to detect conflicts
    return localData['nama'] != serverPatient.nama ||
           localData['usia'] != serverPatient.usia ||
           localData['gender'] != serverPatient.gender ||
           localData['tinggi'] != serverPatient.tinggi;
  }

  /// Check if there's a conflict between local and server omron data
  bool _hasOmronConflict(OmronData local, OmronData server) {
    // Compare key fields to detect conflicts
    return local.patientName != server.patientName ||
           local.weight != server.weight ||
           local.height != server.height ||
           local.timestamp.isBefore(server.timestamp);
  }

  /// Get all patients (from local database) - FIXED RETURN TYPE
  Future<List<Patient>> getAllPatients() async {
    final patientsData = await _databaseService.getAllPatients();
    return patientsData.map((data) => _mapToPatient(data)).toList();
  }

  /// Get all omron data (from local database)
  Future<List<OmronData>> getAllOmronData() async {
    return await _databaseService.getAllOmronData();
  }

  /// Enable/disable auto sync
  Future<void> setAutoSync(bool enabled, {int intervalMinutes = 30}) async {
    _isAutoSyncEnabled = enabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
    await prefs.setInt(_syncIntervalKey, intervalMinutes);

    if (enabled) {
      await _startAutoSync(intervalMinutes);
    } else {
      _stopAutoSync();
    }
  }

  /// Start auto sync timer
  Future<void> _startAutoSyncIfEnabled() async {
    if (_isAutoSyncEnabled) {
      final prefs = await SharedPreferences.getInstance();
      final intervalMinutes = prefs.getInt(_syncIntervalKey) ?? 30;
      await _startAutoSync(intervalMinutes);
    }
  }

  /// Start auto sync with specified interval
  Future<void> _startAutoSync(int intervalMinutes) async {
    _stopAutoSync(); // Stop existing timer
    
    _autoSyncTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (timer) async {
        if (await _hasInternetConnection()) {
          await syncAll();
        }
      },
    );
  }

  /// Stop auto sync timer
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Save last sync time
  Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get sync history
  Future<List<SyncResult>> getSyncHistory({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_syncHistoryKey) ?? [];
    
    return historyJson
        .map((json) => SyncResult.fromJson(jsonDecode(json)))
        .take(limit)
        .toList();
  }

  /// Save sync result to history
  Future<void> _saveSyncHistory(SyncResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_syncHistoryKey) ?? [];
    
    // Add new result to beginning
    historyJson.insert(0, jsonEncode(result.toJson()));
    
    // Keep only last 50 results
    if (historyJson.length > 50) {
      historyJson.removeRange(50, historyJson.length);
    }
    
    await prefs.setStringList(_syncHistoryKey, historyJson);
  }

  /// Clear sync history
  Future<void> clearSyncHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncHistoryKey);
  }

  /// Force sync (ignore current status)
  Future<SyncResult> forceSync() async {
    return await syncAll(forceSync: true);
  }

  /// Check if sync is needed (based on last sync time and data changes)
  Future<bool> isSyncNeeded() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    // Check if more than 1 hour since last sync
    final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
    if (hoursSinceSync >= 1) return true;

    // Check if there are unsynced patients
    final unsyncedPatients = await _databaseService.getPatientsBySyncStatus(isSynced: false);
    if (unsyncedPatients.isNotEmpty) return true;

    return false;
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final history = await getSyncHistory();
    final lastSync = await getLastSyncTime();
    final dbStats = await _databaseService.getSyncStatistics();
    
    final successfulSyncs = history.where((r) => r.success).length;
    final failedSyncs = history.where((r) => !r.success).length;
    final totalUploaded = history.fold<int>(0, (sum, r) => sum + (r.uploadedCount ?? 0));
    final totalDownloaded = history.fold<int>(0, (sum, r) => sum + (r.downloadedCount ?? 0));

    return {
      'lastSyncTime': lastSync?.toIso8601String(),
      'totalSyncs': history.length,
      'successfulSyncs': successfulSyncs,
      'failedSyncs': failedSyncs,
      'totalUploaded': totalUploaded,
      'totalDownloaded': totalDownloaded,
      'autoSyncEnabled': _isAutoSyncEnabled,
      'currentStatus': _currentStatus.toString(),
      'totalPatients': dbStats['totalPatients'],
      'syncedPatients': dbStats['syncedPatients'],
      'unsyncedPatients': dbStats['unsyncedPatients'],
      'lastPatientSync': dbStats['lastSync']?.toIso8601String(),
    };
  }

  /// Sync specific patient by WhatsApp
  Future<SyncResult> syncPatientByWhatsApp(String whatsapp) async {
    try {
      _updateMessage('Sinkronisasi pasien $whatsapp...');
      
      // Get patient from server
      final serverPatientResponse = await _apiService.getPatientByWhatsApp(whatsapp);
      
      if (serverPatientResponse.success && serverPatientResponse.data != null) {
        final serverPatient = serverPatientResponse.data!;
        
        // Check if exists locally
        final localPatient = await _databaseService.getPatientByWhatsApp(whatsapp);
        
        if (localPatient != null) {
          // Update local patient
          await _databaseService.insertPatient(_patientToMap(serverPatient));
          return SyncResult(
            success: true,
            message: 'Pasien berhasil diperbarui',
            downloadedCount: 1,
            timestamp: DateTime.now(),
            type: SyncType.patients,
          );
        } else {
          // Insert new patient
          await _databaseService.insertPatient(_patientToMap(serverPatient));
          return SyncResult(
            success: true,
            message: 'Pasien berhasil ditambahkan',
            downloadedCount: 1,
            timestamp: DateTime.now(),
            type: SyncType.patients,
          );
        }
      } else {
        return SyncResult(
          success: false,
          message: 'Pasien tidak ditemukan di server',
          timestamp: DateTime.now(),
          type: SyncType.patients,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Gagal sinkronisasi pasien: $e',
        timestamp: DateTime.now(),
        type: SyncType.patients,
      );
    }
  }

  /// Upload single patient to server
  Future<SyncResult> uploadPatient(Patient patient) async {
    try {
      _updateMessage('Mengunggah pasien ${patient.nama}...');
      
      final response = await _apiService.createPatient(patient);
      
      if (response.success) {
        // Update local patient sync status
        if (patient.id != null) {
          await _databaseService.updatePatientSyncStatus(patient.id!, isSynced: true);
        }
        
        return SyncResult(
          success: true,
          message: 'Pasien berhasil diunggah',
          uploadedCount: 1,
          timestamp: DateTime.now(),
          type: SyncType.patients,
        );
      } else {
        return SyncResult(
          success: false,
          message: response.message ?? 'Gagal mengunggah pasien',
          timestamp: DateTime.now(),
          type: SyncType.patients,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error mengunggah pasien: $e',
        timestamp: DateTime.now(),
        type: SyncType.patients,
      );
    }
  }

  /// Upload single omron data to server
  Future<SyncResult> uploadOmronData(OmronData omronData) async {
    try {
      _updateMessage('Mengunggah data Omron...');
      
      final response = await _apiService.createOmronData(omronData);
      
      if (response.success) {
        return SyncResult(
          success: true,
          message: 'Data Omron berhasil diunggah',
          uploadedCount: 1,
          timestamp: DateTime.now(),
          type: SyncType.omronData,
        );
      } else {
        return SyncResult(
          success: false,
          message: response.message ?? 'Gagal mengunggah data Omron',
          timestamp: DateTime.now(),
          type: SyncType.omronData,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error mengunggah data Omron: $e',
        timestamp: DateTime.now(),
        type: SyncType.omronData,
      );
    }
  }

  /// Bulk upload unsynced patients
  Future<SyncResult> uploadUnsyncedPatients() async {
    try {
      _updateMessage('Mengunggah pasien yang belum tersinkronisasi...');
      
      final unsyncedPatients = await _databaseService.getPatientsBySyncStatus(isSynced: false);
      
      if (unsyncedPatients.isEmpty) {
        return SyncResult(
          success: true,
          message: 'Tidak ada pasien yang perlu diunggah',
          uploadedCount: 0,
          timestamp: DateTime.now(),
          type: SyncType.patients,
        );
      }
      
      int uploadedCount = 0;
      int failedCount = 0;
      
      for (final patientData in unsyncedPatients) {
        try {
          final patient = _mapToPatient(patientData);
          final response = await _apiService.createPatient(patient);
          
          if (response.success) {
            await _databaseService.updatePatientSyncStatus(patientData['id'], isSynced: true);
            uploadedCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          debugPrint('Failed to upload patient ${patientData['nama']}: $e');
        }
      }
      
      return SyncResult(
        success: failedCount == 0,
        message: 'Berhasil upload: $uploadedCount, Gagal: $failedCount',
        uploadedCount: uploadedCount,
        timestamp: DateTime.now(),
        type: SyncType.patients,
      );
      
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error bulk upload pasien: $e',
        timestamp: DateTime.now(),
        type: SyncType.patients,
      );
    }
  }

  /// Get sync status for specific patient
  Future<Map<String, dynamic>> getPatientSyncStatus(String whatsapp) async {
    final localPatient = await _databaseService.getPatientByWhatsApp(whatsapp);
    
    if (localPatient == null) {
      return {
        'exists': false,
        'synced': false,
        'lastSync': null,
      };
    }
    
    return {
      'exists': true,
      'synced': localPatient['is_synced'] ?? false,
      'lastSync': localPatient['synced_at'],
      'serverId': localPatient['server_id'],
    };
  }

  /// Reset all sync status (for testing)
  Future<void> resetSyncStatus() async {
    await _databaseService.clearSyncData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }

  /// Dispose resources
  void dispose() {
    _stopAutoSync();
    _statusController.close();
    _progressController.close();
    _messageController.close();
  }
}
