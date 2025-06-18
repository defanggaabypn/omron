import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';
import '../services/database_service.dart';
import '../widgets/omron_result_card.dart';
import '../widgets/patient_info_card.dart';

class OmronInputScreen extends StatefulWidget {
  @override
  _OmronInputScreenState createState() => _OmronInputScreenState();
}

class _OmronInputScreenState extends State<OmronInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final DatabaseService _databaseService = DatabaseService();
  
  // Patient Info Controllers
  final _patientNameController = TextEditingController();
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
  bool _autoCalculateSameAge = true;
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LSHC Omron HBF-375',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Body Composition Monitor - 11 Fitur Lengkap',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.orange[700],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.history),
          onPressed: () => Navigator.pushNamed(context, '/history'),
          tooltip: 'Riwayat Data',
        ),
        IconButton(
          icon: Icon(Icons.analytics),
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
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  SizedBox(height: 16),
                  PatientInfoCard(
                    patientNameController: _patientNameController,
                    ageController: _ageController,
                    heightController: _heightController,
                    selectedGender: _selectedGender,
                    onGenderChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildBasicOmronDataCard(),
                  SizedBox(height: 16),
                  _buildAdditionalDataCard(),
                  SizedBox(height: 16),
                  _buildSegmentalDataCard(),
                  SizedBox(height: 16),
                  _buildCalculateButton(),
                  SizedBox(height: 80), // Space for FAB
                ],
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
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Analisis Berhasil! (11/11 Fitur Lengkap)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: OmronResultCard(data: _calculatedResult!),
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
      padding: EdgeInsets.all(16),
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
                      SizedBox(height: 16),
                      PatientInfoCard(
                        patientNameController: _patientNameController,
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
                SizedBox(width: 16),
                // Right column: Basic Data
                Expanded(
                  child: _buildBasicOmronDataCard(),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildAdditionalDataCard(),
            SizedBox(height: 16),
            _buildSegmentalDataCard(),
            SizedBox(height: 16),
            _buildCalculateButton(),
            if (_calculatedResult != null) ...[
              SizedBox(height: 16),
              _buildResultSection(),
            ],
            SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            SizedBox(height: 16),
            PatientInfoCard(
              patientNameController: _patientNameController,
              ageController: _ageController,
              heightController: _heightController,
              selectedGender: _selectedGender,
              onGenderChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            SizedBox(height: 16),
            _buildBasicOmronDataCard(),
            SizedBox(height: 16),
            _buildAdditionalDataCard(),
            SizedBox(height: 16),
            _buildSegmentalDataCard(),
            SizedBox(height: 16),
            _buildCalculateButton(),
            if (_calculatedResult != null) ...[
              SizedBox(height: 16),
              _buildResultSection(),
            ],
            SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      children: [
        // Success notification
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analisis Berhasil! (11/11 Fitur Lengkap)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Hasil analisis untuk ${_calculatedResult!.patientName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Quick actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showResultDialog(),
                    icon: Icon(Icons.fullscreen, color: Colors.green[700]),
                    tooltip: 'Lihat Fullscreen',
                  ),
                  IconButton(
                    onPressed: () => _shareResult(),
                    icon: Icon(Icons.share, color: Colors.green[700]),
                    tooltip: 'Bagikan',
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Result card
        OmronResultCard(data: _calculatedResult!),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
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
            SizedBox(width: 16),
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
                  SizedBox(height: 4),
                  Text(
                    'Masukkan data dari display Omron HBF-375 (11 Fitur)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.orange[700]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '7 Indikator Dasar Omron',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
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
            SizedBox(width: 16),
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
        
        // BMI with auto-calculate toggle
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
            SizedBox(width: 8),
            Column(
              children: [
                Text('Auto', style: TextStyle(fontSize: 12)),
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
            SizedBox(width: 16),
            Expanded(
              child: _buildNumberInputField(
                controller: _skeletalMuscleController,
                label: 'Skeletal Muscle (%)',
                icon: Icons.fitness_center,
                hint: 'Contoh: 42.1',
                suffix: '%',
              ),
            ),
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
            SizedBox(width: 16),
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
            Expanded(child: SizedBox()), // Empty space for balance
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
        
        // BMI with auto-calculate toggle
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
            SizedBox(width: 8),
            Column(
              children: [
                Text('Auto', style: TextStyle(fontSize: 12)),
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
          controller: _skeletalMuscleController,
          label: 'Skeletal Muscle (%)',
          icon: Icons.fitness_center,
          hint: 'Contoh: 42.1',
          suffix: '%',
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: Colors.blue[700]),
                SizedBox(width: 8),
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
            SizedBox(height: 16),
            
            _buildNumberInputField(
              controller: _subcutaneousFatController,
              label: 'Subcutaneous Fat (%)',
              icon: Icons.layers,
              hint: 'Contoh: 15.2',
              suffix: '%',
            ),
            
            SizedBox(height: 8),
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

  Widget _buildSegmentalDataCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new, color: Colors.purple[700]),
                SizedBox(width: 8),
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
                    Text('Auto Calc', style: TextStyle(fontSize: 10)),
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
            SizedBox(height: 16),
            
            // Subcutaneous Fat Segmental
            Text(
              'Subcutaneous Fat per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 8),
            
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
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubRightArmController,
                              label: 'Right Arm',
                              icon: Icons.pan_tool,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.back_hand,
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
                          SizedBox(width: 8),
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
                          Expanded(child: SizedBox()), // Balance
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
                              icon: Icons.pan_tool,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segSubLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.back_hand,
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
                          SizedBox(width: 8),
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
            
            SizedBox(height: 16),
            
            // Skeletal Muscle Segmental
            Text(
              'Skeletal Muscle per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 8),
            
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
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusRightArmController,
                              label: 'Right Arm',
                              icon: Icons.pan_tool,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.back_hand,
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
                          SizedBox(width: 8),
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
                          Expanded(child: SizedBox()), // Balance
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
                              icon: Icons.pan_tool,
                              hint: '0.0',
                              suffix: '%',
                              enabled: !_autoCalculateSegmental,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberInputField(
                              controller: _segMusLeftArmController,
                              label: 'Left Arm',
                              icon: Icons.back_hand,
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
                          SizedBox(width: 8),
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
    required String hint,
    String? suffix,
    bool isInteger = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: enabled ? Colors.orange[700] : Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          filled: !enabled,
          fillColor: Colors.grey[50],
        ),
        keyboardType: TextInputType.numberWithOptions(
          decimal: !isInteger,
        ),
        inputFormatters: [
          if (isInteger)
            FilteringTextInputFormatter.digitsOnly
          else
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return '$label harus diisi';
          }
          
          final number = isInteger 
            ? int.tryParse(value!) 
            : double.tryParse(value!);
            
          if (number == null) {
            return 'Format angka tidak valid';
          }
          
          // Validation ranges
          if (label.contains('Berat') && (number < 20 || number > 300)) {
            return 'Berat badan harus antara 20-300 kg';
          }
          if (label.contains('Body Fat') && (number < 0 || number > 60)) {
            return 'Body fat harus antara 0-60%';
          }
          if (label.contains('BMI') && (number < 10 || number > 50)) {
            return 'BMI harus antara 10-50';
          }
          if (label.contains('Skeletal') && (number < 0 || number > 70)) {
            return 'Skeletal muscle harus antara 0-70%';
          }
          if (label.contains('Visceral') && (number < 1 || number > 30)) {
            return 'Visceral fat harus antara 1-30';
          }
          if (label.contains('Metabolism') && (number < 800 || number > 4000)) {
            return 'Resting metabolism harus antara 800-4000 kcal';
          }
          if (label.contains('Body Age') && (number < 18 || number > 80)) {
            return 'Body age harus antara 18-80 tahun';
          }
          if (label.contains('Subcutaneous') && (number < 0 || number > 50)) {
            return 'Subcutaneous fat harus antara 0-50%';
          }
          
          return null;
        },
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _calculateResult,
        icon: _isLoading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(Icons.calculate),
        label: Text(
          _isLoading ? 'Menghitung...' : 'Hitung & Analisis (11 Fitur Lengkap)',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _calculatedResult != null ? _saveData : null,
      icon: Icon(Icons.save),
      label: Text('Simpan Data'),
      backgroundColor: _calculatedResult != null 
        ? Colors.green[700] 
        : Colors.grey[400],
      foregroundColor: Colors.white,
    );
  }

  Future<void> _calculateResult() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate processing time
    await Future.delayed(Duration(milliseconds: 1000));

    try {
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

      setState(() {
        _calculatedResult = omronData;
        _isLoading = false;
      });

      // Scroll to result for mobile/tablet layout
      if (MediaQuery.of(context).size.width <= 1200) {
        Future.delayed(Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }

      _showSuccessSnackBar('Analisis berhasil! Semua 11 fitur Omron HBF-375 telah dihitung. ${MediaQuery.of(context).size.width <= 1200 ? 'Scroll ke bawah untuk melihat hasil.' : ''}');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Terjadi kesalahan saat menghitung: $e');
    }
  }

  Future<void> _saveData() async {
    if (_calculatedResult == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final id = await _databaseService.insertOmronData(_calculatedResult!);
      
      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('Data berhasil disimpan dengan ID: $id');
      
      // Show save confirmation dialog
      _showSaveConfirmationDialog();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal menyimpan data: $e');
    }
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: Text('Data Tersimpan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Data Omron HBF-375 berhasil disimpan! (11/11 Fitur)'),
              SizedBox(height: 16),
              Text(
                'Pasien: ${_calculatedResult!.patientName}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(_calculatedResult!.timestamp)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              child: Text('Input Baru'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/history');
              },
              child: Text('Lihat Riwayat'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive dialog sizing
            double dialogWidth;
            double dialogHeight;
            
            if (constraints.maxWidth > 1200) {
              // Desktop
              dialogWidth = constraints.maxWidth * 0.7;
              dialogHeight = constraints.maxHeight * 0.8;
            } else if (constraints.maxWidth > 800) {
              // Tablet
              dialogWidth = constraints.maxWidth * 0.85;
              dialogHeight = constraints.maxHeight * 0.85;
            } else {
              // Mobile
              dialogWidth = constraints.maxWidth * 0.95;
              dialogHeight = constraints.maxHeight * 0.9;
            }

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: (constraints.maxWidth - dialogWidth) / 2,
                vertical: (constraints.maxHeight - dialogHeight) / 2,
              ),
              child: Container(
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
                          Icon(
                            Icons.analytics,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hasil Analisis Lengkap - ${_calculatedResult!.patientName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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
      },
    );
  }

  void _shareResult() {
    // Implementation for sharing result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur berbagi akan segera tersedia'),
        backgroundColor: Colors.orange[700],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    
    // Clear all basic controllers
    _patientNameController.clear();
    _ageController.clear();
    _heightController.clear();
    _weightController.clear();
    _bodyFatController.clear();
    _bmiController.clear();
    _skeletalMuscleController.clear();
    _visceralFatController.clear();
    _restingMetabolismController.clear();
    _bodyAgeController.clear();
    
    // Clear additional controllers
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
    
    setState(() {
      _selectedGender = 'Male';
      _calculatedResult = null;
      _autoCalculateBMI = true;
      _autoCalculateSegmental = true;
      _autoCalculateSameAge = true;
    });

    // Scroll to top
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToFirstError() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    
    // Basic controllers
    _patientNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _bmiController.dispose();
    _skeletalMuscleController.dispose();
    _visceralFatController.dispose();
    _restingMetabolismController.dispose();
    _bodyAgeController.dispose();
    
    // Additional controllers
    _subcutaneousFatController.dispose();
    
    // Segmental controllers - Subcutaneous Fat
    _segSubTrunkController.dispose();
    _segSubRightArmController.dispose();
    _segSubLeftArmController.dispose();
    _segSubRightLegController.dispose();
    _segSubLeftLegController.dispose();
    
    // Segmental controllers - Skeletal Muscle
    _segMusTrunkController.dispose();
    _segMusRightArmController.dispose();
    _segMusLeftArmController.dispose();
    _segMusRightLegController.dispose();
    _segMusLeftLegController.dispose();
    
    super.dispose();
  }
}