import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/omron_data.dart';
import '../services/whatsapp_direct_service.dart';

class WhatsAppFormDialog extends StatefulWidget {
  final OmronData data;
  final String? pdfPath;

  const WhatsAppFormDialog({
    super.key,
    required this.data,
    this.pdfPath,
  });

  @override
  State<WhatsAppFormDialog> createState() => _WhatsAppFormDialogState();
}

class _WhatsAppFormDialogState extends State<WhatsAppFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCaptionType = 'basic';
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _captionTypes = {
    'basic': {
      'title': 'Umum',
      'subtitle': 'Caption standar untuk semua orang',
      'icon': Icons.message,
      'color': Colors.blue,
    },
    'family': {
      'title': 'Keluarga',
      'subtitle': 'Caption santai dengan emoji',
      'icon': Icons.family_restroom,
      'color': Colors.green,
    },
    'doctor': {
      'title': 'Dokter',
      'subtitle': 'Caption formal untuk konsultasi medis',
      'icon': Icons.local_hospital,
      'color': Colors.red,
    },
    'trainer': {
      'title': 'Trainer',
      'subtitle': 'Caption profesional untuk fitness',
      'icon': Icons.fitness_center,
      'color': Colors.orange,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
               Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.green[100],
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(
    Icons.chat, // Ganti dari Icons.whatsapp ke Icons.chat
    color: Colors.green[700],
    size: 24,
  ),
),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kirim ke WhatsApp',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          'Laporan: ${widget.data.patientName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Phone Number Input
              Text(
                'Nomor WhatsApp Tujuan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Contoh: 08123456789 atau 628123456789',
                  prefixIcon: Icon(Icons.phone, color: Colors.green[700]),
                  prefixText: '+62 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Nomor WhatsApp harus diisi';
                  }
                  if (value!.length < 10) {
                    return 'Nomor WhatsApp minimal 10 digit';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Caption Type Selection
              Text(
                'Pilih Jenis Caption',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _captionTypes.entries.map((entry) {
                    final String key = entry.key;
                    final Map<String, dynamic> info = entry.value;
                    
                    return RadioListTile<String>(
                      value: key,
                      groupValue: _selectedCaptionType,
                      onChanged: (value) {
                        setState(() {
                          _selectedCaptionType = value!;
                        });
                      },
                      activeColor: Colors.green[700],
                      title: Row(
                        children: [
                          Icon(
                            info['icon'] as IconData,
                            color: info['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            info['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        info['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Preview Caption Button
              OutlinedButton.icon(
                onPressed: _previewCaption,
                icon: const Icon(Icons.preview, size: 18),
                label: const Text('Preview Caption'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _copyCaption,
                      child: const Text('Copy Caption'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendToWhatsApp,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18),
                      label: Text(_isLoading ? 'Mengirim...' : 'Kirim'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Info text
              Text(
                'Caption akan dikirim ke WhatsApp, PDF dapat dibagikan secara terpisah',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

void _previewCaption() {
  final String caption = WhatsAppDirectService.generateCaption( // Hilangkan underscore
    widget.data,
    _selectedCaptionType,
  );
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Preview Caption - ${_captionTypes[_selectedCaptionType]!['title']}'),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: SelectableText(
            caption,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

  Future<void> _copyCaption() async {
    try {
      await WhatsAppDirectService.copyAndSharePDF(
        data: widget.data,
        captionType: _selectedCaptionType,
        pdfPath: widget.pdfPath,
      );
      
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('Caption berhasil dicopy! Paste di WhatsApp, PDF akan dibagikan secara terpisah.');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal copy caption: $e');
    }
  }

  Future<void> _sendToWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await WhatsAppDirectService.sendToWhatsAppWithNumber(
        phoneNumber: _phoneController.text,
        data: widget.data,
        captionType: _selectedCaptionType,
        pdfPath: widget.pdfPath,
      );
      
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('WhatsApp terbuka dengan caption! PDF dapat dibagikan secara terpisah.');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengirim: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}