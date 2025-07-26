// lib/screens/admin/manage_students_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/screens/admin/admin_chat_detail_screen.dart';
import 'package:sipatka/screens/admin/student_detail_screen.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Siswa & Pesan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Cari Siswa atau Wali...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            // --- PERBAIKAN TIPE DATA STREAMBUILDER ---
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: adminProvider.getStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Belum ada data siswa terdaftar.'),
                  );
                }

                final allStudents = snapshot.data!;
                final filteredStudents =
                    _searchQuery.isEmpty
                        ? allStudents
                        : allStudents.where((student) {
                          final studentName =
                              (student['student_name'] as String? ?? '')
                                  .toLowerCase();
                          final parentName =
                              (student['parent_name'] as String? ?? '')
                                  .toLowerCase();
                          return studentName.contains(_searchQuery) ||
                              parentName.contains(_searchQuery);
                        }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(child: Text('Siswa tidak ditemukan.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    // --- Bekerja dengan Map, bukan UserModel ---
                    final studentData = filteredStudents[index];
                    return _buildStudentTile(context, studentData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- PERBAIKAN: Widget ini sekarang menerima Map<String, dynamic> ---
  Widget _buildStudentTile(
    BuildContext context,
    Map<String, dynamic> studentData,
  ) {
    final studentName = studentData['student_name'] ?? 'Tanpa Nama';
    final parentName = studentData['parent_name'] ?? 'Tanpa Wali';
    final className = studentData['class_name'] ?? 'Tanpa Kelas';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () async {
          // <-- Jadikan async
          // Tunggu hasil dari halaman detail
          final deletionSuccess = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => StudentDetailScreen(
                    studentId: studentData['student_id'],
                    initialStudentName: studentName,
                  ),
            ),
          );

          // Jika hasilnya adalah 'true', artinya ada penghapusan
          if (deletionSuccess == true) {
            // Panggil setState untuk "memaksa" widget membangun ulang dirinya,
            // yang akan membuat StreamBuilder mengambil data terbaru.
            setState(() {});
          }
        },
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColorLight,
          child: Text(
            studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Wali: $parentName | Kelas: $className'),
        trailing: IconButton(
          tooltip: "Chat dengan $parentName",
          icon: const Icon(Icons.chat_bubble_outline),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            // --- KUNCI PERBAIKAN: Membuat UserModel on-the-fly dengan ID yang BENAR ---
            final parentForChat = UserModel(
              uid: studentData['parent_id'], // Gunakan parent_id untuk chat
              parentName: parentName,
              // Isi field lain dengan data yang relevan atau nilai default
              studentName: studentName,
              className: className,
              email: '', // Email tidak dibutuhkan untuk navigasi chat
              role: 'user',
              saldo: 0.0,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminChatDetailScreen(parent: parentForChat),
              ),
            );
          },
        ),
      ),
    );
  }
}
