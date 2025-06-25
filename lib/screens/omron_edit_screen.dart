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
  late final TextEditingController _patientNameController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  
  // Basic Omron Data Controllers
  late final TextEditingController _weightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _bmiController;
  late final TextEditingController _skeletalMuscleController;
  late final TextEditingController _visceralFatController;
  late final TextEditingController _restingMetabolismController;
  late final TextEditingController _bodyAgeController;
  
  // Additional Controllers
  late final TextEditingController _subcutaneousFatController;
  
  // Segmental Controllers - Subcutaneous Fat
  late final TextEditingController _segSubTrunkController;
  late final TextEditingController _segSubRightArmController;
  late final TextEditingController _segSubLeftArmController;
  late final TextEditingController _segSubRightLegController;
  late final TextEditingController _segSubLeftLegController;
  
  // Segmental Controllers - Skeletal Muscle
  late final TextEditingController _segMusTrunkController;
  late final TextEditingController _segMusRightArmController;
  late final TextEditingController _segMusLeftArmController;
  late final TextEditingController _segMusRightLegController;
  late final TextEditingController _segMusLeftLegController;

  late String _selectedGender;
  bool _isLoading = false;
  bool _isUpdated = false; // Track if any changes made
  bool _autoCalculateBMI = false; // Disabled by default in edit mode
  bool _autoCalculateSegmental = false; // Disabled by default in edit mode
  OmronData? _previewResult;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
  }

  void _initializeControllers() {
    // Initialize controllers with existing data
    _patientNameController = TextEditingController(text: widget.data.patientName);
    _whatsappController = TextEditingController(text: widget.data.whatsappNumber ?? '');
    _ageController = TextEditingController(text: widget.data.age.toString());
    _heightController = TextEditingController(text: widget.data.height.toString());
    
    _weightController = TextEditingController(text: widget.data.weight.toString());
    _bodyFatController = TextEditingController(text: widget.data.bodyFatPercentage.toString());
    _bmiController = TextEditingController(text: widget.data.bmi.toString());
    _skeletalMuscleController = TextEditingController(text: widget.data.skeletalMusclePercentage.toString());
    _visceralFatController = TextEditingController(text: widget.data.visceralFatLevel.toString());
    _restingMetabolismController = TextEditingController(text: widget.data.restingMetabolism.toString());
    _bodyAgeController = TextEditingController(text: widget.data.bodyAge.toString());
    
    _subcutaneousFatController = TextEditingController(text: widget.data.subcutaneousFatPercentage.toString());
    
    // Segmental Subcutaneous Fat
    _segSubTrunkController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['trunk']!.toString());
    _segSubRightArmController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['rightArm']!.toString());
    _segSubLeftArmController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['leftArm']!.toString());
    _segSubRightLegController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['rightLeg']!.toString());
    _segSubLeftLegController = TextEditingController(text: widget.data.segmentalSubcutaneousFat['leftLeg']!.toString());
    
    // Segmental Skeletal Muscle
    _segMusTrunkController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['trunk']!.toString());
    _segMusRightArmController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['rightArm']!.toString());
    _segMusLeftArmController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['leftArm']!.toString());
    _segMusRightLegController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['rightLeg']!.toString());
    _segMusLeftLegController = TextEditingController(text: widget.data.segmentalSkeletalMuscle['leftLeg']!.toString());

    _selectedGender = widget.data.gender;
  }

  void _setupListeners() {
    // Auto-calculate BMI when weight or height changes (if enabled)
    _weightController.addListener(_calculateBMI);
    _heightController.addListener(_calculateBMI);
    
    // Auto-calculate segmental data when main values change (if enabled)
    _subcutaneousFatController.addListener(_calculateSegmentalData);
    _skeletalMuscleController.addListener(_calculateSegmentalData);

    // Track changes
    _patientNameController.addListener(_onFieldChanged);
    _whatsappController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _bodyFatController.addListener(_onFieldChanged);
    _bmiController.addListener(_onFieldChanged);
    _skeletalMuscleController.addListener(_onFieldChanged);
    _visceralFatController.addListener(_onFieldChanged);
    _restingMetabolismController.addListener(_onFieldChanged);
    _bodyAgeController.addListener(_onFieldChanged);
    _subcutaneousFatController.addListener(_onFieldChanged);
    
    // Add name formatting
    _patientNameController.addListener(_formatPatientName);
  }

  void _onFieldChanged() {
    if (!_isUpdated) {
      setState(() {
        _isUpdated = true;
      });
    }
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
    
    final subcutaneousFat = OmronData.parseDecimalInput(_subcutaneousFatController.text);
    final skeletalMuscle = OmronData.parseDecimalInput(_skeletalMuscleController.text);
    
    if (subcutaneousFat > 0) {
      final segmental = OmronData.calculateSegmentalSubcutaneousFat(subcutaneousFat);
      _segSubTrunkController.text = segmental['trunk']!.toStringAsFixed(1);
      _segSubRightArmController.text = segmental['rightArm']!.toStringAsFixed(1);
      _segSubLeftArmController.text = segmental['leftArm']!.toStringAsFixed(1);
      _segSubRightLegController.text = segmental['rightLeg']!.toStringAsFixed(1);
      _segSubLeftLegController.text = segmental['leftLeg']!.toStringAsFixed(1);
    }
    
    if (skeletalMuscle > 0) {
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _buildResponsiveBody(),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isUpdated) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Perubahan Belum Disimpan'),
          content: const Text('Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Keluar'),
            ),
          ],
        ),
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Data Omron',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.data.patientName,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_isUpdated) ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetToOriginal,
              tooltip: 'Reset ke data asli',
            ),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.preview),
          onPressed: _previewUpdatedData,
          tooltip: 'Preview perubahan',
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
                    _buildAdditionalDataCard(),
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
        if (_previewResult != null)
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
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: OmronResultCard(data: _previewResult!),
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
            _buildHeaderCard(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPatientInfoCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildBasicOmronDataCard()),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdditionalDataCard(),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            if (_previewResult != null) ...[
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
            _buildAdditionalDataCard(),
            const SizedBox(height: 16),
            _buildSegmentalDataCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            if (_previewResult != null) ...[
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
                    'Data Asli: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.data.timestamp)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (widget.data.isWhatsAppSent) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Sudah dikirim via WhatsApp',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_isUpdated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ada Perubahan',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
          _isUpdated = true;
        });
      },
    );
  }

  // [Implement other build methods similar to OmronInputScreen but with edit-specific modifications]
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
            
            _buildNumberInputField(
              controller: _weightController,
              label: 'Berat Badan (kg)',
              icon: Icons.scale,
              hint: 'Contoh: 75,5 atau 75.5',
              suffix: 'kg',
            ),
            
            _buildNumberInputField(
              controller: _bodyFatController,
              label: 'Body Fat (%)',
              icon: Icons.pie_chart_outline,
              hint: 'Contoh: 18,5 atau 18.5',
              suffix: '%',
            ),
            
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
                          _isUpdated = true;
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
              controller: _skeletalMuscleController,
              label: 'Skeletal Muscle (%)',
              icon: Icons.fitness_center,
              hint: 'Contoh: 42,1 atau 42.1',
              suffix: '%',
            ),
            
            _buildNumberInputField(
              controller: _visceralFatController,
              label: 'Visceral Fat',
              icon: Icons.favorite_outline,
              hint: 'Contoh: 8,5 atau 8.5',
              isInteger: false,
            ),
            
            _buildNumberInputField(
              controller: _restingMetabolismController,
              label: 'Metabolism (kcal)',
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
        ),
      ),
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
                Icon(Icons.add_circle, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data Tambahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildNumberInputField(
              controller: _subcutaneousFatController,
              label: 'Subcutaneous Fat (%)',
              icon: Icons.layers,
              hint: 'Contoh: 15,2 atau 15.2',
              suffix: '%',
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
                    'Data Segmental',
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
                          _isUpdated = true;
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
            
            Text(
              'Subcutaneous Fat per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildNumberInputField(
                    controller: _segSubTrunkController,
                    label: 'Trunk',
                    icon: Icons.airline_seat_recline_normal,
                    hint: '0,0',
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
                    hint: '0,0',
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
                    controller: _segSubLeftArmController,
                    label: 'Left Arm',
                    icon: Icons.front_hand,
                    hint: '0,0',
                    suffix: '%',
                    enabled: !_autoCalculateSegmental,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberInputField(
                    controller: _segSubRightLegController,
                    label: 'Right Leg',
                    icon: Icons.directions_walk,
                    hint: '0,0',
                    suffix: '%',
                    enabled: !_autoCalculateSegmental,
                  ),
                ),
              ],
            ),
            _buildNumberInputField(
              controller: _segSubLeftLegController,
              label: 'Left Leg',
              icon: Icons.directions_run,
              hint: '0,0',
              suffix: '%',
              enabled: !_autoCalculateSegmental,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Skeletal Muscle per Segmen (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildNumberInputField(
                    controller: _segMusTrunkController,
                    label: 'Trunk',
                    icon: Icons.airline_seat_recline_normal,
                    hint: '0,0',
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
                    hint: '0,0',
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
                    controller: _segMusLeftArmController,
                    label: 'Left Arm',
                    icon: Icons.front_hand,
                    hint: '0,0',
                    suffix: '%',
                    enabled: !_autoCalculateSegmental,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberInputField(
                    controller: _segMusRightLegController,
                    label: 'Right Leg',
                    icon: Icons.directions_walk,
                    hint: '0,0',
                    suffix: '%',
                    enabled: !_autoCalculateSegmental,
                  ),
                ),
              ],
            ),
            _buildNumberInputField(
              controller: _segMusLeftLegController,
              label: 'Left Leg',
              icon: Icons.directions_run,
              hint: '0,0',
              suffix: '%',
              enabled: !_autoCalculateSegmental,
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
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: enabled ? Colors.blue[700] : Colors.grey),
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
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
            final normalizedValue = value.replaceAll(',', '.');
            if (double.tryParse(normalizedValue) == null) {
              return 'Masukkan angka yang valid (gunakan koma atau titik untuk desimal)';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previewUpdatedData,
                icon: const Icon(Icons.preview),
                label: const Text('Preview Perubahan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUpdated ? _resetToOriginal : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  side: BorderSide(color: Colors.orange[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : (_isUpdated ? _updateData : null),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, size: 24),
            label: Text(
              _isLoading 
                ? 'Menyimpan...' 
                : _isUpdated 
                  ? 'Simpan Perubahan' 
                  : 'Tidak Ada Perubahan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUpdated ? Colors.blue[700] : Colors.grey[400],
              foregroundColor: Colors.white,
              elevation: _isUpdated ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                      'Preview Perubahan 👀',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      'Hasil setelah perubahan diterapkan',
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
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_previewResult == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        _buildPreviewHeader(),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: OmronResultCard(data: _previewResult!),
        ),
      ],
    );
  }

  Future<void> _previewUpdatedData() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    try {
      final updatedData = _createUpdatedOmronData();
      setState(() {
        _previewResult = updatedData;
      });
      
      _showSuccessSnackBar('Preview berhasil dibuat! Scroll ke bawah untuk melihat hasil.');
      
      // Scroll to preview on mobile/tablet
      if (MediaQuery.of(context).size.width <= 1200) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal membuat preview: $e');
    }
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Update'),
        content: const Text('Apakah Anda yakin ingin menyimpan perubahan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (shouldUpdate != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = _createUpdatedOmronData();
      
      await _databaseService.updateOmronData(updatedData);
      
      setState(() {
        _isLoading = false;
        _isUpdated = false;
      });

      _showSuccessSnackBar('Data berhasil diperbarui!');
      
      // Show success dialog
      _showUpdateSuccessDialog();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memperbarui data: $e');
    }
  }

  OmronData _createUpdatedOmronData() {
    // Get segmental data
    Map<String, double> segmentalSubcutaneous = {
      'trunk': OmronData.parseDecimalInput(_segSubTrunkController.text),
      'rightArm': OmronData.parseDecimalInput(_segSubRightArmController.text),
      'leftArm': OmronData.parseDecimalInput(_segSubLeftArmController.text),
      'rightLeg': OmronData.parseDecimalInput(_segSubRightLegController.text),
      'leftLeg': OmronData.parseDecimalInput(_segSubLeftLegController.text),
    };

    Map<String, double> segmentalSkeletal = {
      'trunk': OmronData.parseDecimalInput(_segMusTrunkController.text),
      'rightArm': OmronData.parseDecimalInput(_segMusRightArmController.text),
      'leftArm': OmronData.parseDecimalInput(_segMusLeftArmController.text),
      'rightLeg': OmronData.parseDecimalInput(_segMusRightLegController.text),
      'leftLeg': OmronData.parseDecimalInput(_segMusLeftLegController.text),
    };

    // Calculate same age comparison
    final bodyFat = OmronData.parseDecimalInput(_bodyFatController.text);
    final age = int.parse(_ageController.text);
    final sameAgeComparison = OmronData.calculateSameAgeComparison(bodyFat, age, _selectedGender);

    return widget.data.copyWith(
      patientName: _patientNameController.text.trim(),
      whatsappNumber: _whatsappController.text.trim().isEmpty 
        ? null 
        : _whatsappController.text.trim(),
      age: age,
      gender: _selectedGender,
      height: OmronData.parseDecimalInput(_heightController.text),
      weight: OmronData.parseDecimalInput(_weightController.text),
      bodyFatPercentage: bodyFat,
      bmi: OmronData.parseDecimalInput(_bmiController.text),
      skeletalMusclePercentage: OmronData.parseDecimalInput(_skeletalMuscleController.text),
      visceralFatLevel: OmronData.parseDecimalInput(_visceralFatController.text),
      restingMetabolism: int.parse(_restingMetabolismController.text),
      bodyAge: int.parse(_bodyAgeController.text),
      subcutaneousFatPercentage: OmronData.parseDecimalInput(_subcutaneousFatController.text),
      segmentalSubcutaneousFat: segmentalSubcutaneous,
      segmentalSkeletalMuscle: segmentalSkeletal,
      sameAgeComparison: sameAgeComparison,
      // Keep original WhatsApp sent status
      isWhatsAppSent: widget.data.isWhatsAppSent,
      whatsappSentAt: widget.data.whatsappSentAt,
    );
  }

  void _resetToOriginal() {
    setState(() {
      _initializeControllers();
      _isUpdated = false;
      _previewResult = null;
    });
    _showInfoSnackBar('Data telah direset ke nilai asli');
  }

  void _showUpdateSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Data Berhasil Diperbarui! ✅'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Perubahan data Omron telah berhasil disimpan ke database.'),
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
                      'Pasien: ${_patientNameController.text}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Data Asli: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.data.timestamp)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Diperbarui: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: TextStyle(color: Colors.green[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return true to indicate update success
              },
              child: const Text('Kembali ke Riwayat'),
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

  void _scrollToFirstError() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
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