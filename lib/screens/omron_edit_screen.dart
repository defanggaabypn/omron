import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';
import '../services/database_service.dart';
import '../widgets/omron_result_card.dart';
import '../widgets/patient_info_card.dart';

class OmronEditScreen extends StatefulWidget {
  final OmronData data;
  
  const OmronEditScreen({Key? key, required this.data}) : super(key: key);

  @override
  _OmronEditScreenState createState() => _OmronEditScreenState();
}

class _OmronEditScreenState extends State<OmronEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final DatabaseService _databaseService = DatabaseService();
  
  // Patient Info Controllers
  late TextEditingController _patientNameController;
  late TextEditingController _whatsappController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  
  // Basic Omron Data Controllers - MATCHED WITH INPUT SCREEN
  late TextEditingController _weightController;
  late TextEditingController _bodyFatController;
  late TextEditingController _bmiController;
  late TextEditingController _visceralFatController;
  late TextEditingController _restingMetabolismController;
  late TextEditingController _bodyAgeController;
  
  // Segmental Controllers - NEW STRUCTURE (wholeBody, trunk, arms, legs)
  late TextEditingController _segSubWholeBodyController;
  late TextEditingController _segSubTrunkController;
  late TextEditingController _segSubArmsController;
  late TextEditingController _segSubLegsController;
  
  late TextEditingController _segMusWholeBodyController;
  late TextEditingController _segMusTrunkController;
  late TextEditingController _segMusArmsController;
  late TextEditingController _segMusLegsController;

  late String _selectedGender;
  bool _isLoading = false;
  bool _autoCalculateBMI = false;
  bool _autoCalculateSegmental = false; // Set to false so all fields can be manually input
  OmronData? _updatedResult;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
  }

  void _initializeControllers() {
    // Patient Info
    _patientNameController = TextEditingController(text: widget.data.patientName);
    _whatsappController = TextEditingController(text: widget.data.whatsappNumber ?? '');
    _ageController = TextEditingController(text: widget.data.age.toString());
    _heightController = TextEditingController(text: widget.data.height.toString());
    
    // Basic Omron Data - MATCHED WITH INPUT SCREEN
    _weightController = TextEditingController(text: widget.data.weight.toString());
    _bodyFatController = TextEditingController(text: widget.data.bodyFatPercentage.toString());
    _bmiController = TextEditingController(text: widget.data.bmi.toString());
    _visceralFatController = TextEditingController(text: widget.data.visceralFatLevel.toString());
    _restingMetabolismController = TextEditingController(text: widget.data.restingMetabolism.toString());
    _bodyAgeController = TextEditingController(text: widget.data.bodyAge.toString());
    
    // Segmental Controllers - NEW STRUCTURE
    _segSubWholeBodyController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['wholeBody']?.toString() ?? '0.0');
    _segSubTrunkController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['trunk']?.toString() ?? '0.0');
    _segSubArmsController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['arms']?.toString() ?? '0.0');
    _segSubLegsController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['legs']?.toString() ?? '0.0');
    
    _segMusWholeBodyController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['wholeBody']?.toString() ?? '0.0');
    _segMusTrunkController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['trunk']?.toString() ?? '0.0');
    _segMusArmsController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['arms']?.toString() ?? '0.0');
    _segMusLegsController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['legs']?.toString() ?? '0.0');
    
    // Set gender
    _selectedGender = widget.data.gender;
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

  void _formatPatientName() {
    final text = _patientNameController.text;
    final selection = _patientNameController.selection;
    
    final formattedText = _capitalizeWords(text);
    
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
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);
      _bmiController.text = bmi.toStringAsFixed(1);
    }
  }

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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Data Omron',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Pasien: ${widget.data.patientName}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_updatedResult != null)
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _showPreviewDialog,
            tooltip: 'Preview Hasil',
          ),
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.pushNamed(context, '/history'),
          tooltip: 'Riwayat Data',
        ),
      ],
    );
  }

  Widget _buildResponsiveBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return _buildDesktopLayout();
        } else if (constraints.maxWidth > 800) {
          return _buildTabletLayout();
        } else {
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
                    _buildPatientInfoCard(),
                    const SizedBox(height: 16),
                    _buildBasicOmronDataCard(),
                    const SizedBox(height: 16),
                    _buildSegmentalDataCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right side: Preview
        if (_updatedResult != null)
          Expanded(
            flex: 3,
            child: Container(
              height: MediaQuery.of(context).size.height - kToolbarHeight,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewHeader(),
                  const SizedBox(height: 16),
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
                      child: OmronResultCard(data: _updatedResult!),
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
                Expanded(
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildPatientInfoCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBasicOmronDataCard(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            if (_updatedResult != null) ...[
              const SizedBox(height: 20),
              _buildPreviewSection(),
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
            _buildPatientInfoCard(),
            const SizedBox(height: 16),
            _buildBasicOmronDataCard(),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            if (_updatedResult != null) ...[
              const SizedBox(height: 20),
              _buildPreviewSection(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit,
                size: 32,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Data Omron HBF-375',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modifikasi data hasil pengukuran body composition',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Data asli: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.data.timestamp)}',
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

  Widget _buildPatientInfoCard() {
    return PatientInfoCard(
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
      isEditing: true,
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
                Icon(Icons.assessment, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '6 Indikator Dasar Omron',
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
            
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildBasicTwoColumnForm();
                } else {
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
                  activeColor: Colors.blue[700],
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
                  activeColor: Colors.blue[700],
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

  // Segmental data card TANPA AUTO CALC BUTTON - MATCHED WITH INPUT SCREEN
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
          prefixIcon: Icon(icon, color: enabled ? Colors.blue[700] : Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _previewChanges,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.preview, size: 20),
            label: Text(
              _isLoading ? 'Memproses...' : 'Preview Perubahan',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: _isLoading ? 2 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _updatedResult == null) ? null : _saveChanges,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save, size: 20),
            label: Text(
              _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _updatedResult != null ? Colors.green[700] : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: _isLoading ? 2 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[100]!, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
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
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.preview, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview Hasil Edit 📝',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      'Hasil perhitungan ulang dengan data yang dimodifikasi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
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
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _updatedResult?.patientName ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        '${_updatedResult?.age} tahun • ${_updatedResult?.gender} • Dimodifikasi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_updatedResult?.whatsappNumber != null && _updatedResult!.whatsappNumber!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.chat, color: Colors.blue[600], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'WA: ${_updatedResult!.whatsappNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[600],
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
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_updatedResult == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPreviewHeader(),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: OmronResultCard(data: _updatedResult!),
        ),
      ],
    );
  }

  Future<void> _previewChanges() async {
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

      // Create updated OmronData object
      final updatedData = OmronData(
        id: widget.data.id, // Keep original ID
        timestamp: widget.data.timestamp, // Keep original timestamp
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
        // Keep WhatsApp status from original
        isWhatsAppSent: widget.data.isWhatsAppSent,
        whatsappSentAt: widget.data.whatsappSentAt,
      );

      setState(() {
        _updatedResult = updatedData;
        _isLoading = false;
      });

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
                    'Preview berhasil! Silakan review hasil dan simpan jika sudah sesuai',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue[600],
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

  Future<void> _saveChanges() async {
    if (_updatedResult == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _databaseService.updateOmronData(_updatedResult!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.save, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Perubahan berhasil disimpan untuk ${_updatedResult!.patientName}',
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
      
      // Return to previous screen with updated data
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(_updatedResult);
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

  void _scrollToFirstError() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showPreviewDialog() {
    if (_updatedResult == null) return;
    
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
                    Icon(Icons.fullscreen, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Preview Hasil Edit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
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
                  child: OmronResultCard(data: _updatedResult!),
                ),
                // Action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _saveChanges();
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Perubahan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
    
    // Dispose segmental controllers
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