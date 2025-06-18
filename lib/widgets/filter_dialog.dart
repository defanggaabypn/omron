import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterDialog extends StatefulWidget {
  final List<String> patientNames;
  final String? selectedPatient;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?, DateTime?, DateTime?) onApply;
  final VoidCallback onClear;

  const FilterDialog({
    Key? key,
    required this.patientNames,
    this.selectedPatient,
    this.startDate,
    this.endDate,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _selectedPatient;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.selectedPatient;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.orange[700]),
          SizedBox(width: 8),
          Text('Filter Data'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Filter
            Text(
              'Pilih Pasien',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPatient,
                  hint: Text('Semua Pasien'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Pasien'),
                    ),
                    ...widget.patientNames.map((name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPatient = value;
                    });
                  },
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Date Range Filter
            Text(
              'Rentang Tanggal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            
            // Start Date
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Text(
                      _startDate != null 
                        ? 'Dari: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'
                        : 'Pilih tanggal mulai',
                      style: TextStyle(
                        color: _startDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    if (_startDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                          });
                        },
                        icon: Icon(Icons.clear, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 8),
            
            // End Date
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Text(
                      _endDate != null 
                        ? 'Sampai: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                        : 'Pilih tanggal akhir',
                      style: TextStyle(
                        color: _endDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    if (_endDate != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                        icon: Icon(Icons.clear, size: 16),
                        padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Quick Date Filters
            Text(
              'Filter Cepat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickFilterChip('Hari Ini', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month, now.day);
                    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                  });
                }),
                _buildQuickFilterChip('7 Hari', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now.subtract(Duration(days: 7));
                    _endDate = now;
                  });
                }),
                _buildQuickFilterChip('30 Hari', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now.subtract(Duration(days: 30));
                    _endDate = now;
                  });
                }),
                _buildQuickFilterChip('3 Bulan', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month - 3, now.day);
                    _endDate = now;
                  });
                }),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClear();
            Navigator.pop(context);
          },
          child: Text('Hapus Filter'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedPatient, _startDate, _endDate);
            Navigator.pop(context);
          },
          child: Text('Terapkan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.orange[50],
      labelStyle: TextStyle(color: Colors.orange[700]),
      side: BorderSide(color: Colors.orange[300]!),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, clear it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
          // If start date is after end date, clear it
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = null;
          }
        }
      });
    }
  }
}

