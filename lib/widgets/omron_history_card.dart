import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/omron_data.dart';

class OmronHistoryCard extends StatelessWidget {
  final OmronData data;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OmronHistoryCard({
    Key? key,
    required this.data,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 12),
              _buildPatientInfo(),
              SizedBox(height: 12),
              _buildMeasurementSummary(),
              SizedBox(height: 12),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getOverallAssessmentColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.monitor_weight,
            color: _getOverallAssessmentColor(),
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.patientName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(data.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getOverallAssessmentColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            data.overallAssessment,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            Icons.person,
            '${data.age} thn',
            Colors.blue,
          ),
          SizedBox(width: 16),
          _buildInfoItem(
            data.gender == 'Male' ? Icons.male : Icons.female,
            data.gender == 'Male' ? 'Pria' : 'Wanita',
            data.gender == 'Male' ? Colors.blue : Colors.pink,
          ),
          SizedBox(width: 16),
          _buildInfoItem(
            Icons.height,
            '${data.height.toStringAsFixed(0)} cm',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildMeasurementItem(
            'Berat',
            '${data.weight.toStringAsFixed(1)} kg',
            Icons.scale,
            Colors.blue,
          ),
        ),
        Expanded(
          child: _buildMeasurementItem(
            'BMI',
            data.bmi.toStringAsFixed(1),
            Icons.straighten,
            _getBMIColor(),
          ),
        ),
        Expanded(
          child: _buildMeasurementItem(
            'Body Fat',
            '${data.bodyFatPercentage.toStringAsFixed(1)}%',
            Icons.pie_chart,
            Colors.orange,
          ),
        ),
        Expanded(
          child: _buildMeasurementItem(
            'Body Age',
            '${data.bodyAge} thn',
            Icons.schedule,
            _getBodyAgeColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
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
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Tap untuk detail lengkap',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit, size: 18),
              color: Colors.orange[700],
              tooltip: 'Edit',
              padding: EdgeInsets.all(4),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete, size: 18),
              color: Colors.red[700],
              tooltip: 'Hapus',
              padding: EdgeInsets.all(4),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ],
    );
  }

  Color _getOverallAssessmentColor() {
    switch (data.overallAssessment) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Color _getBMIColor() {
    if (data.bmi < 18.5) return Colors.blue;
    if (data.bmi < 25.0) return Colors.green;
    if (data.bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  Color _getBodyAgeColor() {
    final ageDiff = data.bodyAge - data.age;
    if (ageDiff <= -5) return Colors.green;
    if (ageDiff <= 0) return Colors.blue;
    if (ageDiff <= 5) return Colors.orange;
    return Colors.red;
  }
}
