import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert'; // Tambahkan import ini untuk JsonEncoder
import '../models/omron_data.dart';
import '../services/database_service.dart';
import '../widgets/omron_history_card.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/omron_result_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<OmronData> _allData = [];
  List<OmronData> _filteredData = [];
  List<String> _patientNames = [];
  List<Map<String, dynamic>> _patients = [];
  
  String? _selectedPatient;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  bool _isExporting = false;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _databaseService.getAllOmronData();
      final patients = await _databaseService.getPatientNames();
      // Commented out karena mungkin method ini belum ada
      // final patientsData = await _databaseService.getAllPatients();
      
      setState(() {
        _allData = data;
        _filteredData = data;
        _patientNames = patients;
        // _patients = patientsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat data: $e');
    }
  }

  void _filterData() {
    List<OmronData> filtered = _allData;

    // Filter by patient name
    if (_selectedPatient != null && _selectedPatient!.isNotEmpty) {
      filtered = filtered.where((data) => 
        data.patientName == _selectedPatient).toList();
    }

    // Filter by date range
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((data) => 
        data.timestamp.isAfter(_startDate!) && 
        data.timestamp.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }

    // Filter by search text
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((data) => 
        data.patientName.toLowerCase().contains(searchText) ||
        (data.whatsappNumber?.toLowerCase().contains(searchText) ?? false)).toList();
    }

    setState(() {
      _filteredData = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Data'),
          Text(
            '${_filteredData.length} dari ${_allData.length} record',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.orange[700],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filter Data',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export_csv',
              child: Row(
                children: [
                  Icon(Icons.file_download, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Export CSV'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export_filtered',
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Export Filter'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'patients',
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Kelola Pasien'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'analytics',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Lihat Analisis'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'whatsapp_status',
              child: Row(
                children: [
                  Icon(Icons.message, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Status WhatsApp'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Backup Data'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_filteredData.isNotEmpty) ...[
          FloatingActionButton.small(
            onPressed: _showBulkActionsDialog,
            backgroundColor: Colors.blue[700],
            heroTag: "bulk",
            tooltip: 'Aksi Massal',
            child: const Icon(Icons.checklist, color: Colors.white),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: () => Navigator.pop(context),
          backgroundColor: Colors.orange[700],
          heroTag: "add",
          tooltip: 'Input Data Baru',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange[700]),
            const SizedBox(height: 16),
            const Text('Memuat data...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchAndStats(),
        if (_isExporting) _buildExportProgress(),
        Expanded(
          child: _filteredData.isEmpty 
            ? _buildEmptyState() 
            : _buildDataList(),
        ),
      ],
    );
  }

  Widget _buildExportProgress() {
    return Container(
      color: Colors.orange[50],
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(width: 12),
          const Text('Mengekspor data...'),
        ],
      ),
    );
  }

  Widget _buildSearchAndStats() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama pasien atau nomor WhatsApp...',
              prefixIcon: Icon(Icons.search, color: Colors.orange[700]),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Active Filters Display
          if (_selectedPatient != null || _startDate != null || _endDate != null)
            _buildActiveFilters(),
          
          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedPatient != null)
            Chip(
              label: Text('Pasien: $_selectedPatient'),
              onDeleted: () {
                setState(() {
                  _selectedPatient = null;
                });
                _filterData();
              },
              backgroundColor: Colors.blue[100],
            ),
          if (_startDate != null && _endDate != null)
            Chip(
              label: Text(
                'Tanggal: ${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
              ),
              onDeleted: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _filterData();
              },
              backgroundColor: Colors.green[100],
            ),
          if (_selectedPatient != null || _startDate != null || _endDate != null)
            ActionChip(
              label: const Text('Hapus Semua'),
              onPressed: _clearFilters,
              backgroundColor: Colors.red[100],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_filteredData.isEmpty) return const SizedBox.shrink();

    final totalPatients = _filteredData.map((e) => e.patientName).toSet().length;
    final avgWeight = _filteredData.map((e) => e.weight).reduce((a, b) => a + b) / _filteredData.length;
    final avgBMI = _filteredData.map((e) => e.bmi).reduce((a, b) => a + b) / _filteredData.length;
    final whatsappSent = _filteredData.where((e) => e.isWhatsAppSent).length;
    final whatsappPending = _filteredData.where((e) => !e.isWhatsAppSent && e.whatsappNumber != null).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout berdasarkan lebar layar
        if (constraints.maxWidth < 600) {
          // Layout untuk mobile (2x3 grid)
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Record',
                      _filteredData.length.toString(),
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Pasien',
                      totalPatients.toString(),
                      Icons.people,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Rata² Berat',
                      '${avgWeight.toStringAsFixed(1)} kg',
                      Icons.scale,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Rata² BMI',
                      avgBMI.toStringAsFixed(1),
                      Icons.straighten,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'WA Terkirim',
                      whatsappSent.toString(),
                      Icons.check_circle,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'WA Pending',
                      whatsappPending.toString(),
                      Icons.pending,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Layout untuk tablet/desktop (1 row)
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatCard(
                'Total Record',
                _filteredData.length.toString(),
                Icons.assignment,
                Colors.blue,
              ),
              _buildStatCard(
                'Pasien',
                totalPatients.toString(),
                Icons.people,
                Colors.green,
              ),
              _buildStatCard(
                'Rata² Berat',
                '${avgWeight.toStringAsFixed(1)} kg',
                Icons.scale,
                Colors.orange,
              ),
              _buildStatCard(
                'Rata² BMI',
                avgBMI.toStringAsFixed(1),
                Icons.straighten,
                Colors.purple,
              ),
              _buildStatCard(
                'WA Terkirim',
                whatsappSent.toString(),
                Icons.check_circle,
                Colors.teal,
              ),
              _buildStatCard(
                'WA Pending',
                whatsappPending.toString(),
                Icons.pending,
                Colors.amber,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _allData.isEmpty 
              ? 'Belum ada data yang tersimpan.\nMulai dengan input data pertama.'
              : 'Tidak ada data yang sesuai dengan filter.\nCoba ubah kriteria pencarian.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _allData.isEmpty 
              ? () => Navigator.pop(context)
              : _clearFilters,
            icon: Icon(_allData.isEmpty ? Icons.add : Icons.clear_all),
            label: Text(_allData.isEmpty ? 'Input Data' : 'Hapus Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.orange[700],
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid untuk list data
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 2;
          }

          if (crossAxisCount == 1) {
            // ListView untuk mobile
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                final data = _filteredData[index];
                return OmronHistoryCard(
                  data: data,
                  onTap: () => _showDetailDialog(data),
                  onEdit: () => _editData(data),
                  onDelete: () => _deleteData(data),
                  // Removed showWhatsAppStatus parameter
                );
              },
            );
          } else {
            // GridView untuk tablet/desktop
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                final data = _filteredData[index];
                return OmronHistoryCard(
                  data: data,
                  onTap: () => _showDetailDialog(data),
                  onEdit: () => _editData(data),
                  onDelete: () => _deleteData(data),
                  // Removed showWhatsAppStatus parameter
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        patientNames: _patientNames,
        selectedPatient: _selectedPatient,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (patient, start, end) {
          setState(() {
            _selectedPatient = patient;
            _startDate = start;
            _endDate = end;
          });
          _filterData();
        },
        onClear: _clearFilters,
      ),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aksi Massal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Kirim WhatsApp Massal'),
              subtitle: Text('${_filteredData.where((e) => !e.isWhatsAppSent && e.whatsappNumber != null).length} data pending'),
              onTap: () {
                Navigator.pop(context);
                _sendBulkWhatsApp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Data Terpilih'),
              subtitle: Text('${_filteredData.length} data'),
              onTap: () {
                Navigator.pop(context);
                _exportFilteredData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Hapus Data Terpilih'),
              subtitle: Text('${_filteredData.length} data'),
              onTap: () {
                Navigator.pop(context);
                _showBulkDeleteDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Massal'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${_filteredData.length} data yang sedang ditampilkan?\n\nTindakan ini tidak dapat dibatalkan!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    try {
      for (final data in _filteredData) {
        await _databaseService.deleteOmronData(data.id!);
      }
      await _loadData();
      _showSuccessSnackBar('${_filteredData.length} data berhasil dihapus');
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus data: $e');
    }
  }

  Future<void> _sendBulkWhatsApp() async {
    final pendingData = _filteredData.where((e) => 
      !e.isWhatsAppSent && e.whatsappNumber != null).toList();
    
    if (pendingData.isEmpty) {
      _showErrorSnackBar('Tidak ada data WhatsApp yang perlu dikirim');
      return;
    }

    // Implement bulk WhatsApp sending logic here
    _showSuccessSnackBar('Fitur kirim WhatsApp massal akan segera tersedia');
  }

  void _clearFilters() {
    setState(() {
      _selectedPatient = null;
      _startDate = null;
      _endDate = null;
    });
    _searchController.clear();
    _filterData();
  }

  void _showDetailDialog(OmronData data) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive dialog sizing
            double dialogWidth;
            double dialogHeight;
            
            if (constraints.maxWidth > 1200) {
              // Desktop
              dialogWidth = constraints.maxWidth * 0.6;
              dialogHeight = constraints.maxHeight * 0.8;
            } else if (constraints.maxWidth > 800) {
              // Tablet
              dialogWidth = constraints.maxWidth * 0.8;
              dialogHeight = constraints.maxHeight * 0.85;
            } else {
              // Mobile
              dialogWidth = constraints.maxWidth * 0.95;
              dialogHeight = constraints.maxHeight * 0.9;
            }

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: (constraints.maxWidth - dialogWidth) / 2,
                vertical: (constraints.maxHeight - dialogHeight) / 2,
              ),
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[700],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detail Analisis - ${data.patientName}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMMM yyyy, HH:mm').format(data.timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: OmronResultCard(data: data),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editData(OmronData data) async {
    // Navigate to edit screen dengan data
    final result = await Navigator.pushNamed(
      context, 
      '/edit', 
      arguments: data,
    );
    
    // Jika edit berhasil, refresh data
    if (result == true) {
      await _loadData();
      _showSuccessSnackBar('Data berhasil diperbarui dan dimuat ulang');
    }
  }

  void _deleteData(OmronData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data ${data.patientName} pada ${DateFormat('dd/MM/yyyy HH:mm').format(data.timestamp)}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(OmronData data) async {
    try {
      await _databaseService.deleteOmronData(data.id!);
      await _loadData();
      _showSuccessSnackBar('Data berhasil dihapus');
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus data: $e');
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'export_csv':
        _exportAllData();
        break;
      case 'export_filtered':
        _exportFilteredData();
        break;
      case 'patients':
        _showPatientsDialog();
        break;
      case 'analytics':
        Navigator.pushNamed(context, '/analytics');
        break;
      case 'whatsapp_status':
        _showWhatsAppStatusDialog();
        break;
      case 'backup':
        _backupData();
        break;
      case 'refresh':
        _loadData();
        break;
    }
  }

  Future<void> _exportAllData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Simple CSV export implementation
      StringBuffer csv = StringBuffer();
      
      // CSV Header
      csv.writeln('ID,Timestamp,Patient Name,WhatsApp Number,Age,Gender,Height,Weight,Body Fat %,BMI,'
          'Skeletal Muscle %,Visceral Fat Level,Resting Metabolism,Body Age,'
          'Subcutaneous Fat %,WhatsApp Sent');
      
      // CSV Data
      for (OmronData item in _allData) {
        csv.writeln('${item.id},${item.timestamp.toIso8601String()},'
            '"${item.patientName}","${item.whatsappNumber ?? ''}",'
            '${item.age},"${item.gender}",${item.height},'
            '${item.weight},${item.bodyFatPercentage},${item.bmi},'
            '${item.skeletalMusclePercentage},${item.visceralFatLevel},'
                        '${item.restingMetabolism},${item.bodyAge},${item.subcutaneousFatPercentage},'
            '"${item.isWhatsAppSent ? 'Yes' : 'No'}"');
      }

      await _saveAndShareCSV(csv.toString(), 'omron_data_all');
      _showSuccessSnackBar('Data berhasil diekspor');
    } catch (e) {
      _showErrorSnackBar('Gagal mengekspor data: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportFilteredData() async {
    if (_filteredData.isEmpty) {
      _showErrorSnackBar('Tidak ada data untuk diekspor');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Create CSV manually for filtered data
      StringBuffer csv = StringBuffer();
      
      // CSV Header
      csv.writeln('ID,Timestamp,Patient Name,WhatsApp Number,Age,Gender,Height,Weight,Body Fat %,BMI,'
          'Skeletal Muscle %,Visceral Fat Level,Resting Metabolism,Body Age,'
          'Subcutaneous Fat %,WhatsApp Sent');
      
      // CSV Data
      for (OmronData item in _filteredData) {
        csv.writeln('${item.id},${item.timestamp.toIso8601String()},'
            '"${item.patientName}","${item.whatsappNumber ?? ''}",'
            '${item.age},"${item.gender}",${item.height},'
            '${item.weight},${item.bodyFatPercentage},${item.bmi},'
            '${item.skeletalMusclePercentage},${item.visceralFatLevel},'
            '${item.restingMetabolism},${item.bodyAge},${item.subcutaneousFatPercentage},'
            '"${item.isWhatsAppSent ? 'Yes' : 'No'}"');
      }

      String filename = 'omron_data_filtered';
      if (_selectedPatient != null) {
        filename += '_${_selectedPatient!.replaceAll(' ', '_')}';
      }
      if (_startDate != null && _endDate != null) {
        filename += '_${DateFormat('yyyyMMdd').format(_startDate!)}_${DateFormat('yyyyMMdd').format(_endDate!)}';
      }

      await _saveAndShareCSV(csv.toString(), filename);
      _showSuccessSnackBar('Data filter berhasil diekspor (${_filteredData.length} record)');
    } catch (e) {
      _showErrorSnackBar('Gagal mengekspor data filter: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _saveAndShareCSV(String csvData, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Data Omron HBF-375 - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        subject: 'Export Data Omron',
      );
    } catch (e) {
      throw Exception('Gagal menyimpan atau membagikan file: $e');
    }
  }

  void _showPatientsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kelola Pasien',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _patients.isEmpty
                  ? const Center(
                      child: Text('Belum ada data pasien'),
                    )
                  : ListView.builder(
                      itemCount: _patients.length,
                      itemBuilder: (context, index) {
                        final patient = _patients[index];
                        final dataCount = _allData.where((d) => 
                          d.patientName == patient['nama']).length;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange[100],
                            child: Text(
                              patient['nama'][0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(patient['nama']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${patient['gender']}, ${patient['usia']} tahun'),
                              Text('WhatsApp: ${patient['whatsapp']}'),
                              Text('$dataCount pengukuran'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handlePatientAction(value, patient),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view_data',
                                child: Text('Lihat Data'),
                              ),
                              const PopupMenuItem(
                                value: 'export_patient',
                                child: Text('Export Data'),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePatientAction(String action, Map<String, dynamic> patient) {
    switch (action) {
      case 'view_data':
        Navigator.pop(context); // Close dialog
        setState(() {
          _selectedPatient = patient['nama'];
        });
        _filterData();
        break;
      case 'export_patient':
        Navigator.pop(context); // Close dialog
        _exportPatientData(patient['nama']);
        break;
    }
  }

  Future<void> _exportPatientData(String patientName) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final patientData = _allData.where((data) => data.patientName == patientName).toList();
      
      if (patientData.isEmpty) {
        _showErrorSnackBar('Tidak ada data untuk pasien $patientName');
        return;
      }

      StringBuffer csv = StringBuffer();
      
      // CSV Header
      csv.writeln('ID,Timestamp,Patient Name,WhatsApp Number,Age,Gender,Height,Weight,Body Fat %,BMI,'
          'Skeletal Muscle %,Visceral Fat Level,Resting Metabolism,Body Age,'
          'Subcutaneous Fat %,WhatsApp Sent');
      
      // CSV Data
      for (OmronData item in patientData) {
        csv.writeln('${item.id},${item.timestamp.toIso8601String()},'
            '"${item.patientName}","${item.whatsappNumber ?? ''}",'
            '${item.age},"${item.gender}",${item.height},'
            '${item.weight},${item.bodyFatPercentage},${item.bmi},'
            '${item.skeletalMusclePercentage},${item.visceralFatLevel},'
            '${item.restingMetabolism},${item.bodyAge},${item.subcutaneousFatPercentage},'
            '"${item.isWhatsAppSent ? 'Yes' : 'No'}"');
      }

      await _saveAndShareCSV(csv.toString(), 'omron_data_${patientName.replaceAll(' ', '_')}');
      _showSuccessSnackBar('Data $patientName berhasil diekspor (${patientData.length} record)');
    } catch (e) {
      _showErrorSnackBar('Gagal mengekspor data $patientName: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showWhatsAppStatusDialog() {
    // Hitung statistik WhatsApp dari data yang ada
    final totalRecords = _allData.length;
    final withWhatsApp = _allData.where((data) => data.whatsappNumber != null && data.whatsappNumber!.isNotEmpty).length;
    final sentWhatsApp = _allData.where((data) => data.isWhatsAppSent).length;
    final pendingWhatsApp = _allData.where((data) => !data.isWhatsAppSent && data.whatsappNumber != null && data.whatsappNumber!.isNotEmpty).length;

    final stats = {
      'totalRecords': totalRecords,
      'withWhatsApp': withWhatsApp,
      'sentWhatsApp': sentWhatsApp,
      'pendingWhatsApp': pendingWhatsApp,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.message, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Status WhatsApp'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Total Record', stats['totalRecords']!, Icons.assignment, Colors.blue),
            _buildStatusRow('Dengan WhatsApp', stats['withWhatsApp']!, Icons.phone, Colors.green),
            _buildStatusRow('Sudah Terkirim', stats['sentWhatsApp']!, Icons.check_circle, Colors.teal),
            _buildStatusRow('Belum Terkirim', stats['pendingWhatsApp']!, Icons.pending, Colors.orange),
            const SizedBox(height: 16),
            if (stats['pendingWhatsApp']! > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendBulkWhatsApp();
                  },
                  icon: const Icon(Icons.send),
                  label: Text('Kirim ${stats['pendingWhatsApp']} Pesan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Create comprehensive backup JSON
      final completeBackup = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'omron_data': _allData.map((data) => {
          'id': data.id,
          'timestamp': data.timestamp.toIso8601String(),
          'patientName': data.patientName,
          'whatsappNumber': data.whatsappNumber,
          'age': data.age,
          'gender': data.gender,
          'height': data.height,
          'weight': data.weight,
          'bodyFatPercentage': data.bodyFatPercentage,
          'bmi': data.bmi,
          'skeletalMusclePercentage': data.skeletalMusclePercentage,
          'visceralFatLevel': data.visceralFatLevel,
          'restingMetabolism': data.restingMetabolism,
          'bodyAge': data.bodyAge,
          'subcutaneousFatPercentage': data.subcutaneousFatPercentage,
          'isWhatsAppSent': data.isWhatsAppSent,
          'whatsappSentAt': data.whatsappSentAt?.toIso8601String(),
        }).toList(),
        'patients': _patients,
        'statistics': {
          'totalRecords': _allData.length,
          'totalPatients': _patientNames.length,
          'whatsappSent': _allData.where((e) => e.isWhatsAppSent).length,
          'whatsappPending': _allData.where((e) => !e.isWhatsAppSent && e.whatsappNumber != null).length,
        },
      };

      // Fixed JsonEncoder usage
      final jsonString = JsonEncoder.withIndent('  ').convert(completeBackup);
      
      final directory = await getApplicationDocumentsDirectory();
      final filename = 'omron_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${directory.path}/$filename');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup Data Omron HBF-375 - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        subject: 'Backup Data Omron',
      );

      _showSuccessSnackBar('Backup berhasil dibuat (${_allData.length} record)');
    } catch (e) {
      _showErrorSnackBar('Gagal membuat backup: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

