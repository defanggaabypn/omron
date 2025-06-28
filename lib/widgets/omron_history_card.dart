import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';

class OmronHistoryCard extends StatelessWidget {
  final OmronData data;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onWhatsApp; // CALLBACK BARU untuk kirim WhatsApp

  const OmronHistoryCard({
    Key? key,
    required this.data,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onWhatsApp, // PARAMETER BARU
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // TAMBAHKAN BORDER HIJAU JIKA SUDAH DIKIRIM WHATSAPP
        side: data.isWhatsAppSent 
          ? BorderSide(color: Colors.green[300]!, width: 1.5)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER dengan nama pasien dan status WhatsApp
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // INDIKATOR STATUS WHATSAPP
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: data.isWhatsAppSent 
                              ? Colors.green[600] 
                              : data.whatsappNumber != null && data.whatsappNumber!.isNotEmpty
                                ? Colors.orange[600]
                                : Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.patientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // BADGE STATUS WHATSAPP
                  if (data.isWhatsAppSent) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Terkirim',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (data.whatsappNumber != null && data.whatsappNumber!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // MENU ACTIONS
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            const Text('Lihat Detail'),
                          ],
                        ),
                      ),
                      if (data.whatsappNumber != null && data.whatsappNumber!.isNotEmpty) ...[
                        PopupMenuItem(
                          value: 'whatsapp',
                          child: Row(
                            children: [
                              Icon(
                                data.isWhatsAppSent ? Icons.repeat : Icons.send,
                                color: data.isWhatsAppSent ? Colors.orange[600] : Colors.green[600], 
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(data.isWhatsAppSent ? 'Kirim Ulang WA' : 'Kirim ke WA'),
                            ],
                          ),
                        ),
                      ],
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue[600], size: 20), 
                            const SizedBox(width: 8),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red[600], size: 20),
                            const SizedBox(width: 8),
                            const Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // TIMESTAMP DAN WHATSAPP INFO
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(data.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (data.whatsappNumber != null && data.whatsappNumber!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatPhoneNumber(data.whatsappNumber!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              
              // WHATSAPP SENT TIME (jika sudah dikirim)
              if (data.isWhatsAppSent && data.whatsappSentAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.send,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dikirim: ${_formatSentTime(data.whatsappSentAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // BASIC METRICS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'Berat',
                            '${data.weight.toStringAsFixed(1)} kg',
                            Icons.scale,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'BMI',
                            data.bmi.toStringAsFixed(1),
                            Icons.straighten,
                            _getBMIColor(data.bmi),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'Body Fat',
                            '${data.bodyFatPercentage.toStringAsFixed(1)}%',
                            Icons.fitness_center,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'Muscle',
                            '${data.skeletalMusclePercentage.toStringAsFixed(1)}%',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // ASSESSMENT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getAssessmentColor(data.overallAssessment).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getAssessmentColor(data.overallAssessment).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getAssessmentIcon(data.overallAssessment),
                      size: 16,
                      color: _getAssessmentColor(data.overallAssessment),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Penilaian: ${data.overallAssessment}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getAssessmentColor(data.overallAssessment),
                      ),
                    ),
                  ],
                ),
              ),
              
              // QUICK ACTION BUTTONS (jika ada WhatsApp)
              if (data.whatsappNumber != null && 
                  data.whatsappNumber!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Detail'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onWhatsApp,
                        icon: Icon(
                          data.isWhatsAppSent ? Icons.repeat : Icons.send, 
                          size: 16,
                        ),
                        label: Text(
                          data.isWhatsAppSent ? 'Kirim Ulang' : 'Kirim WA',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: data.isWhatsAppSent 
                            ? Colors.orange[600] 
                            : Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // METHOD HELPER
  String _formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.startsWith('62')) {
      cleanNumber = '0${cleanNumber.substring(2)}';
    }
    // Format dengan pemisah untuk kemudahan baca
    if (cleanNumber.length >= 10) {
      return '${cleanNumber.substring(0, 4)}-${cleanNumber.substring(4, 8)}-${cleanNumber.substring(8)}';
    }
    return cleanNumber;
  }

  String _formatSentTime(DateTime sentTime) {
    final now = DateTime.now();
    final difference = now.difference(sentTime);
    
    if (difference.inMinutes < 1) {
      return 'baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else {
      return '${difference.inDays}h lalu';
    }
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

Color _getAssessmentColor(String assessment) {
  switch (assessment) {
    case 'Excellent': return Colors.green;
    case 'Good': return Colors.blue;
    case 'Fair': return Colors.orange;
    default: return Colors.red; // Poor or Unknown
  }
}

IconData _getAssessmentIcon(String assessment) {
  switch (assessment) {
    case 'Excellent': return Icons.star;
    case 'Good': return Icons.thumb_up;
    case 'Fair': return Icons.warning;
    default: return Icons.priority_high; // Poor or Unknown
  }
}


  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'detail':
        onTap?.call();
        break;
      case 'whatsapp':
        onWhatsApp?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}