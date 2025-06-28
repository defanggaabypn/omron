import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../models/omron_data.dart';
import '../services/pdf_service.dart';
import '../widgets/whatsapp_form_dialog.dart';

class OmronResultCard extends StatefulWidget {
  final OmronData data;

  const OmronResultCard({super.key, required this.data});

  @override
  OmronResultCardState createState() => OmronResultCardState();
}

class OmronResultCardState extends State<OmronResultCard> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight > 0 
                ? constraints.maxHeight 
                : MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // Header yang tidak di-scroll
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildHeader(),
                ),
                // Tab bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.green[700],
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.green[700],
                    tabs: const [
                      Tab(icon: Icon(Icons.assessment, size: 20), text: 'Basic'),
                      Tab(icon: Icon(Icons.layers, size: 20), text: 'Advanced'),
                      Tab(icon: Icon(Icons.accessibility_new, size: 20), text: 'Segmental'),
                      Tab(icon: Icon(Icons.person, size: 20), text: 'Body Map'),
                    ],
                  ),
                ),
                // Content yang bisa di-scroll
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBasicTab(),
                      _buildAdvancedTab(),
                      _buildSegmentalTab(),
                      _buildBodyMapTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics,
                size: 28,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Analisis Omron HBF-375',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(widget.data.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  // TAMPILKAN WHATSAPP JIKA ADA
                  if (widget.data.whatsappNumber != null && widget.data.whatsappNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.chat, size: 12, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          widget.data.whatsappNumber!,
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Text(
                    '11/11 Fitur Lengkap',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildOverallScoreBadge(),
          ],
        ),
        const SizedBox(height: 12),
        // Action buttons - UPDATED DENGAN LOGIKA WHATSAPP
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    final bool hasWhatsApp = widget.data.whatsappNumber != null && widget.data.whatsappNumber!.isNotEmpty;
    
    if (hasWhatsApp) {
      // Jika ada nomor WhatsApp: tampilkan 2 tombol
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _exportToPDF,
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('PDF', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareToWhatsApp,
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      );
    } else {
      // Jika tidak ada nomor WhatsApp: tampilkan 1 tombol PDF saja
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _exportToPDF,
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildOverallScoreBadge() {
    Color badgeColor;
    IconData badgeIcon;
    
    // FIXED: Sesuaikan dengan kategori dari model
    switch (widget.data.overallAssessment) {
      case 'Excellent': // DARI 'Sangat Baik' KE 'Excellent'
        badgeColor = Colors.green;
        badgeIcon = Icons.star;
        break;
      case 'Good': // DARI 'Baik' KE 'Good'
        badgeColor = Colors.blue;
        badgeIcon = Icons.thumb_up;
        break;
      case 'Fair': // DARI 'Cukup' KE 'Fair'
        badgeColor = Colors.orange;
        badgeIcon = Icons.warning;
        break;
      default: // 'Needs Improvement'
        badgeColor = Colors.red;
        badgeIcon = Icons.priority_high;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            widget.data.overallAssessment,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientInfo(),
          const SizedBox(height: 12),
          _buildBasicMeasurements(),
          const SizedBox(height: 12),
          _buildBasicAnalysis(),
          const SizedBox(height: 12),
          _buildBasicRecommendations(),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancedMeasurements(),
          const SizedBox(height: 12),
          // _buildSameAgeComparison(),
          // const SizedBox(height: 12),
          _buildBodyAgeAssessment(), // TAMBAHKAN INI
          const SizedBox(height: 12),
          _buildAdvancedAnalysis(),
          const SizedBox(height: 12),
          _buildAdvancedRecommendations(),
        ],
      ),
    );
  }

  Widget _buildSegmentalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSegmentalSubcutaneousFat(),
          const SizedBox(height: 16),
          _buildSegmentalSkeletalMuscle(),
          const SizedBox(height: 16),
          _buildSegmentalAnalysis(),
        ],
      ),
    );
  }

  Widget _buildBodyMapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBodyVisualization(),
          const SizedBox(height: 16),
          _buildBodyMapLegend(),
          const SizedBox(height: 16),
          _buildBodyMapAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.green[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.patientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.data.age} tahun • ${widget.data.gender == 'Male' ? 'Pria' : 'Wanita'} • ${widget.data.height.toStringAsFixed(0)} cm',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                // TAMPILKAN WHATSAPP DI PATIENT INFO JIKA ADA
                if (widget.data.whatsappNumber != null && widget.data.whatsappNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.chat, size: 14, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'WA: ${widget.data.whatsappNumber}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildBasicMeasurements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Pengukuran Dasar (7 Indikator)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementTile(
                    'Berat Badan',
                    '${widget.data.weight.toStringAsFixed(1)} kg',
                    Icons.scale,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMeasurementTile(
                    'Body Fat',
                    '${widget.data.bodyFatPercentage.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementTile(
                    'BMI',
                    widget.data.bmi.toStringAsFixed(1),
                    Icons.straighten,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMeasurementTile(
                    'Skeletal Muscle',
                    '${widget.data.skeletalMusclePercentage.toStringAsFixed(1)}%',
                    Icons.fitness_center,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementTile(
                    'Visceral Fat',
                    widget.data.visceralFatLevel.toStringAsFixed(1),
                    Icons.favorite,
                    Colors.pink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMeasurementTile(
                    'Metabolism',
                    '${widget.data.restingMetabolism} kcal',
                    Icons.local_fire_department,
                    Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMeasurementTile(
              'Body Age',
              '${widget.data.bodyAge} tahun',
              Icons.schedule,
              Colors.teal,
              isFullWidth: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedMeasurements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔬 Pengukuran Lanjutan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMeasurementTile(
                'Subcutaneous Fat',
                '${widget.data.subcutaneousFatPercentage.toStringAsFixed(1)}%',
                Icons.layers,
                Colors.cyan,
              ),
            ),
            const SizedBox(width: 8),
            // Expanded(
            //   child: _buildMeasurementTile(
            //     'Same Age Rank',
            //     '${widget.data.sameAgeComparison.toStringAsFixed(0)}th percentile',
            //     Icons.compare,
            //     Colors.indigo,
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  // Widget _buildSameAgeComparison() {
  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: Colors.indigo[200]!),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           '👥 Perbandingan Usia Sebaya',
  //           style: TextStyle(
  //             fontSize: 15,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.indigo[700],
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Posisi Anda:',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: Colors.grey[600],
  //                     ),
  //                   ),
  //                   Text(
  //                     '${widget.data.sameAgeComparison.toStringAsFixed(0)}th Percentile',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.indigo[700],
  //                     ),
  //                   ),
  //                   Text(
  //                     widget.data.sameAgeCategory,
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: _getSameAgeCategoryColor(widget.data.sameAgeCategory),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: _getSameAgeCategoryColor(widget.data.sameAgeCategory).withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Icon(
  //                 _getSameAgeCategoryIcon(widget.data.sameAgeCategory),
  //                 color: _getSameAgeCategoryColor(widget.data.sameAgeCategory),
  //                 size: 32,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           _getSameAgeDescription(widget.data.sameAgeComparison),
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: Colors.grey[600],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // TAMBAHKAN: Widget untuk Body Age Assessment
  Widget _buildBodyAgeAssessment() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎂 Penilaian Usia Tubuh',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usia Asli: ${widget.data.age} tahun',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Body Age: ${widget.data.bodyAge} tahun',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.bodyAgeAssessment,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getBodyAgeAssessmentColor(widget.data.bodyAgeAssessment),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getBodyAgeAssessmentColor(widget.data.bodyAgeAssessment).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getBodyAgeAssessmentIcon(widget.data.bodyAgeAssessment),
                  color: _getBodyAgeAssessmentColor(widget.data.bodyAgeAssessment),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            OmronData.getBodyAgeAssessmentDescription(
              widget.data.bodyAgeAssessment, 
              widget.data.bodyAge, 
              widget.data.age
            ),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ PERBAIKAN - Segmental Subcutaneous Fat dengan struktur baru dan null safety
  Widget _buildSegmentalSubcutaneousFat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          '🫁 Subcutaneous Fat per Segmen',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildSegmentalTile(
              'Whole Body (Seluruh Tubuh)',
              '${(widget.data.segmentalSubcutaneousFat['wholeBody'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.accessibility_new,
              Colors.purple,
            ),
            const SizedBox(height: 4),
            _buildSegmentalTile(
              'Trunk (Batang Tubuh)',
              '${(widget.data.segmentalSubcutaneousFat['trunk'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.airline_seat_recline_normal,
              Colors.purple,
            ),
            const SizedBox(height: 4),
            _buildSegmentalTile(
              'Arms (Kedua Lengan)',
              '${(widget.data.segmentalSubcutaneousFat['arms'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.sports_martial_arts,
              Colors.purple,
            ),
            const SizedBox(height: 4),
            _buildSegmentalTile(
              'Legs (Kedua Kaki)',
              '${(widget.data.segmentalSubcutaneousFat['legs'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.directions_walk,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  // ✅ PERBAIKAN - Segmental Skeletal Muscle dengan struktur baru dan null safety
  Widget _buildSegmentalSkeletalMuscle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💪 Skeletal Muscle per Segmen',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildSegmentalTile(
              'Whole Body (Seluruh Tubuh)',
              '${(widget.data.segmentalSkeletalMuscle['wholeBody'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.accessibility_new,
              Colors.red,
            ),
            const SizedBox(height: 4),
            _buildSegmentalTile(
              'Trunk (Batang Tubuh)',
              '${(widget.data.segmentalSkeletalMuscle['trunk'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.airline_seat_recline_normal,
              Colors.red,
            ),
            const SizedBox(height: 4),
            _buildSegmentalTile(
              'Arms (Kedua Lengan)',
              '${(widget.data.segmentalSkeletalMuscle['arms'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.sports_martial_arts,
              Colors.red,
            ),
            const SizedBox(height: 4),
            _buildSegmentalTile(
              'Legs (Kedua Kaki)',
              '${(widget.data.segmentalSkeletalMuscle['legs'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.directions_walk,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBodyVisualization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧍 Body Display Chart',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.teal[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal[200]!),
          ),
          child: CustomPaint(
            painter: BodyMapPainter(
              data: widget.data,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keterangan Warna:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Tinggi', Colors.red[700]!),
                    _buildLegendItem('Sedang', Colors.orange[700]!),
                    _buildLegendItem('Rendah', Colors.green[700]!),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Fat Level', Colors.red[200]!),
                    _buildLegendItem('Muscle Level', Colors.blue[200]!),
                    _buildLegendItem('Normal', Colors.green[200]!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTile(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentalTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔍 Analisis Dasar',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildAnalysisItem(
          'BMI Status',
          widget.data.bmiCategory,
          _getBMICategoryColor(widget.data.bmiCategory),
          _getBMIDescription(widget.data.bmiCategory),
        ),
        _buildAnalysisItem(
          'Body Fat Status',
          widget.data.bodyFatCategory,
          _getBodyFatCategoryColor(widget.data.bodyFatCategory),
          _getBodyFatDescription(widget.data.bodyFatCategory),
        ),
        _buildAnalysisItem(
          'Visceral Fat',
          _getVisceralFatCategory(widget.data.visceralFatLevel),
          _getVisceralFatColor(widget.data.visceralFatLevel),
          _getVisceralFatDescription(widget.data.visceralFatLevel),
        ),
      ],
    );
  }

  Widget _buildAdvancedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔬 Analisis Lanjutan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildAnalysisItem(
          'Subcutaneous Fat',
          _getSubcutaneousFatCategory(widget.data.subcutaneousFatPercentage),
          _getSubcutaneousFatColor(widget.data.subcutaneousFatPercentage),
          _getSubcutaneousFatDescription(widget.data.subcutaneousFatPercentage),
        ),
        _buildAnalysisItem(
          'Same Age Comparison',
          widget.data.sameAgeCategory,
          _getSameAgeCategoryColor(widget.data.sameAgeCategory),
          _getSameAgeDescription(widget.data.sameAgeComparison),
        ),
      ],
    );
  }

  Widget _buildSegmentalAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Analisis Segmental',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribusi Lemak & Otot:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getSegmentalAnalysis(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyMapAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧬 Analisis Body Map',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.teal[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interpretasi Visual:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getBodyMapAnalysis(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisItem(String title, String category, Color color, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Rekomendasi Dasar',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _getBasicRecommendations(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎯 Rekomendasi Lanjutan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _getAdvancedRecommendations(),
          ),
        ),
      ],
    );
  }

  List<Widget> _getBasicRecommendations() {
    List<Widget> recommendations = [];
    
    // BMI recommendations
    if (widget.data.bmi < 18.5) {
      recommendations.add(_buildRecommendationItem(
        '🍎 Tingkatkan asupan kalori dengan makanan bergizi',
        Colors.blue,
      ));
    } else if (widget.data.bmi >= 25.0) {
      recommendations.add(_buildRecommendationItem(
        '🏃‍♂️ Perbanyak aktivitas fisik dan kurangi kalori',
        Colors.orange,
      ));
    }
    
    // Body fat recommendations
    if (widget.data.bodyFatPercentage > 25 && widget.data.gender == 'Male') {
      recommendations.add(_buildRecommendationItem(
        '💪 Fokus pada latihan kardio dan strength training',
        Colors.red,
      ));
    } else if (widget.data.bodyFatPercentage > 32 && widget.data.gender == 'Female') {
      recommendations.add(_buildRecommendationItem(
        '💪 Fokus pada latihan kardio dan strength training',
        Colors.red,
      ));
    }
    
    // Visceral fat recommendations
    if (widget.data.visceralFatLevel > 9.0) {
      recommendations.add(_buildRecommendationItem(
        '❤️ Kurangi lemak visceral dengan diet seimbang',
        Colors.pink,
      ));
    }
    
    // General recommendations
    recommendations.add(_buildRecommendationItem(
      '📅 Lakukan pengukuran rutin setiap minggu',
      Colors.green,
    ));

    return recommendations;
  }

  // UPDATED: Advanced Recommendations dengan Body Age Assessment
  List<Widget> _getAdvancedRecommendations() {
    List<Widget> recommendations = [];
    
    // Subcutaneous fat recommendations
    if (widget.data.subcutaneousFatPercentage > 20) {
      recommendations.add(_buildRecommendationItem(
        '🧘‍♀️ Kurangi lemak subkutan dengan yoga dan cardio',
        Colors.purple,
      ));
    }
    
    // Same age comparison recommendations
    if (widget.data.sameAgeComparison < 50) {
      recommendations.add(_buildRecommendationItem(
        '🎯 Tingkatkan program fitness untuk menyamai teman sebaya',
        Colors.indigo,
      ));
    }
    
    // TAMBAHKAN: Body Age Recommendations
    if (widget.data.bodyAgeAssessment == 'Sedikit Tua' || 
        widget.data.bodyAgeAssessment == 'Lebih Tua' || 
        widget.data.bodyAgeAssessment == 'Sangat Tua') {
      recommendations.add(_buildRecommendationItem(
        '⏰ Fokus pada latihan untuk menurunkan usia tubuh',
        Colors.red,
      ));
    } else if (widget.data.bodyAgeAssessment == 'Sangat Muda' || 
               widget.data.bodyAgeAssessment == 'Lebih Muda') {
      recommendations.add(_buildRecommendationItem(
        '🏆 Pertahankan gaya hidup sehat untuk menjaga usia tubuh',
        Colors.green,
      ));
    }
    
    // Segmental recommendations dengan null safety
    final segmentalValues = widget.data.segmentalSubcutaneousFat.values;
    if (segmentalValues.isNotEmpty) {
      final maxSegFat = segmentalValues.reduce((a, b) => a > b ? a : b);
      if (maxSegFat > 15) {
        recommendations.add(_buildRecommendationItem(
          '🎯 Fokus latihan pada area dengan lemak tinggi',
          Colors.red,
        ));
      }
    }
    
    recommendations.add(_buildRecommendationItem(
      '👨‍⚕️ Konsultasikan dengan ahli gizi untuk program yang tepat',
      Colors.blue,
    ));

    return recommendations;
  }

  Widget _buildRecommendationItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getBMICategoryColor(String category) {
    switch (category) {
      case 'Normal': return Colors.green;
      case 'Overweight': return Colors.orange;
      case 'Obese': return Colors.red;
      case 'Underweight': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getBMIDescription(String category) {
    switch (category) {
      case 'Normal': return 'Berat badan ideal untuk tinggi badan Anda';
      case 'Overweight': return 'Berat badan sedikit berlebih';
      case 'Obese': return 'Berat badan berlebih, perlu perhatian khusus';
      case 'Underweight': return 'Berat badan kurang dari ideal';
      default: return '';
    }
  }

  Color _getBodyFatCategoryColor(String category) {
    switch (category) {
      case 'Athletes': return Colors.green;
      case 'Fitness': return Colors.blue;
      case 'Average': return Colors.orange;
      case 'Obese': return Colors.red;
      case 'Essential Fat': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getBodyFatDescription(String category) {
    switch (category) {
      case 'Athletes': return 'Persentase lemak tubuh sangat baik';
      case 'Fitness': return 'Persentase lemak tubuh baik untuk kebugaran';
      case 'Average': return 'Persentase lemak tubuh rata-rata';
      case 'Obese': return 'Persentase lemak tubuh terlalu tinggi';
      case 'Essential Fat': return 'Lemak tubuh minimal yang diperlukan';
      default: return '';
    }
  }

  // Visceral fat methods for double
  String _getVisceralFatCategory(double level) {
    if (level <= 9.0) return 'Normal';
    if (level <= 14.0) return 'High';
    return 'Very High';
  }

  Color _getVisceralFatColor(double level) {
    if (level <= 9.0) return Colors.green;
    if (level <= 14.0) return Colors.orange;
    return Colors.red;
  }

  String _getVisceralFatDescription(double level) {
    if (level <= 9.0) return 'Level lemak visceral dalam batas normal';
    if (level <= 14.0) return 'Level lemak visceral agak tinggi';
    return 'Level lemak visceral sangat tinggi';
  }

  String _getSubcutaneousFatCategory(double percentage) {
    if (percentage <= 10) return 'Low';
    if (percentage <= 20) return 'Normal';
    if (percentage <= 30) return 'High';
    return 'Very High';
  }

  Color _getSubcutaneousFatColor(double percentage) {
    if (percentage <= 10) return Colors.green;
    if (percentage <= 20) return Colors.blue;
    if (percentage <= 30) return Colors.orange;
    return Colors.red;
  }

  String _getSubcutaneousFatDescription(double percentage) {
    if (percentage <= 10) return 'Level lemak subkutan rendah';
    if (percentage <= 20) return 'Level lemak subkutan normal';
    if (percentage <= 30) return 'Level lemak subkutan tinggi';
    return 'Level lemak subkutan sangat tinggi';
  }

  // FIXED: Same Age Category Color mapping
  Color _getSameAgeCategoryColor(String category) {
    switch (category) {
      case 'Excellent': // DARI 'Sangat Baik' KE 'Excellent'
        return Colors.green;
      case 'Good': // DARI 'Baik' KE 'Good'
        return Colors.blue;
      case 'Average': // TETAP 'Average'
        return Colors.orange;
      case 'Below Average': // TETAP 'Below Average'
        return Colors.red;
      case 'Poor': // TETAP 'Poor'
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  // FIXED: Same Age Category Icon mapping
  // IconData _getSameAgeCategoryIcon(String category) {
  //   switch (category) {
  //     case 'Excellent': // DARI 'Sangat Baik' KE 'Excellent'
  //       return Icons.star;
  //     case 'Good': // DARI 'Baik' KE 'Good'
  //       return Icons.thumb_up;
  //     case 'Average': // TETAP 'Average'
  //       return Icons.remove;
  //     case 'Below Average': // TETAP 'Below Average'
  //       return Icons.thumb_down;
  //     case 'Poor': // TETAP 'Poor'
  //       return Icons.warning;
  //     default:
  //       return Icons.help;
  //   }
  // }

  // HELPER: Get body age assessment color (pindah dari model ke widget)
  Color _getBodyAgeAssessmentColor(String assessment) {
    switch (assessment) {
      case 'Sangat Muda': return Colors.green[800]!;
      case 'Lebih Muda': return Colors.green[700]!;
      case 'Sedikit Muda': return Colors.green[500]!;
      case 'Sesuai Usia': return Colors.blue[500]!;
      case 'Sedikit Tua': return Colors.orange[500]!;
      case 'Lebih Tua': return Colors.deepOrange[500]!;
      case 'Sangat Tua': return Colors.red[700]!;
      default: return Colors.grey[500]!;
    }
  }

  // HELPER: Body Age Assessment Icon
  IconData _getBodyAgeAssessmentIcon(String assessment) {
    switch (assessment) {
      case 'Sangat Muda':  return Icons.celebration;
      case 'Lebih Muda':   return Icons.thumb_up;
      case 'Sedikit Muda': return Icons.trending_up;
      case 'Sesuai Usia':  return Icons.balance;
      case 'Sedikit Tua':  return Icons.trending_down;
      case 'Lebih Tua':    return Icons.warning;
      case 'Sangat Tua':   return Icons.error;
      default:             return Icons.help;
    }
  }

  String _getSameAgeDescription(double percentile) {
    if (percentile >= 90) return 'Anda berada di 10% teratas untuk usia Anda';
    if (percentile >= 75) return 'Anda berada di 25% teratas untuk usia Anda';
    if (percentile >= 50) return 'Anda berada di rata-rata untuk usia Anda';
    if (percentile >= 25) return 'Anda berada di bawah rata-rata untuk usia Anda';
    return 'Anda berada di 25% terbawah untuk usia Anda';
  }

  // ✅ PERBAIKAN - Segmental analysis dengan struktur baru dan null safety
  String _getSegmentalAnalysis() {
    final trunk = widget.data.segmentalSubcutaneousFat['trunk'] ?? 0.0;
    final arms = widget.data.segmentalSubcutaneousFat['arms'] ?? 0.0;
    final legs = widget.data.segmentalSubcutaneousFat['legs'] ?? 0.0;
    
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
    
    return 'Area dengan lemak subkutan tertinggi adalah $highestArea (${highestValue.toStringAsFixed(1)}%). Fokuskan latihan pada area ini untuk hasil optimal.';
  }

  String _getBodyMapAnalysis() {
    final bodyFat = widget.data.bodyFatPercentage;
    final muscle = widget.data.skeletalMusclePercentage;
    
    if (bodyFat > 25 && muscle < 30) {
      return 'Body map menunjukkan komposisi lemak tinggi dengan massa otot rendah. Direkomendasikan kombinasi latihan kardio dan resistance training.';
    } else if (bodyFat < 15 && muscle > 40) {
      return 'Body map menunjukkan komposisi tubuh yang sangat baik dengan lemak rendah dan massa otot tinggi. Pertahankan pola latihan dan nutrisi saat ini.';
    } else {
      return 'Body map menunjukkan komposisi tubuh yang seimbang. Lanjutkan program fitness dengan peningkatan bertahap.';
    }
  }

  // METHOD BARU UNTUK WHATSAPP DENGAN NOMOR OTOMATIS
  Future<void> _shareToWhatsApp() async {
    if (widget.data.whatsappNumber == null || widget.data.whatsappNumber!.isEmpty) {
      _showErrorDialog('Nomor WhatsApp Tidak Tersedia', 
          'Data ini tidak memiliki nomor WhatsApp. Gunakan tombol Share untuk berbagi secara umum.');
      return;
    }

    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate PDF first
      final String pdfPath = await PDFService.generateOmronReport(widget.data);
      
      // Close loading dialog dengan mounted check
      if (!mounted) return;
      Navigator.of(context).pop();
      
      // Show WhatsApp form dialog dengan nomor sudah terisi
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => WhatsAppFormDialog(
          data: widget.data,
          pdfPath: pdfPath,
          prefilledNumber: widget.data.whatsappNumber, // PARAMETER BARU
        ),
      );
      
    } catch (e) {
      // Close loading dialog dengan mounted check
      if (mounted) Navigator.of(context).pop();
      
      // Show error dialog dengan mounted check
      if (mounted) _showErrorDialog('Gagal membuat PDF', e.toString());
    }
  }

  // PDF Export method - SAMA SEPERTI ASLI
  Future<void> _exportToPDF() async {
    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final String pdfPath = await PDFService.generateOmronReport(widget.data);
      
      // Close loading dialog dengan mounted check
      if (!mounted) return;
      Navigator.of(context).pop();
      
      // Show success dialog dengan mounted check
      if (!mounted) return;
      _showSuccessDialog('PDF berhasil dibuat!', 'File disimpan di: $pdfPath');
      
    } catch (e) {
      // Close loading dialog dengan mounted check
      if (mounted) Navigator.of(context).pop();
      
      // Show error dialog dengan mounted check
      if (mounted) _showErrorDialog('Gagal membuat PDF', e.toString());
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ✅ PERBAIKAN - Custom Painter untuk Body Map dengan struktur baru dan null safety
class BodyMapPainter extends CustomPainter {
  final OmronData data;

  const BodyMapPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw simplified body outline
    final center = Offset(size.width / 2, size.height / 2);
    
    // Head
    paint.color = _getBodyPartColor(data.bodyFatPercentage);
    canvas.drawCircle(Offset(center.dx, center.dy - size.height * 0.3), size.width * 0.08, paint);
    
    // Trunk - dengan null safety
    paint.color = _getBodyPartColor(data.segmentalSubcutaneousFat['trunk'] ?? 0.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - size.height * 0.1),
          width: size.width * 0.3,
          height: size.height * 0.35,
        ),
        const Radius.circular(15),
      ),
      paint,
    );
    
    // Arms (gunakan nilai arms yang sudah digabung, bagi 2 untuk per lengan) - dengan null safety
    paint.color = _getBodyPartColor((data.segmentalSubcutaneousFat['arms'] ?? 0.0) / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + size.width * 0.2, center.dy - size.height * 0.1),
          width: size.width * 0.08,
          height: size.height * 0.25,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - size.width * 0.2, center.dy - size.height * 0.1),
          width: size.width * 0.08,
          height: size.height * 0.25,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
    
    // Legs (gunakan nilai legs yang sudah digabung, bagi 2 untuk per kaki) - dengan null safety
    paint.color = _getBodyPartColor((data.segmentalSubcutaneousFat['legs'] ?? 0.0) / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + size.width * 0.08, center.dy + size.height * 0.25),
          width: size.width * 0.1,
          height: size.height * 0.3,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - size.width * 0.08, center.dy + size.height * 0.25),
          width: size.width * 0.1,
          height: size.height * 0.3,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
    
    // Add labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${data.bodyFatPercentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - size.height * 0.1 - textPainter.height / 2),
    );
  }

  Color _getBodyPartColor(double fatPercentage) {
    if (fatPercentage <= 10) return Colors.green[700]!;
    if (fatPercentage <= 20) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}