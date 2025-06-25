import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';
import '../services/database_service.dart';
import '../widgets/omron_history_card.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/omron_result_card.dart';
import '../widgets/whatsapp_form_dialog.dart'; // IMPORT BARU

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
  
  String? _selectedPatient;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _whatsappFilter; // FILTER BARU: 'all', 'sent', 'pending', 'none'
  bool _isLoading = true;
  
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
      
      setState(() {
        _allData = data;
        _filteredData = data;
        _patientNames = patients;
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

    // FILTER BARU: Filter by WhatsApp status
    if (_whatsappFilter != null) {
      switch (_whatsappFilter) {
        case 'sent':
          filtered = filtered.where((data) => data.isWhatsAppSent).toList();
          break;
        case 'pending':
          filtered = filtered.where((data) => 
            !data.isWhatsAppSent && 
            data.whatsappNumber != null && 
            data.whatsappNumber!.isNotEmpty).toList();
          break;
        case 'none':
          filtered = filtered.where((data) => 
            data.whatsappNumber == null || 
            data.whatsappNumber!.isEmpty).toList();
          break;
        case 'all':
        default:
          // No additional filtering
          break;
      }
    }

    // Filter by search text
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((data) => 
        data.patientName.toLowerCase().contains(searchText)).toList();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.orange[700],
        tooltip: 'Input Data Baru',
        child: const Icon(Icons.add),
      ),
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
              value: 'whatsapp_stats',
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  const Text('Statistik WhatsApp'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Export Data'),
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
        _buildWhatsAppFilter(), // FILTER BARU
        Expanded(
          child: _filteredData.isEmpty 
            ? _buildEmptyState() 
            : _buildDataList(),
        ),
      ],
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
              hintText: 'Cari nama pasien...',
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
          
          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  // WIDGET BARU: Filter WhatsApp Status
  Widget _buildWhatsAppFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Status WhatsApp: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 8),
            _buildFilterChip('Semua', 'all', Colors.grey),
            const SizedBox(width: 8),
            _buildFilterChip('Terkirim', 'sent', Colors.green),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending', Colors.orange),
            const SizedBox(width: 8),
            _buildFilterChip('Tanpa WA', 'none', Colors.blue),
          ],
        ),
      ),
    );
  }

Widget _buildFilterChip(String label, String value, Color color) {
  final bool isSelected = _whatsappFilter == value;
  
  return FilterChip(
    label: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : _getColorShade(color, 700),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
    selected: isSelected,
    onSelected: (bool selected) {
      setState(() {
        _whatsappFilter = selected ? value : null;
      });
      _filterData();
    },
    backgroundColor: color.withOpacity(0.1),
    selectedColor: _getColorShade(color, 600),
    checkmarkColor: Colors.white,
    side: BorderSide(color: _getColorShade(color, 300)),
  );
}

// Helper method untuk mendapatkan shade warna
Color _getColorShade(Color baseColor, int shade) {
  if (baseColor == Colors.grey) {
    return Colors.grey[shade] ?? Colors.grey;
  } else if (baseColor == Colors.green) {
    return Colors.green[shade] ?? Colors.green;
  } else if (baseColor == Colors.orange) {
    return Colors.orange[shade] ?? Colors.orange;
  } else if (baseColor == Colors.blue) {
    return Colors.blue[shade] ?? Colors.blue;
  } else {
    // Fallback untuk warna lain
    return baseColor;
  }
}

  Widget _buildQuickStats() {
    if (_filteredData.isEmpty) return const SizedBox.shrink();

    final totalPatients = _filteredData.map((e) => e.patientName).toSet().length;
    final avgWeight = _filteredData.map((e) => e.weight).reduce((a, b) => a + b) / _filteredData.length;
    final avgBMI = _filteredData.map((e) => e.bmi).reduce((a, b) => a + b) / _filteredData.length;
    
    // STATISTIK WHATSAPP BARU
    final withWhatsApp = _filteredData.where((e) => 
      e.whatsappNumber != null && e.whatsappNumber!.isNotEmpty).length;
    final sentWhatsApp = _filteredData.where((e) => e.isWhatsAppSent).length;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                      'Dengan WA',
                      withWhatsApp.toString(),
                      Icons.chat,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Terkirim WA',
                      sentWhatsApp.toString(),
                      Icons.check_circle,
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
            ],
          );
        } else {
          // Layout untuk tablet/desktop (1 row)
          return Row(
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
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Dengan WA',
                  withWhatsApp.toString(),
                  Icons.chat,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Terkirim WA',
                  sentWhatsApp.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
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
                  onWhatsApp: () => _showWhatsAppDialog(data), // CALLBACK BARU
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
                  onWhatsApp: () => _showWhatsAppDialog(data), // CALLBACK BARU
                );
              },
            );
          }
        },
      ),
    );
  }

  // METHOD BARU: Show WhatsApp Dialog
  void _showWhatsAppDialog(OmronData data) {
    showDialog(
      context: context,
      builder: (context) => WhatsAppFormDialog(
        data: data,
        prefilledNumber: data.whatsappNumber,
        onWhatsAppSent: () {
          // REFRESH DATA SETELAH KIRIM WHATSAPP
          _loadData();
        },
      ),
    );
  }

  // METHOD BARU: Show WhatsApp Statistics
  void _showWhatsAppStatistics() async {
    try {
      final stats = await _databaseService.getWhatsAppStatistics();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Statistik WhatsApp'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Record', stats['totalRecords'].toString()),
              _buildStatRow('Dengan WhatsApp', stats['withWhatsApp'].toString()),
              _buildStatRow('Sudah Terkirim', stats['sentWhatsApp'].toString()),
              _buildStatRow('Belum Terkirim', stats['pendingWhatsApp'].toString()),
              const Divider(),
              if (stats['withWhatsApp'] > 0) ...[
                _buildStatRow(
                  'Persentase Terkirim', 
                  '${((stats['sentWhatsApp'] / stats['withWhatsApp']) * 100).toStringAsFixed(1)}%'
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Gagal memuat statistik WhatsApp: $e');
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
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

  void _clearFilters() {
    setState(() {
      _selectedPatient = null;
      _startDate = null;
      _endDate = null;
      _whatsappFilter = null; // RESET FILTER WHATSAPP
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
                    // Header dengan indikator WhatsApp status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // UBAH WARNA BERDASARKAN STATUS WHATSAPP
                        color: data.isWhatsAppSent 
                          ? Colors.green[700]
                          : Colors.orange[700],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            data.isWhatsAppSent 
                              ? Icons.check_circle
                              : Icons.analytics,
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
                                if (data.isWhatsAppSent) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Laporan sudah dikirim via WhatsApp',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
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

  void _editData(OmronData data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur edit akan segera tersedia'),
        backgroundColor: Colors.orange[700],
      ),
    );
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
      case 'whatsapp_stats':
        _showWhatsAppStatistics();
        break;
      case 'export':
        _exportData();
        break;
      case 'analytics':
        Navigator.pushNamed(context, '/analytics');
        break;
      case 'refresh':
        _loadData();
        break;
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur export akan segera tersedia'),
        backgroundColor: Colors.orange[700],
      ),
    );
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}