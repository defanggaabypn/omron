class Patient {
  final int? id;
  final String nama;
  final String whatsapp;
  final int usia;
  final String gender;
  final double tinggi;
  final DateTime createdAt;
  final bool isSynced;

  Patient({
    this.id,
    required this.nama,
    required this.whatsapp,
    required this.usia,
    required this.gender,
    required this.tinggi,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'whatsapp': whatsapp,
    'usia': usia,
    'gender': gender,
    'tinggi': tinggi,
    'created_at': createdAt.toIso8601String(),
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    nama: json['nama'],
    whatsapp: json['whatsapp'],
    usia: json['usia'],
    gender: json['gender'],
    tinggi: json['tinggi'].toDouble(),
    createdAt: DateTime.parse(json['created_at']),
    isSynced: true,
  );
}
