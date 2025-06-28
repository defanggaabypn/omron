import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PatientInfoCard extends StatefulWidget {
  final TextEditingController patientNameController;
  final TextEditingController whatsappController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final String selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final bool isEditing; // ✅ Parameter baru

  const PatientInfoCard({
    super.key,
    required this.patientNameController,
    required this.whatsappController,
    required this.ageController,
    required this.heightController,
    required this.selectedGender,
    required this.onGenderChanged,
    this.isEditing = false, // ✅ Default false
  });

  @override
  State<PatientInfoCard> createState() => _PatientInfoCardState();
}

class _PatientInfoCardState extends State<PatientInfoCard> {
  @override
  void initState() {
    super.initState();
    // Listener untuk format nama otomatis sudah dipindahkan ke parent
    // Tambahkan listener untuk WhatsApp number formatting
    widget.whatsappController.addListener(_formatWhatsAppNumber);
  }

  // Format nomor WhatsApp (opsional, untuk membersihkan format)
  void _formatWhatsAppNumber() {
    final text = widget.whatsappController.text;
    final selection = widget.whatsappController.selection;
    
    // Remove any non-digit characters
    final cleanedText = text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Hanya update jika ada perubahan
    if (cleanedText != text) {
      widget.whatsappController.value = TextEditingValue(
        text: cleanedText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset <= cleanedText.length 
            ? selection.baseOffset 
            : cleanedText.length,
        ),
      );
    }
  }

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
                    color: widget.isEditing ? Colors.orange[100] : Colors.blue[100], // ✅ Warna berbeda saat edit
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isEditing ? Icons.edit : Icons.person, // ✅ Icon berbeda saat edit
                    color: widget.isEditing ? Colors.orange[700] : Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isEditing ? 'Edit Informasi Pasien' : 'Informasi Pasien', // ✅ Title berbeda
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isEditing ? Colors.orange[700] : Colors.blue[700],
                    ),
                  ),
                ),
                // ✅ Badge "EDIT" saat mode editing
                if (widget.isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Text(
                      'EDIT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            
            // ✅ Info tambahan saat mode edit
            if (widget.isEditing) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode Edit: Ubah data sesuai kebutuhan, lalu klik Preview untuk melihat hasil',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Patient Name Field - DENGAN FORMAT OTOMATIS
            _buildTextFormField(
              controller: widget.patientNameController,
              label: 'Nama Pasien',
              icon: Icons.person_outline,
              hint: 'Masukkan nama lengkap pasien',
              textCapitalization: TextCapitalization.words, // Capitalize words
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
            
            // WhatsApp Number Field
            _buildTextFormField(
              controller: widget.whatsappController,
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
                  // Validasi format nomor Indonesia
                  if (!RegExp(r'^(08|628|62|8)').hasMatch(value)) {
                    return 'Format nomor tidak valid (gunakan 08xxx atau 628xxx)';
                  }
                }
                return null; // Field ini opsional
              },
              suffixIcon: widget.whatsappController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        widget.whatsappController.clear();
                        setState(() {}); // Refresh untuk update suffix icon
                      },
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
                    controller: widget.ageController,
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
                    controller: widget.heightController,
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
            
            // Gender Selection - FIXED LAYOUT untuk mengatasi overflow
            Text(
              'Jenis Kelamin',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            
            // FIXED: Gunakan layout yang lebih responsif
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isEditing ? Colors.orange[300]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Pria
                    Expanded(
                      child: InkWell(
                        onTap: () => widget.onGenderChanged('Male'),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.selectedGender == 'Male' 
                              ? (widget.isEditing ? Colors.orange[50] : Colors.blue[50])
                              : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: 'Male',
                                groupValue: widget.selectedGender,
                                onChanged: widget.onGenderChanged,
                                activeColor: widget.isEditing ? Colors.orange[700] : Colors.blue[700],
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              Icon(
                                Icons.male, 
                                color: widget.selectedGender == 'Male' 
                                  ? (widget.isEditing ? Colors.orange[700] : Colors.blue[700])
                                  : Colors.grey[600], 
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Pria',
                                  style: TextStyle(
                                    color: widget.selectedGender == 'Male' 
                                      ? (widget.isEditing ? Colors.orange[700] : Colors.blue[700])
                                      : Colors.grey[700],
                                    fontWeight: widget.selectedGender == 'Male' 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Divider
                    Container(
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    
                    // Wanita
                    Expanded(
                      child: InkWell(
                        onTap: () => widget.onGenderChanged('Female'),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.selectedGender == 'Female' 
                              ? (widget.isEditing ? Colors.orange[50] : Colors.pink[50])
                              : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: 'Female',
                                groupValue: widget.selectedGender,
                                onChanged: widget.onGenderChanged,
                                activeColor: widget.isEditing ? Colors.orange[700] : Colors.pink[700],
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              Icon(
                                Icons.female, 
                                color: widget.selectedGender == 'Female' 
                                  ? (widget.isEditing ? Colors.orange[700] : Colors.pink[700])
                                  : Colors.grey[600], 
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Wanita',
                                  style: TextStyle(
                                    color: widget.selectedGender == 'Female' 
                                      ? (widget.isEditing ? Colors.orange[700] : Colors.pink[700])
                                      : Colors.grey[700],
                                    fontWeight: widget.selectedGender == 'Female' 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Info text untuk WhatsApp
            if (widget.whatsappController.text.isNotEmpty) ...[
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
                        widget.isEditing 
                          ? 'Laporan yang sudah diedit dapat dikirim ulang ke WhatsApp'
                          : 'Laporan dapat langsung dikirim ke WhatsApp setelah analisis selesai',
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
            
            // Format info untuk nama
            if (widget.patientNameController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isEditing ? Colors.orange[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.isEditing ? Colors.orange[200]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_fix_high, 
                      color: widget.isEditing ? Colors.orange[700] : Colors.blue[700], 
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nama otomatis diformat dengan huruf kapital di setiap kata',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isEditing ? Colors.orange[700] : Colors.blue[700],
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
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon, 
          color: widget.isEditing ? Colors.orange[700] : Colors.blue[700], // ✅ Warna berbeda saat edit
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isEditing ? Colors.orange[700]! : Colors.blue[700]!, // ✅ Warna berbeda
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: validator,
      onChanged: (value) {
        // Trigger rebuild untuk update suffix icon dan info text
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    widget.whatsappController.removeListener(_formatWhatsAppNumber);
    super.dispose();
  }
}