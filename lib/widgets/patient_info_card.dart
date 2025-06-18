import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PatientInfoCard extends StatelessWidget {
  final TextEditingController patientNameController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final String selectedGender;
  final ValueChanged<String?> onGenderChanged;

  const PatientInfoCard({
    Key? key,
    required this.patientNameController,
    required this.ageController,
    required this.heightController,
    required this.selectedGender,
    required this.onGenderChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.orange[700]),
                SizedBox(width: 8),
                Text(
                  'Informasi Pasien',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Patient Name
            TextFormField(
              controller: patientNameController,
              decoration: InputDecoration(
                labelText: 'Nama Pasien',
                hintText: 'Masukkan nama lengkap',
                prefixIcon: Icon(Icons.badge, color: Colors.orange[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Nama pasien harus diisi';
                }
                if (value!.length < 2) {
                  return 'Nama minimal 2 karakter';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Age and Gender Row
            Row(
              children: [
                // Age
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: ageController,
                    decoration: InputDecoration(
                      labelText: 'Usia (tahun)',
                      hintText: 'Contoh: 25',
                      prefixIcon: Icon(Icons.cake, color: Colors.orange[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Usia harus diisi';
                      }
                      final age = int.tryParse(value!);
                      if (age == null || age < 18 || age > 100) {
                        return 'Usia harus antara 18-100 tahun';
                      }
                      return null;
                    },
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Gender
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jenis Kelamin',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Pria', style: TextStyle(fontSize: 14)),
                                value: 'Male',
                                groupValue: selectedGender,
                                onChanged: onGenderChanged,
                                activeColor: Colors.orange[700],
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Wanita', style: TextStyle(fontSize: 14)),
                                value: 'Female',
                                groupValue: selectedGender,
                                onChanged: onGenderChanged,
                                activeColor: Colors.orange[700],
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Height
            TextFormField(
              controller: heightController,
              decoration: InputDecoration(
                labelText: 'Tinggi Badan (cm)',
                hintText: 'Contoh: 170',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.height, color: Colors.orange[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Tinggi badan harus diisi';
                }
                final height = double.tryParse(value!);
                if (height == null || height < 100 || height > 250) {
                  return 'Tinggi badan harus antara 100-250 cm';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
