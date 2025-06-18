import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PatientInfoCard extends StatelessWidget {
  final TextEditingController patientNameController;
  final TextEditingController whatsappController; // CONTROLLER BARU
  final TextEditingController ageController;
  final TextEditingController heightController;
  final String selectedGender;
  final ValueChanged<String?> onGenderChanged;

  const PatientInfoCard({
    super.key,
    required this.patientNameController,
    required this.whatsappController, // PARAMETER BARU
    required this.ageController,
    required this.heightController,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Informasi Pasien',
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
            
            // Patient Name Field
            _buildTextFormField(
              controller: patientNameController,
              label: 'Nama Pasien',
              icon: Icons.person_outline,
              hint: 'Masukkan nama lengkap pasien',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pasien harus diisi';
                }
                if (value.trim().length < 2) {
                  return 'Nama pasien minimal 2 karakter';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 12),
            
            // WhatsApp Number Field - FIELD BARU
            _buildTextFormField(
              controller: whatsappController,
              label: 'Nomor WhatsApp (Opsional)',
              icon: Icons.chat,
              hint: 'Contoh: 08123456789 atau 628123456789',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length < 10) {
                    return 'Nomor WhatsApp minimal 10 digit';
                  }
                  if (value.length > 15) {
                    return 'Nomor WhatsApp maksimal 15 digit';
                  }
                }
                return null; // Field ini opsional
              },
              suffixIcon: whatsappController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () => whatsappController.clear(),
                      tooltip: 'Hapus nomor',
                    )
                  : null,
            ),
            
            const SizedBox(height: 12),
            
            // Age and Height in Row
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: ageController,
                    label: 'Usia (tahun)',
                    icon: Icons.cake,
                    hint: 'Contoh: 25',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Usia harus diisi';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 1 || age > 120) {
                        return 'Usia harus antara 1-120 tahun';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    controller: heightController,
                    label: 'Tinggi (cm)',
                    icon: Icons.height,
                    hint: 'Contoh: 170',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tinggi badan harus diisi';
                      }
                      final height = double.tryParse(value);
                      if (height == null || height < 50 || height > 250) {
                        return 'Tinggi harus antara 50-250 cm';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Gender Selection
            Text(
              'Jenis Kelamin',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.male, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 4),
                          const Text('Pria'),
                        ],
                      ),
                      value: 'Male',
                      groupValue: selectedGender,
                      onChanged: onGenderChanged,
                      activeColor: Colors.blue[700],
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.female, color: Colors.pink[600], size: 20),
                          const SizedBox(width: 4),
                          const Text('Wanita'),
                        ],
                      ),
                      value: 'Female',
                      groupValue: selectedGender,
                      onChanged: onGenderChanged,
                      activeColor: Colors.pink[700],
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
            
            // Info text untuk WhatsApp
            if (whatsappController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Laporan dapat langsung dikirim ke WhatsApp setelah analisis selesai',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: validator,
    );
  }
}