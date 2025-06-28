import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';

class PDFService {
  static Future<String> generateOmronReport(OmronData data) async {
    final pdf = pw.Document();
    
    // Add pages to PDF
    pdf.addPage(_buildCoverPage(data));
    pdf.addPage(_buildBasicAnalysisPage(data));
    pdf.addPage(_buildAdvancedAnalysisPage(data));
    pdf.addPage(_buildSegmentalAnalysisPage(data));
    pdf.addPage(_buildRecommendationsPage(data));
    
    // Save PDF to device
    final String fileName = 'Omron_Report_${data.patientName}_${DateFormat('yyyyMMdd_HHmm').format(data.timestamp)}.pdf';
    final String filePath = await _savePDF(pdf, fileName);
    
    return filePath;
  }

  static pw.Page _buildCoverPage(OmronData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'LAPORAN ANALISIS OMRON HBF-375',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Body Composition Monitor - Lampung Sport Health Center',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 40),
            
            // Patient Info
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORMASI PASIEN',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildInfoRow('Nama Pasien', data.patientName),
                  _buildInfoRow('Usia', '${data.age} tahun'),
                  _buildInfoRow('Jenis Kelamin', data.gender == 'Male' ? 'Pria' : 'Wanita'),
                  _buildInfoRow('Tinggi Badan', '${data.height.toStringAsFixed(0)} cm'),
                  _buildInfoRow('Tanggal Pengukuran', DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(data.timestamp)),
                  // TAMBAHKAN WHATSAPP JIKA ADA
                  if (data.whatsappNumber?.isNotEmpty ?? false)
                    _buildInfoRow('WhatsApp', data.whatsappNumber!),
                ],
              ),
            ),
            
            pw.SizedBox(height: 40),
            
            // Overall Assessment
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _getAssessmentColor(data.overallAssessment),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'PENILAIAN KESELURUHAN',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    data.overallAssessment.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.Spacer(),
            
            // Footer
            pw.Center(
              child: pw.Text(
                'Generated by LSHC Omron App',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static pw.Page _buildBasicAnalysisPage(OmronData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('ANALISIS DASAR (7 INDIKATOR)'),
            
            pw.SizedBox(height: 20),
            
            // Basic Measurements Grid
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildTableHeader(['Parameter', 'Nilai', 'Status', 'Kategori']),
                _buildMeasurementRow('Berat Badan', '${data.weight.toStringAsFixed(1)} kg', 'Normal', ''),
                _buildMeasurementRow('BMI', data.bmi.toStringAsFixed(1), data.bmiCategory, _getBMIDescription(data.bmiCategory)),
                _buildMeasurementRow('Body Fat', '${data.bodyFatPercentage.toStringAsFixed(1)}%', data.bodyFatCategory, _getBodyFatDescription(data.bodyFatCategory)),
                _buildMeasurementRow('Skeletal Muscle', '${data.skeletalMusclePercentage.toStringAsFixed(1)}%', _getSkeletalMuscleCategory(data.skeletalMusclePercentage), ''),
                _buildMeasurementRow('Visceral Fat', data.visceralFatLevel.toStringAsFixed(1), _getVisceralFatCategory(data.visceralFatLevel), _getVisceralFatDescription(data.visceralFatLevel)),
                _buildMeasurementRow('Resting Metabolism', '${data.restingMetabolism} kcal', 'Normal', ''),
                _buildMeasurementRow('Body Age', '${data.bodyAge} tahun', _getBodyAgeStatus(data.bodyAge, data.age), ''),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Basic Analysis Summary
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RINGKASAN ANALISIS DASAR',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _generateBasicSummary(data),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static pw.Page _buildAdvancedAnalysisPage(OmronData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('ANALISIS LANJUTAN'),
            
            pw.SizedBox(height: 20),
            
            // Advanced Measurements
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildTableHeader(['Parameter', 'Nilai', 'Status', 'Deskripsi']),
                _buildMeasurementRow(
                  'Subcutaneous Fat', 
                  '${data.subcutaneousFatPercentage.toStringAsFixed(1)}%', 
                  _getSubcutaneousFatCategory(data.subcutaneousFatPercentage),
                  _getSubcutaneousFatDescription(data.subcutaneousFatPercentage),
                ),
                _buildMeasurementRow(
                  'Same Age Comparison', 
                  '${data.sameAgeComparison.toStringAsFixed(0)}th percentile', 
                  data.sameAgeCategory,
                  _getSameAgeDescription(data.sameAgeComparison),
                ),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Same Age Comparison Details
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PERBANDINGAN USIA SEBAYA',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Posisi Anda: ${data.sameAgeComparison.toStringAsFixed(0)}th Percentile (${data.sameAgeCategory})',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    _getSameAgeDescription(data.sameAgeComparison),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Advanced Analysis Summary
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple50,
                border: pw.Border.all(color: PdfColors.purple),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ANALISIS LANJUTAN',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _generateAdvancedSummary(data),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static pw.Page _buildSegmentalAnalysisPage(OmronData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('ANALISIS SEGMENTAL'),
            
            pw.SizedBox(height: 20),
            
            // Subcutaneous Fat Segmental - FIXED STRUCTURE
            pw.Text(
              'DISTRIBUSI SUBCUTANEOUS FAT (%)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple,
              ),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildTableHeader(['Bagian Tubuh', 'Nilai (%)', 'Status']),
                _buildSegmentalRow('Whole Body (Seluruh Tubuh)', data.segmentalSubcutaneousFat['wholeBody'] ?? 0.0),
                _buildSegmentalRow('Trunk (Batang Tubuh)', data.segmentalSubcutaneousFat['trunk'] ?? 0.0),
                _buildSegmentalRow('Arms (Kedua Lengan)', data.segmentalSubcutaneousFat['arms'] ?? 0.0),
                _buildSegmentalRow('Legs (Kedua Kaki)', data.segmentalSubcutaneousFat['legs'] ?? 0.0),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Skeletal Muscle Segmental - FIXED STRUCTURE
            pw.Text(
              'DISTRIBUSI SKELETAL MUSCLE (%)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red,
              ),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildTableHeader(['Bagian Tubuh', 'Nilai (%)', 'Status']),
                _buildSegmentalRow('Whole Body (Seluruh Tubuh)', data.segmentalSkeletalMuscle['wholeBody'] ?? 0.0),
                _buildSegmentalRow('Trunk (Batang Tubuh)', data.segmentalSkeletalMuscle['trunk'] ?? 0.0),
                _buildSegmentalRow('Arms (Kedua Lengan)', data.segmentalSkeletalMuscle['arms'] ?? 0.0),
                _buildSegmentalRow('Legs (Kedua Kaki)', data.segmentalSkeletalMuscle['legs'] ?? 0.0),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Segmental Analysis
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ANALISIS DISTRIBUSI',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _generateSegmentalAnalysis(data),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static pw.Page _buildRecommendationsPage(OmronData data) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('REKOMENDASI & SARAN'),
            
            pw.SizedBox(height: 20),
            
            // Basic Recommendations
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REKOMENDASI DASAR',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ..._generateBasicRecommendations(data).map((rec) => 
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(child: pw.Text(rec, style: const pw.TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Advanced Recommendations
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REKOMENDASI LANJUTAN',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ..._generateAdvancedRecommendations(data).map((rec) => 
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(child: pw.Text(rec, style: const pw.TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Footer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'CATATAN PENTING',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Hasil analisis ini berdasarkan pengukuran Omron HBF-375 dan merupakan indikator umum kondisi tubuh. '
                    'Untuk interpretasi medis yang akurat, konsultasikan dengan dokter atau ahli gizi profesional. '
                    'Lakukan pengukuran secara rutin untuk monitoring yang optimal.',
                    style: const pw.TextStyle(fontSize: 11),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Generated by LSHC Omron App | ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper methods
  static pw.Widget _buildPageHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableHeader(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.orange),
      children: headers.map((header) => 
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            header,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ).toList(),
    );
  }

  static pw.TableRow _buildMeasurementRow(String parameter, String value, String status, String description) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(parameter),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(status, textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(description, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  static pw.TableRow _buildSegmentalRow(String bodyPart, double value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(bodyPart),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value.toStringAsFixed(1), textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(_getSegmentalStatus(value), textAlign: pw.TextAlign.center),
        ),
      ],
    );
  }

  static Future<String> _savePDF(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    final Uint8List pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Helper functions for categorization
  static PdfColor _getAssessmentColor(String assessment) {
    switch (assessment) {
      case 'Sangat Baik': return PdfColors.green;
      case 'Baik': return PdfColors.blue;
      case 'Cukup': return PdfColors.orange;
      default: return PdfColors.red;
    }
  }

  static String _getBMIDescription(String category) {
    switch (category) {
      case 'Normal': return 'Berat badan ideal';
      case 'Overweight': return 'Kelebihan berat badan';
      case 'Obese': return 'Obesitas';
      case 'Underweight': return 'Kekurangan berat badan';
      default: return '';
    }
  }

  static String _getBodyFatDescription(String category) {
    switch (category) {
      case 'Athletes': return 'Level atlet';
      case 'Fitness': return 'Level fitness';
      case 'Average': return 'Level rata-rata';
      case 'Obese': return 'Terlalu tinggi';
      case 'Essential Fat': return 'Lemak esensial';
      default: return '';
    }
  }

  static String _getSkeletalMuscleCategory(double percentage) {
    if (percentage < 25) return 'Rendah';
    if (percentage < 35) return 'Normal';
    if (percentage < 45) return 'Tinggi';
    return 'Sangat Tinggi';
  }

  static String _getVisceralFatCategory(double level) {
    if (level <= 9.0) return 'Normal';
    if (level <= 14.0) return 'Tinggi';
    return 'Sangat Tinggi';
  }

  static String _getVisceralFatDescription(double level) {
    if (level <= 9.0) return 'Dalam batas normal';
    if (level <= 14.0) return 'Agak tinggi';
    return 'Sangat tinggi';
  }

  static String _getSubcutaneousFatCategory(double percentage) {
    if (percentage <= 10) return 'Rendah';
    if (percentage <= 20) return 'Normal';
    if (percentage <= 30) return 'Tinggi';
    return 'Sangat Tinggi';
  }

  static String _getSubcutaneousFatDescription(double percentage) {
    if (percentage <= 10) return 'Level rendah';
    if (percentage <= 20) return 'Level normal';
    if (percentage <= 30) return 'Level tinggi';
    return 'Level sangat tinggi';
  }

  static String _getSameAgeDescription(double percentile) {
    if (percentile >= 90) return 'Anda berada di 10% teratas untuk usia Anda';
    if (percentile >= 75) return 'Anda berada di 25% teratas untuk usia Anda';
    if (percentile >= 50) return 'Anda berada di rata-rata untuk usia Anda';
    if (percentile >= 25) return 'Anda berada di bawah rata-rata untuk usia Anda';
    return 'Anda berada di 25% terbawah untuk usia Anda';
  }

  static String _getBodyAgeStatus(int bodyAge, int actualAge) {
    final diff = bodyAge - actualAge;
    if (diff <= -5) return 'Sangat Baik';
    if (diff <= 0) return 'Baik';
    if (diff <= 5) return 'Rata-rata';
    return 'Perlu Perbaikan';
  }

  static String _getSegmentalStatus(double value) {
    if (value <= 10) return 'Rendah';
    if (value <= 20) return 'Normal';
    if (value <= 30) return 'Tinggi';
    return 'Sangat Tinggi';
  }

  // FIXED Summary generators dengan struktur baru
  static String _generateBasicSummary(OmronData data) {
    return 'Berdasarkan 7 indikator dasar Omron HBF-375, kondisi keseluruhan Anda dinilai ${data.overallAssessment}. '
           'BMI Anda ${data.bmi.toStringAsFixed(1)} termasuk kategori ${data.bmiCategory}, dengan persentase lemak tubuh ${data.bodyFatPercentage.toStringAsFixed(1)}% (${data.bodyFatCategory}). '
           'Level lemak viseral Anda ${data.visceralFatLevel.toStringAsFixed(1)} (${_getVisceralFatCategory(data.visceralFatLevel)}).';
  }

  static String _generateAdvancedSummary(OmronData data) {
    return 'Analisis lanjutan menunjukkan lemak subkutan ${data.subcutaneousFatPercentage.toStringAsFixed(1)}% (${_getSubcutaneousFatCategory(data.subcutaneousFatPercentage)}). '
           'Dibandingkan dengan orang seusia Anda, Anda berada di posisi ${data.sameAgeComparison.toStringAsFixed(0)} persentil (${data.sameAgeCategory}).';
  }

  // FIXED Segmental analysis dengan struktur baru
  static String _generateSegmentalAnalysis(OmronData data) {
    final trunk = data.segmentalSubcutaneousFat['trunk'] ?? 0.0;
    final arms = data.segmentalSubcutaneousFat['arms'] ?? 0.0;
    final legs = data.segmentalSubcutaneousFat['legs'] ?? 0.0;
    
    String highestArea = 'trunk';
    double highestValue = trunk;
    
    if (arms > highestValue) {
      highestArea = 'lengan';
      highestValue = arms;
    }
    if (legs > highestValue) {
      highestArea = 'kaki';
      highestValue = legs;
    }
    
    return 'Distribusi lemak subkutan menunjukkan konsentrasi tertinggi di area $highestArea (${highestValue.toStringAsFixed(1)}%). '
           'Distribusi otot rangka relatif seimbang dengan trunk ${(data.segmentalSkeletalMuscle['trunk'] ?? 0.0).toStringAsFixed(1)}%, '
           'lengan ${(data.segmentalSkeletalMuscle['arms'] ?? 0.0).toStringAsFixed(1)}%, '
           'dan kaki ${(data.segmentalSkeletalMuscle['legs'] ?? 0.0).toStringAsFixed(1)}%.';
  }

  static List<String> _generateBasicRecommendations(OmronData data) {
    List<String> recommendations = [];
    
    if (data.bmi < 18.5) {
      recommendations.add('Tingkatkan asupan kalori dengan makanan bergizi untuk mencapai berat badan ideal');
    } else if (data.bmi >= 25.0) {
      recommendations.add('Perbanyak aktivitas fisik dan kurangi asupan kalori untuk menurunkan berat badan');
    }
    
    if (data.bodyFatPercentage > 25 && data.gender == 'Male') {
      recommendations.add('Fokus pada latihan kardio dan strength training untuk mengurangi lemak tubuh');
    } else if (data.bodyFatPercentage > 32 && data.gender == 'Female') {
      recommendations.add('Fokus pada latihan kardio dan strength training untuk mengurangi lemak tubuh');
    }
    
    if (data.visceralFatLevel > 9.0) {
      recommendations.add('Kurangi lemak visceral dengan diet seimbang rendah gula dan lemak jenuh');
    }
    
    recommendations.add('Lakukan pengukuran rutin setiap minggu untuk monitoring progress');
    
    return recommendations;
  }

  static List<String> _generateAdvancedRecommendations(OmronData data) {
    List<String> recommendations = [];
    
    if (data.subcutaneousFatPercentage > 20) {
      recommendations.add('Kurangi lemak subkutan dengan kombinasi yoga, cardio, dan resistance training');
    }
    
    if (data.sameAgeComparison < 50) {
      recommendations.add('Tingkatkan program fitness untuk menyamai atau melampaui teman sebaya');
    }
    
    // FIXED: Cari nilai maksimum segmental fat dengan null safety
    final segmentalValues = data.segmentalSubcutaneousFat.values.where((v) => v != null);
    if (segmentalValues.isNotEmpty) {
      final maxSegFat = segmentalValues.reduce((a, b) => a > b ? a : b);
      if (maxSegFat > 15) {
        recommendations.add('Fokus latihan pada area dengan lemak tinggi untuk hasil yang optimal');
      }
    }
    
    recommendations.add('Konsultasikan dengan ahli gizi untuk program diet dan latihan yang tepat');
    recommendations.add('Pertimbangkan konsultasi dengan personal trainer untuk program latihan terstruktur');
    
    return recommendations;
  }
}