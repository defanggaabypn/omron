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
  
  // Basic Omron Data Controllers
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _bmiController = TextEditingController();
  final _skeletalMuscleController = TextEditingController();
  final _visceralFatController = TextEditingController();
  final _restingMetabolismController = TextEditingController();
  final _bodyAgeController = TextEditingController();
  
  // New Additional Controllers
  final _subcutaneousFatController = TextEditingController();
  
  // Segmental Controllers - Subcutaneous Fat
  final _segSubTrunkController = TextEditingController();
  final _segSubRightArmController = TextEditingController();
  final _segSubLeftArmController = TextEditingController();
  final _segSubRightLegController = TextEditingController();
  final _segSubLeftLegController = TextEditingController();
  
  // Segmental Controllers - Skeletal Muscle
  final _segMusTrunkController = TextEditingController();
  final _segMusRightArmController = TextEditingController();
  final _segMusLeftArmController = TextEditingController();
  final _segMusRightLegController = TextEditingController();
  final _segMusLeftLegController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _autoCalculateBMI = true;
  bool _autoCalculateSegmental = true;
  final bool _autoCalculateSameAge = true;
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
    _subcutaneousFatController.addListener(_calculateSegmentalData);
    _skeletalMuscleController.addListener(_calculateSegmentalData);

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
    
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    
    if (weight != null && height != null && height > 0) {
      final heightInMeters = height / 100; // Convert cm to meters
      final bmi = weight / (heightInMeters * heightInMeters);
      _bmiController.text = bmi.toStringAsFixed(1);
    }
  }

  void _calculateSegmentalData() {
    if (!_autoCalculateSegmental) return;
    
    final subcutaneousFat = double.tryParse(_subcutaneousFatController.text);
    final skeletalMuscle = double.tryParse(_skeletalMuscleController.text);
    
    if (subcutaneousFat != null) {
      final segmental = OmronData.calculateSegmentalSubcutaneousFat(subcutaneousFat);
      _segSubTrunkController.text = segmental['trunk']!.toStringAsFixed(1);
      _segSubRightArmController.text = segmental['rightArm']!.toStringAsFixed(1);
      _segSubLeftArmController.text = segmental['leftArm']!.toStringAsFixed(1);
      _segSubRightLegController.text = segmental['rightLeg']!.toStringAsFixed(1);
      _segSubLeftLegController.text = segmental['leftLeg']!.toStringAsFixed(1);
    }
    
    if (skeletalMuscle != null) {
      final segmental = OmronData.calculateSegmentalSkeletalMuscle(skeletalMuscle);
      _segMusTrunkController.text = segmental['trunk']!.toStringAsFixed(1);
      _segMusRightArmController.text = segmental['rightArm']!.toStringAsFixed(1);
      _segMusLeftArmController.text = segmental['leftArm']!.toStringAsFixed(1);
      _segMusRightLegController.text = segmental['rightLeg']!.toStringAsFixed(1);
      _segMusLeftLegController.text = segmental['leftLeg']!.toStringAsFixed(1);
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
                    _buildAdditionalDataCard(),
                    const SizedBox(height: 16),
                    _buildSegmentalDataCard(), // FITUR 4: Pindah setelah subcutaneous
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
            _buildAdditionalDataCard(),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(), // FITUR 4: Pindah setelah subcutaneous
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
            _buildAdditionalDataCard(),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(), // FITUR 4: Pindah setelah subcutaneous
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
                hint: 'Contoh: 75.5',
                suffix: 'kg',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberInputField(
                controller: _bodyFatController,
                label: 'Body Fat (%)',
                icon: Icons.pie_chart_outline,
                hint: 'Contoh: 18.5',
                suffix: '%',
              ),
            ),
          ],
        ),
        
        // BMI with auto-calculate toggle (TANPA SKELETAL MUSCLE)
        Row(
          children: [
            Expanded(
              child: _buildNumberInputField(
                controller: _bmiController,
                label: 'BMI',
                icon: Icons.straighten,
                hint: 'Contoh: 23.4',
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
            const Expanded(child: SizedBox()), // Empty space
          ],
        ),
        
        Row(
          children: [
            Expanded(
              child: _buildNumberInputField(
                controller: _visceralFatController,
                label: 'Visceral Fat',
                icon: Icons.favorite_outline,
                hint: 'Contoh: 8',
                isInteger: true,
              ),
            ),
            const SizedBox(width: 16),
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
          ],
        ),
        
        Row(
          children: [
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
            const Expanded(child: SizedBox()), // Empty space for balance
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
          hint: 'Contoh: 75.5',
          suffix: 'kg',
        ),
        
        _buildNumberInputField(
          controller: _bodyFatController,
          label: 'Body Fat Percentage (%)',
          icon: Icons.pie_chart_outline,
          hint: 'Contoh: 18.5',
          suffix: '%',
        ),
        
        // BMI with auto-calculate toggle (TANPA SKELETAL MUSCLE)
        Row(
          children: [
            Expanded(
              child: _buildNumberInputField(
                controller: _bmiController,
                label: 'Body Mass Index (BMI)',
                icon: Icons.straighten,
                hint: 'Contoh: 23.4',
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
          hint: 'Contoh: 8',
          isInteger: true,
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

  Widget _buildAdditionalDataCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data Tambahan Omron HBF-375',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // SUBCUTANEOUS FAT
            _buildNumberInputField(
              controller: _subcutaneousFatController,
              label: 'Subcutaneous Fat (%)',
              icon: Icons.layers,
              hint: 'Contoh: 15.2',
              suffix: '%',
            ),
            
            // SKELETAL MUSCLE - DIPINDAH KE SINI
            _buildNumberInputField(
              controller: _skeletalMuscleController,
              label: 'Skeletal Muscle (%)',
              icon: Icons.fitness_center,
              hint: 'Contoh: 42.1',
              suffix: '%',
            ),
            
            const SizedBox(height: 8),
            Text(
              'Same Age Comparison akan dihitung otomatis berdasarkan Body Fat dan Usia',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FITUR 4: FORM SKELETAL SETELAH SUBCUTANEOUS
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
                    'Data Segmental (Per Bagian Tubuh)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Text('Auto Calc', style: TextStyle(fontSize: 10)),
                    Switch(
                      value: _autoCalculateSegmental,
                      onChanged: (value) {
                        setState(() {
                          _autoCalculateSegmental = value;
                          if (value) _calculateSegmentalData();
                        });
                      },
                      activeColor: Colors.purple[700],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Subcutaneous Fat Segmental
            Text(
              'Subcutaneous Fat per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            const SizedBox(height: 8),
            
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubTrunkController,
                              label: 'Trunk',
                              icon: Icons.airline_seat_recline_normal,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubRightArmController,
                              label: 'Right Arm',
                              icon: Icons.back_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.front_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubRightLegController,
                              label: 'Right Leg',
                              icon: Icons.directions_walk,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubLeftLegController,
                              label: 'Left Leg',
                              icon: Icons.directions_run,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const Expanded(child: SizedBox()), // Empty space for balance
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildNumberInputField(
                        controller: _segSubTrunkController,
                        label: 'Trunk',
                        icon: Icons.airline_seat_recline_normal,
                        hint: '0.0',
                        suffix: '%',
                        enabled: !_autoCalculateSegmental,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubRightArmController,
                              label: 'Right Arm',
                              icon: Icons.back_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.front_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubRightLegController,
                              label: 'Right Leg',
                              icon: Icons.directions_walk,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubLeftLegController,
                              label: 'Left Leg',
                              icon: Icons.directions_run,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // Skeletal Muscle Segmental
            Text(
              'Skeletal Muscle per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            const SizedBox(height: 8),
            
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusTrunkController,
                              label: 'Trunk',
                              icon: Icons.airline_seat_recline_normal,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusRightArmController,
                              label: 'Right Arm',
                              icon: Icons.back_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.front_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusRightLegController,
                              label: 'Right Leg',
                              icon: Icons.directions_walk,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusLeftLegController,
                              label: 'Left Leg',
                              icon: Icons.directions_run,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const Expanded(child: SizedBox()), // Empty space for balance
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildNumberInputField(
                        controller: _segMusTrunkController,
                        label: 'Trunk',
                        icon: Icons.airline_seat_recline_normal,
                        hint: '0.0',
                        suffix: '%',
                        enabled: !_autoCalculateSegmental,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusRightArmController,
                              label: 'Right Arm',
                              icon: Icons.back_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.front_hand,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusRightLegController,
                              label: 'Right Leg',
                              icon: Icons.directions_walk,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusLeftLegController,
                              label: 'Left Leg',
                              icon: Icons.directions_run,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
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
    String? hint,
    String? suffix,
    bool isInteger = false,
    bool enabled = true,
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
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: enabled ? Colors.orange[700] : Colors.grey),
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Field ini wajib diisi';
          }
          if (isInteger) {
            if (int.tryParse(value) == null) {
              return 'Masukkan angka yang valid';
            }
          } else {
            if (double.tryParse(value) == null) {
              return 'Masukkan angka yang valid';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
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
          _isLoading ? 'Menghitung...' : 'Hitung & Analisis (11 Fitur)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _calculateResult() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    setState(() {
      _isLoading = true;
      _calculatedResult = null; // Clear previous result
    });

    try {
      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get segmental data
      Map<String, double> segmentalSubcutaneous = {
        'trunk': double.tryParse(_segSubTrunkController.text) ?? 0.0,
        'rightArm': double.tryParse(_segSubRightArmController.text) ?? 0.0,
        'leftArm': double.tryParse(_segSubLeftArmController.text) ?? 0.0,
        'rightLeg': double.tryParse(_segSubRightLegController.text) ?? 0.0,
        'leftLeg': double.tryParse(_segSubLeftLegController.text) ?? 0.0,
      };

      Map<String, double> segmentalSkeletal = {
        'trunk': double.tryParse(_segMusTrunkController.text) ?? 0.0,
        'rightArm': double.tryParse(_segMusRightArmController.text) ?? 0.0,
        'leftArm': double.tryParse(_segMusLeftArmController.text) ?? 0.0,
        'rightLeg': double.tryParse(_segMusRightLegController.text) ?? 0.0,
        'leftLeg': double.tryParse(_segMusLeftLegController.text) ?? 0.0,
      };

      // Calculate same age comparison
      final bodyFat = double.parse(_bodyFatController.text);
      final age = int.parse(_ageController.text);
      final sameAgeComparison = OmronData.calculateSameAgeComparison(bodyFat, age, _selectedGender);

      final omronData = OmronData(
        timestamp: DateTime.now(),
        patientName: _patientNameController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty 
          ? null 
          : _whatsappController.text.trim(),
        age: age,
        gender: _selectedGender,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        bodyFatPercentage: bodyFat,
        bmi: double.parse(_bmiController.text),
        skeletalMusclePercentage: double.parse(_skeletalMuscleController.text),
        visceralFatLevel: int.parse(_visceralFatController.text),
        restingMetabolism: int.parse(_restingMetabolismController.text),
        bodyAge: int.parse(_bodyAgeController.text),
        subcutaneousFatPercentage: double.parse(_subcutaneousFatController.text),
        segmentalSubcutaneousFat: segmentalSubcutaneous,
        segmentalSkeletalMuscle: segmentalSkeletal,
        sameAgeComparison: sameAgeComparison,
      );

      // Set result dengan setState yang aman
      if (mounted) {
        setState(() {
          _calculatedResult = omronData;
          _isLoading = false;
        });

        // FITUR 2: RESET FORM LANGSUNG SETELAH PERHITUNGAN SELESAI
        _clearFormAfterCalculation();

        // Scroll dengan delay untuk memastikan widget sudah ter-render
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && MediaQuery.of(context).size.width <= 1200) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });

        // SUCCESS MESSAGE
        final hasWhatsApp = omronData.whatsappNumber != null && omronData.whatsappNumber!.isNotEmpty;
        String successMessage = '✅ Analisis berhasil! Form telah direset untuk input baru. ';
        
        if (hasWhatsApp) {
          successMessage += 'Nomor WhatsApp tersimpan: ${omronData.whatsappNumber}. ';
        }
        
        successMessage += 'Data akan otomatis tersimpan dalam 3 detik.';
        
        _showSuccessSnackBar(successMessage);

        // FITUR 3: AUTO SAVE SETELAH 3 DETIK
        _startAutoSaveCountdown();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _calculatedResult = null;
        });
        _showErrorSnackBar('Terjadi kesalahan saat menghitung: $e');
      }
    }
  }

  // FITUR 3: AUTO SAVE FUNCTIONALITY
  void _startAutoSaveCountdown() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _calculatedResult != null) {
        _saveDataAutomatically();
      }
    });
  }

  Future<void> _saveDataAutomatically() async {
    if (_calculatedResult == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final id = await _databaseService.insertOmronData(_calculatedResult!);
      
      setState(() {
        _isLoading = false;
      });

      // SUCCESS MESSAGE
      final hasWhatsApp = _calculatedResult!.whatsappNumber != null && _calculatedResult!.whatsappNumber!.isNotEmpty;
      String successMessage = '✅ Data otomatis tersimpan dengan ID: $id';
      
      if (hasWhatsApp) {
        successMessage += ' (dengan nomor WhatsApp)';
      }

      _showSuccessSnackBar(successMessage);
      
      // Show auto save success dialog
      _showAutoSaveSuccessDialog();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal menyimpan otomatis: $e');
    }
  }

  Future<void> _saveDataManually() async {
    if (_calculatedResult == null) {
      _showErrorSnackBar('Tidak ada data untuk disimpan. Silakan hitung terlebih dahulu.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final id = await _databaseService.insertOmronData(_calculatedResult!);
      
      setState(() {
        _isLoading = false;
      });

      // SUCCESS MESSAGE
      final hasWhatsApp = _calculatedResult!.whatsappNumber != null && _calculatedResult!.whatsappNumber!.isNotEmpty;
      String successMessage = '✅ Data manual tersimpan dengan ID: $id';
      
      if (hasWhatsApp) {
        successMessage += ' (dengan nomor WhatsApp)';
      }

      _showSuccessSnackBar(successMessage);
      
      // Show manual save success dialog
      _showManualSaveSuccessDialog();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal menyimpan data: $e');
    }
  }

  // FITUR 2: RESET FORM LANGSUNG SETELAH PERHITUNGAN SELESAI
  void _clearFormAfterCalculation() {
    // Clear all form controllers tapi JANGAN hapus _calculatedResult
    _patientNameController.clear();
    _whatsappController.clear();
    _ageController.clear();
    _heightController.clear();
    _weightController.clear();
    _bodyFatController.clear();
    _bmiController.clear();
    _skeletalMuscleController.clear();
    _visceralFatController.clear();
    _restingMetabolismController.clear();
    _bodyAgeController.clear();
    _subcutaneousFatController.clear();
    
    // Clear segmental controllers
    _segSubTrunkController.clear();
    _segSubRightArmController.clear();
    _segSubLeftArmController.clear();
    _segSubRightLegController.clear();
    _segSubLeftLegController.clear();
    
    _segMusTrunkController.clear();
    _segMusRightArmController.clear();
    _segMusLeftArmController.clear();
    _segMusRightLegController.clear();
    _segMusLeftLegController.clear();

    // Reset gender selection ke default
    setState(() {
      _selectedGender = 'Male';
      // JANGAN reset _calculatedResult dan _isLoading di sini
    });

    // Show reset notification
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _showInfoSnackBar('📝 Form siap untuk input data pasien berikutnya');
      }
    });
  }

  void _showAutoSaveSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.schedule_send, color: Colors.green, size: 48),
          title: const Text('Data Otomatis Tersimpan! ⚡'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Data Omron HBF-375 berhasil disimpan secara otomatis! (11/11 Fitur)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasien: ${_calculatedResult!.patientName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(_calculatedResult!.timestamp)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⚡ Data tersimpan otomatis dalam 3 detik',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                    if (_calculatedResult!.whatsappNumber != null && _calculatedResult!.whatsappNumber!.isNotEmpty) ...[
                      Text(
                        '📱 Nomor WhatsApp: ${_calculatedResult!.whatsappNumber}',
                        style: TextStyle(color: Colors.green[700], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearResultAndPrepareNewInput(); // Method baru untuk clear result saja
              },
              child: const Text('Input Baru'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/history');
              },
              child: const Text('Lihat Riwayat'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showManualSaveSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Data Tersimpan! 👍'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Data Omron HBF-375 berhasil disimpan secara manual! (11/11 Fitur)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasien: ${_calculatedResult!.patientName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(_calculatedResult!.timestamp)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✅ Data tersimpan manual oleh pengguna',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                    if (_calculatedResult!.whatsappNumber != null && _calculatedResult!.whatsappNumber!.isNotEmpty) ...[
                      Text(
                        '📱 Nomor WhatsApp: ${_calculatedResult!.whatsappNumber}',
                        style: TextStyle(color: Colors.green[700], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearResultAndPrepareNewInput(); // Method baru untuk clear result saja
              },
              child: const Text('Input Baru'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/history');
              },
              child: const Text('Lihat Riwayat'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Method baru untuk clear result dan prepare input baru setelah save
  void _clearResultAndPrepareNewInput() {
    setState(() {
      _calculatedResult = null;
      _isLoading = false;
    });

    // Scroll back to top
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    // Show notification
    _showInfoSnackBar('🆕 Siap untuk analisis pasien baru');
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResultDialog() {
    if (_calculatedResult == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive dialog sizing
              double dialogWidth = constraints.maxWidth > 1200 
                  ? constraints.maxWidth * 0.7
                  : constraints.maxWidth > 800 
                      ? constraints.maxWidth * 0.85
                      : constraints.maxWidth * 0.95;
              
              double dialogHeight = constraints.maxHeight * 0.9;

              return Container(
                width: dialogWidth,
                height: dialogHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hasil Analisis - ${_calculatedResult!.patientName}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_calculatedResult!.whatsappNumber != null && _calculatedResult!.whatsappNumber!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.chat, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'WA: ${_calculatedResult!.whatsappNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: _buildSafeResultCard(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _scrollToFirstError() {
    // Find first error and scroll to it
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _patientNameController.dispose();
    _whatsappController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _bmiController.dispose();
    _skeletalMuscleController.dispose();
    _visceralFatController.dispose();
    _restingMetabolismController.dispose();
    _bodyAgeController.dispose();
    _subcutaneousFatController.dispose();
    
    _segSubTrunkController.dispose();
    _segSubRightArmController.dispose();
    _segSubLeftArmController.dispose();
    _segSubRightLegController.dispose();
    _segSubLeftLegController.dispose();
    
    _segMusTrunkController.dispose();
    _segMusRightArmController.dispose();
    _segMusLeftArmController.dispose();
    _segMusRightLegController.dispose();
    _segMusLeftLegController.dispose();
    
    _scrollController.dispose();
    super.dispose();
  }
}