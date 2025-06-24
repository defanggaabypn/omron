import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/omron_data.dart';

class WhatsAppDirectService {
  // Method untuk kirim caption langsung ke WhatsApp dengan nomor
  static Future<void> sendToWhatsAppWithNumber({
    required String phoneNumber,
    required OmronData data,
    required String captionType,
    String? pdfPath,
  }) async {
    try {
      // Generate caption
      final String caption = generateCaption(data, captionType);
      
      // Format nomor telepon
      final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      String formattedNumber = cleanNumber;
      
      // Tambahkan country code jika belum ada
      if (!formattedNumber.startsWith('62')) {
        if (formattedNumber.startsWith('0')) {
          formattedNumber = '62${formattedNumber.substring(1)}';
        } else {
          formattedNumber = '62$formattedNumber';
        }
      }
      
      // Encode caption untuk URL
      final String encodedCaption = Uri.encodeComponent(caption);
      
      // Coba beberapa URL scheme WhatsApp
      List<String> whatsappUrls = [
        'whatsapp://send?phone=$formattedNumber&text=$encodedCaption',
        'https://wa.me/$formattedNumber?text=$encodedCaption',
        'https://api.whatsapp.com/send?phone=$formattedNumber&text=$encodedCaption',
      ];
      
      bool success = false;
      
      // Coba setiap URL sampai berhasil
      for (String url in whatsappUrls) {
        try {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri, 
              mode: LaunchMode.externalApplication,
            );
            success = true;
            break;
          }
        } catch (e) {
          // Lanjut ke URL berikutnya
          continue;
        }
      }
      
      if (!success) {
        // Jika semua URL gagal, coba buka WhatsApp tanpa parameter
        await _openWhatsAppFallback(caption, pdfPath);
      } else {
        // Jika berhasil dan ada PDF, share setelah WhatsApp terbuka
        if (pdfPath != null) {
          await Future.delayed(const Duration(seconds: 2));
          await _sharePDFSeparately(pdfPath);
        }
      }
      
    } catch (e) {
      // Fallback terakhir: copy caption dan buka share
      await _copyAndShareFallback(data, captionType, pdfPath);
    }
  }

  // Method fallback jika WhatsApp tidak bisa dibuka dengan URL
  static Future<void> _openWhatsAppFallback(String caption, String? pdfPath) async {
    try {
      // Coba buka WhatsApp dengan scheme sederhana
      List<String> fallbackUrls = [
        'whatsapp://',
        'https://wa.me/',
      ];
      
      bool opened = false;
      for (String url in fallbackUrls) {
        try {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            opened = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (opened) {
        // Copy caption ke clipboard
        await _copyToClipboard(caption);
        
        // Share PDF jika ada
        if (pdfPath != null) {
          await Future.delayed(const Duration(seconds: 1));
          await _sharePDFSeparately(pdfPath);
        }
      } else {
        throw Exception('WhatsApp tidak ditemukan di perangkat');
      }
    } catch (e) {
      throw Exception('Tidak dapat membuka WhatsApp: $e');
    }
  }

  // Method fallback copy dan share manual
  static Future<void> _copyAndShareFallback(
    OmronData data, 
    String captionType, 
    String? pdfPath
  ) async {
    try {
      final String caption = generateCaption(data, captionType);
      
      // Copy caption ke clipboard
      await _copyToClipboard(caption);
      
      // Share menggunakan sistem share
      if (pdfPath != null) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: caption,
          subject: 'Laporan Omron HBF-375 - ${data.patientName}',
        );
      } else {
        await Share.share(
          caption,
          subject: 'Laporan Omron HBF-375 - ${data.patientName}',
        );
      }
    } catch (e) {
      throw Exception('Gagal share data: $e');
    }
  }

  // Method untuk copy caption dan share PDF manual
  static Future<void> copyAndSharePDF({
    required OmronData data,
    required String captionType,
    String? pdfPath,
  }) async {
    try {
      // Generate caption
      final String caption = generateCaption(data, captionType);
      
      // Copy caption ke clipboard
      await _copyToClipboard(caption);
      
      // Share PDF dan caption
      if (pdfPath != null) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: caption,
          subject: 'Laporan Omron HBF-375 - ${data.patientName}',
        );
      } else {
        await Share.share(
          caption,
          subject: 'Laporan Omron HBF-375 - ${data.patientName}',
        );
      }
    } catch (e) {
      throw Exception('Gagal copy caption: $e');
    }
  }

  // Method untuk share hanya caption (tanpa PDF)
  static Future<void> shareCaption({
    required OmronData data,
    required String captionType,
  }) async {
    try {
      final String caption = generateCaption(data, captionType);
      
      await Share.share(
        caption,
        subject: 'Laporan Omron HBF-375 - ${data.patientName}',
      );
    } catch (e) {
      throw Exception('Gagal share caption: $e');
    }
  }

  // Helper method untuk share PDF secara terpisah
  static Future<void> _sharePDFSeparately(String pdfPath) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: 'Laporan Omron HBF-375 PDF',
      );
    } catch (e) {
      // Fallback jika share gagal
      print('Gagal share PDF: $e');
    }
  }

  // Helper method untuk copy ke clipboard
  static Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      // Fallback menggunakan share jika clipboard gagal
      await Share.share(text);
    }
  }

  // Generate caption berdasarkan tipe
  static String generateCaption(OmronData data, String captionType) {
    switch (captionType) {
      case 'doctor':
        return _generateDoctorCaption(data);
      case 'family':
        return _generateFamilyCaption(data);
      case 'trainer':
        return _generateTrainerCaption(data);
      default:
        return _generateBasicCaption(data);
    }
  }

  // PRIVATE METHODS UNTUK GENERATE CAPTION
  static String _generateBasicCaption(OmronData data) {
    final String date = DateFormat('dd/MM/yyyy HH:mm').format(data.timestamp);
    
    return '''
🏥 *LAPORAN OMRON HBF-375*

👤 *Pasien:* ${data.patientName}
📅 *Tanggal:* $date
⚖️ *Usia:* ${data.age} tahun | ${data.gender == 'Male' ? '👨' : '👩'} ${data.gender == 'Male' ? 'Pria' : 'Wanita'}

📊 *RINGKASAN BASIC:*
• Berat: ${data.weight.toStringAsFixed(1)} kg
• BMI: ${data.bmi.toStringAsFixed(1)} (${data.bmiCategory})
• Body Fat: ${data.bodyFatPercentage.toStringAsFixed(1)}% (${data.bodyFatCategory})
• Muscle: ${data.skeletalMusclePercentage.toStringAsFixed(1)}%
• Visceral Fat: ${data.visceralFatLevel} (${_getVisceralFatStatus(data.visceralFatLevel.toInt())})
• Body Age: ${data.bodyAge} tahun

🎯 *PENILAIAN KESELURUHAN:*
${_getAssessmentEmoji(data.overallAssessment)} *${data.overallAssessment.toUpperCase()}*

📈 *SAME AGE COMPARISON:*
${data.sameAgeComparison.toStringAsFixed(0)}th percentile (${data.sameAgeCategory})

${_generateQuickRecommendation(data)}

📋 *Detail lengkap tersedia di PDF*
Generated by LSHC Omron App 📱
    ''';
  }

  static String _generateFamilyCaption(OmronData data) {
    return '''
👨‍👩‍👧‍👦 *Update Kesehatan*

Halo! Share hasil check-up Omron nih:

👤 *${data.patientName}*
📅 ${DateFormat('dd/MM/yyyy').format(data.timestamp)}

📊 *Hasil Singkat:*
• Berat: ${data.weight.toStringAsFixed(1)} kg
• BMI: ${data.bmi.toStringAsFixed(1)} (${data.bmiCategory})
• Body Fat: ${data.bodyFatPercentage.toStringAsFixed(1)}%
• Overall: ${_getAssessmentEmoji(data.overallAssessment)} ${data.overallAssessment}

${_generateQuickRecommendation(data)}

📋 Detail lengkap ada di PDF ya!
Generated by LSHC Omron App 📱
    ''';
  }

  static String _generateDoctorCaption(OmronData data) {
    return '''
📋 *LAPORAN MEDIS - OMRON HBF-375*

*Pasien:* ${data.patientName}
*Tanggal Pemeriksaan:* ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(data.timestamp)}
*Usia:* ${data.age} tahun | *Gender:* ${data.gender}

*PARAMETER UTAMA:*
• BMI: ${data.bmi.toStringAsFixed(1)} kg/m² (${data.bmiCategory})
• Body Fat: ${data.bodyFatPercentage.toStringAsFixed(1)}% (${data.bodyFatCategory})
• Skeletal Muscle: ${data.skeletalMusclePercentage.toStringAsFixed(1)}%
• Visceral Fat Level: ${data.visceralFatLevel}
• Resting Metabolism: ${data.restingMetabolism} kcal
• Body Age: ${data.bodyAge} years

*ANALISIS LANJUTAN:*
• Subcutaneous Fat: ${data.subcutaneousFatPercentage.toStringAsFixed(1)}%
• Same Age Percentile: ${data.sameAgeComparison.toStringAsFixed(0)}th

*Assessment:* ${data.overallAssessment}

Mohon review untuk konsultasi lebih lanjut.
Terima kasih.

Generated by LSHC Omron App
    ''';
  }

  static String _generateTrainerCaption(OmronData data) {
    return '''
🏋️‍♂️ *BODY COMPOSITION REPORT*

*Client:* ${data.patientName}
*Date:* ${DateFormat('dd/MM/yyyy').format(data.timestamp)}

*KEY METRICS:*
• Weight: ${data.weight.toStringAsFixed(1)} kg
• BMI: ${data.bmi.toStringAsFixed(1)} (${data.bmiCategory})
• Body Fat: ${data.bodyFatPercentage.toStringAsFixed(1)}% (${data.bodyFatCategory})
• Skeletal Muscle: ${data.skeletalMusclePercentage.toStringAsFixed(1)}%
• Visceral Fat: ${data.visceralFatLevel}
• Body Age: ${data.bodyAge} years

*SEGMENTAL DATA:*
• Trunk Fat: ${data.segmentalSubcutaneousFat['trunk']!.toStringAsFixed(1)}%
• Arms Avg: ${((data.segmentalSubcutaneousFat['rightArm']! + data.segmentalSubcutaneousFat['leftArm']!) / 2).toStringAsFixed(1)}%
• Legs Avg: ${((data.segmentalSubcutaneousFat['rightLeg']! + data.segmentalSubcutaneousFat['leftLeg']!) / 2).toStringAsFixed(1)}%

*Overall Assessment:* ${data.overallAssessment}

Ready to discuss the training program! 💪
Full report in PDF attached.

Generated by LSHC Omron App
    ''';
  }

  // HELPER METHODS
  static String _getVisceralFatStatus(int level) {
    if (level <= 9) return 'Normal';
    if (level <= 14) return 'Tinggi';
    return 'Sangat Tinggi';
  }

  static String _getAssessmentEmoji(String assessment) {
    switch (assessment) {
      case 'Excellent': return '🌟';
      case 'Good': return '👍';
      case 'Fair': return '⚠️';
      default: return '🚨';
    }
  }

  static String _generateQuickRecommendation(OmronData data) {
    if (data.overallAssessment == 'Excellent') {
      return '✅ *Rekomendasi:* Pertahankan pola hidup sehat saat ini!';
    } else if (data.overallAssessment == 'Good') {
      return '💪 *Rekomendasi:* Tingkatkan sedikit aktivitas fisik untuk hasil optimal.';
    } else if (data.overallAssessment == 'Fair') {
      return '🏃‍♂️ *Rekomendasi:* Fokus pada diet seimbang dan olahraga rutin.';
    } else {
      return '🏥 *Rekomendasi:* Konsultasi dengan ahli gizi untuk program khusus.';
    }
  }

  // METHOD TAMBAHAN UNTUK VALIDASI NOMOR TELEPON
  static bool isValidPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleanNumber.length >= 10 && cleanNumber.length <= 15;
  }

  // METHOD UNTUK FORMAT NOMOR TELEPON
  static String formatPhoneNumber(String phoneNumber) {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    String formattedNumber = cleanNumber;
    
    // Tambahkan country code jika belum ada
    if (!formattedNumber.startsWith('62')) {
      if (formattedNumber.startsWith('0')) {
        formattedNumber = '62${formattedNumber.substring(1)}';
      } else {
        formattedNumber = '62$formattedNumber';
      }
    }
    
    return formattedNumber;
  }

  // METHOD UNTUK CEK APAKAH WHATSAPP TERINSTALL - DIPERBAIKI
  static Future<bool> isWhatsAppInstalled() async {
    try {
      // Cek beberapa URL scheme WhatsApp
      List<String> whatsappUrls = [
        'whatsapp://',
        'https://wa.me/',
        'whatsapp://send',
      ];
      
      for (String url in whatsappUrls) {
        try {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            return true;
          }
        } catch (e) {
          continue;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // METHOD UNTUK BUKA WHATSAPP TANPA NOMOR (UNTUK SHARE MANUAL)
  static Future<void> openWhatsAppForManualShare(String caption) async {
    try {
      final String encodedCaption = Uri.encodeComponent(caption);
      
      List<String> whatsappUrls = [
        'whatsapp://send?text=$encodedCaption',
        'https://wa.me/?text=$encodedCaption',
        'whatsapp://',
      ];
      
      bool success = false;
      for (String url in whatsappUrls) {
        try {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            success = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (!success) {
        // Copy caption dan buka share biasa
        await _copyToClipboard(caption);
        await Share.share(caption);
      }
    } catch (e) {
      throw Exception('Gagal membuka WhatsApp: $e');
    }
  }

  // METHOD UNTUK SHARE DENGAN MULTIPLE OPTIONS
  static Future<void> shareWithOptions({
    required OmronData data,
    required String captionType,
    String? pdfPath,
    String? phoneNumber,
  }) async {
    try {
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Coba kirim ke nomor spesifik
        await sendToWhatsAppWithNumber(
          phoneNumber: phoneNumber,
          data: data,
          captionType: captionType,
          pdfPath: pdfPath,
        );
      } else {
        // Share manual
        await copyAndSharePDF(
          data: data,
          captionType: captionType,
          pdfPath: pdfPath,
        );
      }
    } catch (e) {
      // Fallback terakhir
      await _copyAndShareFallback(data, captionType, pdfPath);
    }
  }
}
