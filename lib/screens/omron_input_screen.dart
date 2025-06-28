import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';
import '../services/database_service.dart';
import '../widgets/omron_result_card.dart';
import '../widgets/patient_info_card.dart';

class OmronInputScreen extends StatefulWidget {
  const OmronInputScreen({Key? key}) : super(key: key);

  @override
  _OmronInputScreenState createState() => _OmronInputScreenState();
}

class _OmronInputScreenState extends State<OmronInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final DatabaseService _databaseService = DatabaseService();
  
  // Patient Info Controllers
  final _patientNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  
  // Basic Omron Data Controllers - UPDATED: Removed Skeletal Muscle
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _bmiController = TextEditingController();
  final _visceralFatController = TextEditingController();
  final _restingMetabolismController = TextEditingController();
  final _bodyAgeController = TextEditingController();
  
  // Segmental Controllers - NEW STRUCTURE (wholeBody, trunk, arms, legs)
  final _segSubWholeBodyController = TextEditingController();
  final _segSubTrunkController = TextEditingController();
  final _segSubArmsController = TextEditingController();
  final _segSubLegsController = TextEditingController();
  
  final _segMusWholeBodyController = TextEditingController();
  final _segMusTrunkController = TextEditingController();
  final _segMusArmsController = TextEditingController();
  final _segMusLegsController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _autoCalculateBMI = true;
  bool _autoCalculateSegmental = false; // CHANGED: Set to false so all fields can be manually input
  OmronData? _calculatedResult;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Auto-calculate BMI when weight or height changes
    _weightController.addListener(_calculateBMI);
    _heightController.addListener(_calculateBMI);
    
    // Auto-calculate segmental data when main values change
    _segSubWholeBodyController.addListener(_calculateSegmentalData);
    _segMusWholeBodyController.addListener(_calculateSegmentalData);

    // Add listener for name formatting
    _patientNameController.addListener(_formatPatientName);
  }

  // FITUR 1: FORMAT NAMA OTOMATIS
  void _formatPatientName() {
    final text = _patientNameController.text;
    final selection = _patientNameController.selection;
    
    // Format nama: kapitalisasi huruf pertama setiap kata
    final formattedText = _capitalizeWords(text);
    
    // Hanya update jika ada perubahan untuk menghindari loop
    if (formattedText != text) {
      _patientNameController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset <= formattedText.length 
            ? selection.baseOffset 
            : formattedText.length,
        ),
      );
    }
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _calculateBMI() {
    if (!_autoCalculateBMI) return;
    
    final weight = OmronData.parseDecimalInput(_weightController.text);
    final height = OmronData.parseDecimalInput(_heightController.text);
    
    if (weight > 0 && height > 0) {
      final heightInMeters = height / 100; // Convert cm to meters
      final bmi = weight / (heightInMeters * heightInMeters);
      _bmiController.text = bmi.toStringAsFixed(1);
    }
  }

  // UPDATED: Calculate segmental data dengan struktur baru
  void _calculateSegmentalData() {
    if (!_autoCalculateSegmental) return;
    
    final subcutaneousFat = OmronData.parseDecimalInput(_segSubWholeBodyController.text);
    final skeletalMuscle = OmronData.parseDecimalInput(_segMusWholeBodyController.text);
    
    if (subcutaneousFat > 0) {
      final segmental = OmronData.calculateSegmentalSubcutaneousFat(subcutaneousFat);
      _segSubTrunkController.text = segmental['trunk']!.toStringAsFixed(1);
      _segSubArmsController.text = segmental['arms']!.toStringAsFixed(1);
      _segSubLegsController.text = segmental['legs']!.toStringAsFixed(1);
    }
    
    if (skeletalMuscle > 0) {
      final segmental = OmronData.calculateSegmentalSkeletalMuscle(skeletalMuscle);
      _segMusTrunkController.text = segmental['trunk']!.toStringAsFixed(1);
      _segMusArmsController.text = segmental['arms']!.toStringAsFixed(1);
      _segMusLegsController.text = segmental['legs']!.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildResponsiveBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LSHC Omron HBF-375',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Body Composition Monitor',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.orange[700],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.pushNamed(context, '/history'),
          tooltip: 'Riwayat Data',
        ),
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () => Navigator.pushNamed(context, '/analytics'),
          tooltip: 'Analisis Data',
        ),
      ],
    );
  }

  Widget _buildResponsiveBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout berdasarkan lebar layar
        if (constraints.maxWidth > 1200) {
          // Desktop layout: Side by side
          return _buildDesktopLayout();
        } else if (constraints.maxWidth > 800) {
          // Tablet layout: Stacked with better spacing
          return _buildTabletLayout();
        } else {
          // Mobile layout: Single column
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Form
        Expanded(
          flex: 2,
          child: SizedBox(
            height: MediaQuery.of(context).size.height - kToolbarHeight,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    PatientInfoCard(
                      patientNameController: _patientNameController,
                      whatsappController: _whatsappController,
                      ageController: _ageController,
                      heightController: _heightController,
                      selectedGender: _selectedGender,
                      onGenderChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildBasicOmronDataCard(),
                    const SizedBox(height: 16),
                    _buildSegmentalDataCard(),
                    const SizedBox(height: 16),
                    _buildCalculateButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right side: Result
        if (_calculatedResult != null)
          Expanded(
            flex: 3,
            child: Container(
              height: MediaQuery.of(context).size.height - kToolbarHeight,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header untuk result dengan tombol simpan yang prominent
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[100]!, Colors.green[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analisis Berhasil! 🎉',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Text(
                                    'Hasil untuk ${_calculatedResult!.patientName} (11/11 Fitur Lengkap)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  if (_calculatedResult!.whatsappNumber != null && _calculatedResult!.whatsappNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.chat, color: Colors.green[600], size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'WA: ${_calculatedResult!.whatsappNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Tombol aksi - FITUR 3: AUTO SAVE BUTTON
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.schedule, color: Colors.orange[700], size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Auto Save dalam 3 detik...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveDataManually,
                              icon: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save, size: 18),
                              label: Text(
                                _isLoading ? 'Menyimpan...' : 'Simpan Sekarang',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Result content
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildSafeResultCard(),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Header + Patient Info
                Expanded(
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      PatientInfoCard(
                        patientNameController: _patientNameController,
                        whatsappController: _whatsappController,
                        ageController: _ageController,
                        heightController: _heightController,
                        selectedGender: _selectedGender,
                        onGenderChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right column: Basic Data
                Expanded(
                  child: _buildBasicOmronDataCard(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(),
            const SizedBox(height: 16),
            _buildCalculateButton(),
            if (_calculatedResult != null) ...[
              const SizedBox(height: 20),
              _buildResultSection(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            PatientInfoCard(
              patientNameController: _patientNameController,
              whatsappController: _whatsappController,
              ageController: _ageController,
              heightController: _heightController,
              selectedGender: _selectedGender,
              onGenderChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildBasicOmronDataCard(),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(),
            const SizedBox(height: 16),
            _buildCalculateButton(),
            if (_calculatedResult != null) ...[
              const SizedBox(height: 20),
              _buildResultSection(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_calculatedResult == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success notification dengan auto save indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[100]!, Colors.green[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan icon dan title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analisis Berhasil! 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          'Semua 11 fitur Omron HBF-375 telah dihitung lengkap',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Patient info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _calculatedResult!.patientName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            '${_calculatedResult!.age} tahun • ${_calculatedResult!.gender} • ${DateFormat('dd/MM/yyyy HH:mm').format(_calculatedResult!.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_calculatedResult!.whatsappNumber != null && _calculatedResult!.whatsappNumber!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.chat, color: Colors.green[600], size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'WA: ${_calculatedResult!.whatsappNumber}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons - FITUR 3: AUTO SAVE dengan countdown
              Row(
                children: [
                  // Auto save indicator
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, color: Colors.orange[700], size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Auto Save dalam 3s...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Manual save button
                  Expanded(
                    flex: 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveDataManually,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                        label: Text(
                          _isLoading ? 'Menyimpan...' : 'Simpan Sekarang',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: _isLoading ? 2 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Fullscreen button
                  IconButton(
                    onPressed: () => _showResultDialog(),
                    icon: Icon(Icons.fullscreen, color: Colors.green[700], size: 24),
                    tooltip: 'Lihat Fullscreen',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.green[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Result card
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: _buildSafeResultCard(),
        ),
      ],
    );
  }

  Widget _buildSafeResultCard() {
    if (_calculatedResult == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('Tidak ada data untuk ditampilkan'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: constraints.maxHeight,
          ),
          child: OmronResultCard(data: _calculatedResult!),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.monitor_weight,
                size: 32,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input Manual Data Lengkap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan data dari display Omron HBF-375 (11 Fitur)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicOmronDataCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '6 Indikator Dasar Omron',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Responsive form layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Two column layout for wider screens
                  return _buildBasicTwoColumnForm();
                } else {
                  // Single column for mobile
                  return _buildBasicSingleColumnForm();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTwoColumnForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNumberInputField(
                controller: _weightController,
                label: 'Berat Badan (kg)',
                icon: Icons.scale,
                hint: 'Contoh: 75,5 atau 75.5',
                suffix: 'kg',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberInputField(
                controller: _bodyFatController,
                label: 'Body Fat (%)',
                icon: Icons.pie_chart_outline,
                hint: 'Contoh: 18,5 atau 18.5',
                suffix: '%',
              ),
            ),
          ],
        ),
        
        // BMI with auto-calculate toggle
        Row(
          children: [
            Expanded(
              child: _buildNumberInputField(
                controller: _bmiController,
                label: 'BMI',
                icon: Icons.straighten,
                hint: 'Contoh: 23,4 atau 23.4',
                enabled: !_autoCalculateBMI,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                const Text('Auto', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _autoCalculateBMI,
                  onChanged: (value) {
                    setState(() {
                      _autoCalculateBMI = value;
                      if (value) _calculateBMI();
                    });
                  },
                  activeColor: Colors.orange[700],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberInputField(
                controller: _visceralFatController,
                label: 'Visceral Fat',
                icon: Icons.favorite_outline,
                hint: 'Contoh: 8,5 atau 8.5',
                isInteger: false,
              ),
            ),
          ],
        ),
        
        Row(
          children: [
            Expanded(
              child: _buildNumberInputField(
                controller: _restingMetabolismController,
                label: 'Metabolism (kcal)',
                icon: Icons.local_fire_department,
                hint: 'Contoh: 1650',
                suffix: 'kcal',
                isInteger: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberInputField(
                controller: _bodyAgeController,
                label: 'Body Age (tahun)',
                icon: Icons.schedule,
                hint: 'Contoh: 28',
                suffix: 'tahun',
                isInteger: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicSingleColumnForm() {
    return Column(
      children: [
        _buildNumberInputField(
          controller: _weightController,
          label: 'Berat Badan (kg)',
          icon: Icons.scale,
          hint: 'Contoh: 75,5 atau 75.5',
          suffix: 'kg',
        ),
        
        _buildNumberInputField(
          controller: _bodyFatController,
          label: 'Body Fat Percentage (%)',
          icon: Icons.pie_chart_outline,
          hint: 'Contoh: 18,5 atau 18.5',
          suffix: '%',
        ),
        
        // BMI with auto-calculate toggle
        Row(
          children: [
            Expanded(
              child: _buildNumberInputField(
                controller: _bmiController,
                label: 'Body Mass Index (BMI)',
                icon: Icons.straighten,
                hint: 'Contoh: 23,4 atau 23.4',
                enabled: !_autoCalculateBMI,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                const Text('Auto', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _autoCalculateBMI,
                  onChanged: (value) {
                    setState(() {
                      _autoCalculateBMI = value;
                      if (value) _calculateBMI();
                    });
                  },
                  activeColor: Colors.orange[700],
                ),
              ],
            ),
          ],
        ),
        
        _buildNumberInputField(
          controller: _visceralFatController,
          label: 'Visceral Fat Level',
          icon: Icons.favorite_outline,
          hint: 'Contoh: 8,5 atau 8.5',
          isInteger: false,
        ),
        
        _buildNumberInputField(
          controller: _restingMetabolismController,
          label: 'Resting Metabolism (kcal)',
          icon: Icons.local_fire_department,
          hint: 'Contoh: 1650',
          suffix: 'kcal',
          isInteger: true,
        ),
        
        _buildNumberInputField(
          controller: _bodyAgeController,
          label: 'Body Age (tahun)',
          icon: Icons.schedule,
          hint: 'Contoh: 28',
          suffix: 'tahun',
          isInteger: true,
        ),
      ],
    );
  }

  // Segmental data card TANPA AUTO CALC BUTTON
  Widget _buildSegmentalDataCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data Segmental per Area Tubuh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
                // REMOVED: Auto calculate toggle button
              ],
            ),
            
            // REMOVED: Info container tentang auto calculate
            
            const SizedBox(height: 16),
            
            // Subcutaneous Fat Segmental - NEW STRUCTURE
            Text(
              'Subcutaneous Fat per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[600],
              ),
            ),
            const SizedBox(height: 8),
            
            _buildNumberInputField(
              controller: _segSubWholeBodyController,
              label: 'Whole Body (Seluruh Tubuh)',
              icon: Icons.accessibility_new,
              hint: '0,0',
              suffix: '%',
            ),
            
            // Responsive layout for trunk and arms
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildNumberInputField(
                          controller: _segSubTrunkController,
                          label: 'Trunk (Batang Tubuh)',
                          icon: Icons.airline_seat_recline_normal,
                          hint: '0,0',
                          suffix: '%',
                          enabled: true, // FIXED: Always enabled for manual input
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberInputField(
                          controller: _segSubArmsController,
                          label: 'Arms (Kedua Lengan)',
                          icon: Icons.sports_martial_arts,
                          hint: '0,0',
                          suffix: '%',
                          enabled: true, // FIXED: Always enabled for manual input
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildNumberInputField(
                        controller: _segSubTrunkController,
                        label: 'Trunk (Batang Tubuh)',
                        icon: Icons.airline_seat_recline_normal,
                        hint: '0,0',
                        suffix: '%',
                        enabled: true, // FIXED: Always enabled for manual input
                      ),
                      _buildNumberInputField(
                        controller: _segSubArmsController,
                        label: 'Arms (Kedua Lengan)',
                        icon: Icons.sports_martial_arts,
                        hint: '0,0',
                        suffix: '%',
                        enabled: true, // FIXED: Always enabled for manual input
                      ),
                    ],
                  );
                }
              },
            ),
            
            _buildNumberInputField(
              controller: _segSubLegsController,
              label: 'Legs (Kedua Kaki)',
              icon: Icons.directions_walk,
              hint: '0,0',
              suffix: '%',
              enabled: true, // FIXED: Always enabled for manual input
            ),
            
            const SizedBox(height: 24),
            
            // Skeletal Muscle Segmental - NEW STRUCTURE
            Text(
              'Skeletal Muscle per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            
            _buildNumberInputField(
              controller: _segMusWholeBodyController,
              label: 'Whole Body (Seluruh Tubuh)',
              icon: Icons.accessibility_new,
              hint: '0,0',
              suffix: '%',
            ),
            
            // Responsive layout for trunk and arms
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildNumberInputField(
                          controller: _segMusTrunkController,
                          label: 'Trunk (Batang Tubuh)',
                          icon: Icons.airline_seat_recline_normal,
                          hint: '0,0',
                          suffix: '%',
                          enabled: true, // FIXED: Always enabled for manual input
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberInputField(
                          controller: _segMusArmsController,
                          label: 'Arms (Kedua Lengan)',
                          icon: Icons.sports_martial_arts,
                          hint: '0,0',
                          suffix: '%',
                          enabled: true, // FIXED: Always enabled for manual input
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildNumberInputField(
                        controller: _segMusTrunkController,
                        label: 'Trunk (Batang Tubuh)',
                        icon: Icons.airline_seat_recline_normal,
                        hint: '0,0',
                        suffix: '%',
                        enabled: true, // FIXED: Always enabled for manual input
                      ),
                      _buildNumberInputField(
                        controller: _segMusArmsController,
                        label: 'Arms (Kedua Lengan)',
                        icon: Icons.sports_martial_arts,
                        hint: '0,0',
                        suffix: '%',
                        enabled: true, // FIXED: Always enabled for manual input
                      ),
                    ],
                  );
                }
              },
            ),
            
            _buildNumberInputField(
              controller: _segMusLegsController,
              label: 'Legs (Kedua Kaki)',
              icon: Icons.directions_walk,
              hint: '0,0',
              suffix: '%',
              enabled: true, // FIXED: Always enabled for manual input
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String hint = '',
    String suffix = '',
    bool enabled = true,
    bool isInteger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
        inputFormatters: [
          if (isInteger)
            FilteringTextInputFormatter.digitsOnly
          else
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix.isNotEmpty ? suffix : null,
          prefixIcon: Icon(icon, color: enabled ? Colors.orange[700] : Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Field ini wajib diisi';
          }
          
          final numValue = OmronData.parseDecimalInput(value);
          if (numValue <= 0) {
            return 'Nilai harus lebih dari 0';
          }
          
          return null;
        },
      ),
    );
  }

  Widget _buildCalculateButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _calculateResult,
        icon: _isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.calculate, size: 24),
        label: Text(
          _isLoading ? 'Menghitung Analisis...' : 'Hitung Analisis Lengkap (11 Fitur)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: _isLoading ? 2 : 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Calculate result dengan struktur segmental baru
  Future<void> _calculateResult() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse all input values
      final age = int.tryParse(_ageController.text) ?? 0;
      final height = OmronData.parseDecimalInput(_heightController.text);
      final weight = OmronData.parseDecimalInput(_weightController.text);
      final bodyFat = OmronData.parseDecimalInput(_bodyFatController.text);
      final bmi = OmronData.parseDecimalInput(_bmiController.text);
      final visceralFat = OmronData.parseDecimalInput(_visceralFatController.text);
      final restingMetabolism = int.tryParse(_restingMetabolismController.text) ?? 0;
      final bodyAge = int.tryParse(_bodyAgeController.text) ?? 0;
      
      // Use subcutaneous fat from segmental whole body
      final subcutaneousFat = OmronData.parseDecimalInput(_segSubWholeBodyController.text);
      
      // Use skeletal muscle from segmental whole body
      final skeletalMuscle = OmronData.parseDecimalInput(_segMusWholeBodyController.text);

      // Get segmental data with NEW STRUCTURE
      Map<String, double> segmentalSubcutaneous = {
        'wholeBody': OmronData.parseDecimalInput(_segSubWholeBodyController.text),
        'trunk': OmronData.parseDecimalInput(_segSubTrunkController.text),
        'arms': OmronData.parseDecimalInput(_segSubArmsController.text),
        'legs': OmronData.parseDecimalInput(_segSubLegsController.text),
      };

      Map<String, double> segmentalSkeletal = {
        'wholeBody': OmronData.parseDecimalInput(_segMusWholeBodyController.text),
        'trunk': OmronData.parseDecimalInput(_segMusTrunkController.text),
        'arms': OmronData.parseDecimalInput(_segMusArmsController.text),
        'legs': OmronData.parseDecimalInput(_segMusLegsController.text),
      };

      // Calculate same age comparison
      final sameAgeComparison = OmronData.calculateSameAgeComparison(
        bodyFat, 
        age, 
        _selectedGender,
      );

      // Create OmronData object
      final omronData = OmronData(
        timestamp: DateTime.now(),
        patientName: _patientNameController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty 
          ? null 
          : _whatsappController.text.trim(),
        age: age,
        gender: _selectedGender,
        height: height,
        weight: weight,
        bodyFatPercentage: bodyFat,
        bmi: bmi,
        skeletalMusclePercentage: skeletalMuscle,
        visceralFatLevel: visceralFat,
        restingMetabolism: restingMetabolism,
        bodyAge: bodyAge,
        subcutaneousFatPercentage: subcutaneousFat,
        segmentalSubcutaneousFat: segmentalSubcutaneous,
        segmentalSkeletalMuscle: segmentalSkeletal,
        sameAgeComparison: sameAgeComparison,
      );

      setState(() {
        _calculatedResult = omronData;
        _isLoading = false;
      });

      // FITUR 3: AUTO SAVE setelah 3 detik
      _startAutoSaveTimer();

      // Scroll to result (untuk mobile)
      if (MediaQuery.of(context).size.width <= 800) {
        await Future.delayed(const Duration(milliseconds: 500));
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analisis berhasil! Data akan tersimpan otomatis dalam 3 detik',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Terjadi kesalahan: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _scrollToFirstError() {
    // Scroll to the first error field
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // FITUR 3: AUTO SAVE TIMER
  Timer? _autoSaveTimer;
  
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (_calculatedResult != null && mounted) {
        _saveDataAutomatically();
      }
    });
  }

  Future<void> _saveDataAutomatically() async {
    if (_calculatedResult == null) return;
    
    try {
      await _databaseService.insertOmronData(_calculatedResult!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.save_alt, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Data tersimpan otomatis untuk ${_calculatedResult!.patientName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      
      // Reset form setelah auto save
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _resetForm();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Auto save gagal: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveDataManually() async {
    if (_calculatedResult == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cancel auto save timer jika ada
      _autoSaveTimer?.cancel();
      
      await _databaseService.insertOmronData(_calculatedResult!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.save, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Data berhasil disimpan untuk ${_calculatedResult!.patientName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      
      // Reset form
      _resetForm();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Gagal menyimpan: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    // Clear all controllers
    _patientNameController.clear();
    _whatsappController.clear();
    _ageController.clear();
    _heightController.clear();
    _weightController.clear();
    _bodyFatController.clear();
    _bmiController.clear();
    _visceralFatController.clear();
    _restingMetabolismController.clear();
    _bodyAgeController.clear();
    
    // Clear segmental controllers - NEW STRUCTURE
    _segSubWholeBodyController.clear();
    _segSubTrunkController.clear();
    _segSubArmsController.clear();
    _segSubLegsController.clear();
    _segMusWholeBodyController.clear();
    _segMusTrunkController.clear();
    _segMusArmsController.clear();
    _segMusLegsController.clear();
    
    // Reset state
    setState(() {
      _selectedGender = 'Male';
      _calculatedResult = null;
      _autoCalculateBMI = true;
      _autoCalculateSegmental = false; // FIXED: Keep it false so fields remain enabled
    });
    
    // Scroll to top
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showResultDialog() {
    if (_calculatedResult == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.fullscreen, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hasil Analisis Lengkap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const Divider(),
                // Content
                Expanded(
                  child: OmronResultCard(data: _calculatedResult!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Cancel timer
    _autoSaveTimer?.cancel();
    
    // Dispose controllers
    _scrollController.dispose();
    _patientNameController.dispose();
    _whatsappController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _bmiController.dispose();
    _visceralFatController.dispose();
    _restingMetabolismController.dispose();
    _bodyAgeController.dispose();
    
    // Dispose segmental controllers - NEW STRUCTURE
    _segSubWholeBodyController.dispose();
    _segSubTrunkController.dispose();
    _segSubArmsController.dispose();
    _segSubLegsController.dispose();
    _segMusWholeBodyController.dispose();
    _segMusTrunkController.dispose();
    _segMusArmsController.dispose();
    _segMusLegsController.dispose();
    
    super.dispose();
  }
}