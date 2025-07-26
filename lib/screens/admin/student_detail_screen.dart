// lib/screens/admin/student_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart'; // Untuk akses client supabase
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart'; // Kita tetap gunakan untuk dialog
import 'package:sipatka/utils/app_theme.dart';
import 'package:sipatka/utils/error_dialog.dart';

class StudentDetailScreen extends StatefulWidget {
  // Sekarang kita hanya perlu studentId untuk mengambil semua data
  final String studentId;
  final String initialStudentName; // Untuk judul app bar awal

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.initialStudentName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  // Future untuk menampung data dari RPC
  late Future<Map<String, dynamic>> _studentDetailsFuture;

  @override
  void initState() {
    super.initState();
    // Panggil RPC saat halaman pertama kali dibuka
    _studentDetailsFuture = _fetchStudentDetails();
  }

  // Fungsi untuk memanggil RPC dari Supabase
  Future<Map<String, dynamic>> _fetchStudentDetails() async {
    try {
      final response = await supabase.rpc(
        'get_student_details',
        params: {'student_uuid': widget.studentId},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      // Jika terjadi error, lemparkan agar bisa ditangani oleh FutureBuilder
      throw 'Gagal memuat detail siswa: $e';
    }
  }

  void _refreshData() {
    setState(() {
      _studentDetailsFuture = _fetchStudentDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialStudentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Muat Ulang Data",
            onPressed: _refreshData,
          ),
          // Tombol Edit dan Hapus akan menggunakan data dari FutureBuilder
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _studentDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Data siswa tidak ditemukan."));
          }

          final details = snapshot.data!;
          final profileData = details['profile'] as Map<String, dynamic>;
          final paymentsData =
              (details['payments'] as List).cast<Map<String, dynamic>>();

          // Buat objek UserModel sementara untuk digunakan di dialog
          final studentForDialog = UserModel(
            uid: profileData['id'],
            studentName: profileData['student_name'],
            className: profileData['class_name'],
            parentName: profileData['parent_name'],
            email: profileData['email'],
            role: 'user',
            saldo: (profileData['saldo'] as num?)?.toDouble() ?? 0.0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(profileData),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text("Edit Data"),
                      onPressed:
                          () =>
                              _showEditStudentDialog(context, studentForDialog),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      label: const Text("Hapus Akun"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed:
                          () => _showDeleteConfirmation(
                            context,
                            profileData['parent_id'],
                          ), // Hapus berdasarkan parent_id
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Riwayat Tagihan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                if (paymentsData.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Belum ada riwayat tagihan."),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paymentsData.length,
                    itemBuilder: (context, index) {
                      // Buat objek Payment dari data JSON
                      final payment = Payment.fromSupabase({
                        ...paymentsData[index],
                        'due_date': (paymentsData[index]['due_date'] as String),
                        'created_at':
                            DateTime.now().toIso8601String(), // Nilai dummy
                      });
                      return _buildPaymentTile(payment);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET DAN DIALOG HELPER ---
  Widget _buildProfileCard(Map<String, dynamic> profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.child_care,
              "Nama Siswa",
              profile['student_name'] ?? '...',
            ),
            _buildInfoRow(
              Icons.class_,
              "Kelas",
              profile['class_name'] ?? '...',
            ),
            _buildInfoRow(
              Icons.person,
              "Nama Wali",
              profile['parent_name'] ?? '...',
            ),
            _buildInfoRow(Icons.email, "Email Wali", profile['email'] ?? '...'),
            _buildInfoRow(
              Icons.wallet,
              "Saldo",
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
              ).format(profile['saldo'] ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 16),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final totalAmount = payment.amount;
    final statusInfo = payment.getStatusInfo();
    final monthInt =
        payment.month; // Ini seharusnya sudah benar dari model Anda
    final Map<int, String> monthMap = {
      1: 'Januari',
      2: 'Februari',
      3: 'Maret',
      4: 'April',
      5: 'Mei',
      6: 'Juni',
      7: 'Juli',
      8: 'Agustus',
      9: 'September',
      10: 'Oktober',
      11: 'November',
      12: 'Desember',
    };
    final monthName = monthMap[int.tryParse(monthInt) ?? 0] ?? monthInt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusInfo['icon'], color: statusInfo['color']),
        title: Text('$monthName ${payment.year}'),
        subtitle: Text(
          "Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}",
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currencyFormat.format(totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              statusInfo['text'],
              style: TextStyle(color: statusInfo['color'], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(BuildContext context, UserModel student) {
    final studentNameController = TextEditingController(
      text: student.studentName,
    );
    // --- AWAL PERBAIKAN DROPDOWN ---
    String? _selectedClass = student.className;
    final List<String> _classes = ['TK A1', 'TK B1'];
    // --- AKHIR PERBAIKAN DROPDOWN ---
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Edit Data Siswa"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: studentNameController,
                      decoration: const InputDecoration(
                        labelText: "Nama Siswa",
                      ),
                    ),
                    const SizedBox(height: 16),
                    // --- GANTI TEXTFIELD MENJADI DROPDOWN ---
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Kelas',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _classes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        _selectedClass = newValue;
                      },
                      validator:
                          (value) =>
                              value == null ? 'Kelas wajib dipilih' : null,
                    ),
                    // --- AKHIR PERUBAHAN DROPDOWN ---
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await supabase
                          .from('students')
                          .update({
                            'full_name': studentNameController.text.trim(),
                            'class_name': _selectedClass,
                          })
                          .eq('id', student.uid);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Data siswa berhasil diupdate"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _refreshData();
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Tutup dialog loading
                        showErrorDialog(
                          context: context,
                          title: 'Update Gagal',
                          message:
                              'Tidak dapat menyimpan perubahan. Silakan coba lagi nanti.\n\nDetail: $e',
                        );
                      }
                    }
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  // lib/screens/admin/student_detail_screen.dart -> Ganti fungsi _showDeleteConfirmation

  void _showDeleteConfirmation(BuildContext context, String parentId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Hapus Akun"),
            content: const Text(
              "Apakah Anda yakin? Tindakan ini akan menghapus akun wali dan semua data terkait (siswa, tagihan) secara permanen.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await supabase.functions.invoke(
                      'delete-user-account',
                      body: {'uid': parentId},
                    );
                    if (mounted) {
                      // Tutup dialog konfirmasi
                      Navigator.pop(context);

                      // Kembali ke halaman daftar DAN kirim sinyal 'true'
                      Navigator.pop(context, true);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Akun siswa berhasil dihapus."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Tutup dialog loading
                      showErrorDialog(
                        context: context,
                        title: 'Hapus Akun Gagal',
                        message:
                            'Tidak dapat menghapus akun saat ini. Pastikan koneksi internet stabil.\n\nDetail: $e',
                      );
                    }
                  }
                },
                child: const Text("Hapus"),
              ),
            ],
          ),
    );
  }
}
