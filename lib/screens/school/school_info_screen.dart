import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class SchoolInfoScreen extends StatelessWidget {
  const SchoolInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Sekolah',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // School Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.school, size: 60, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'TK An-Naafi\'Nur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Akreditasi B', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Information
          _buildInfoCard('Kontak & Alamat', [
            _buildInfoRow(
              Icons.location_on,
              'Alamat',
              'Perum Orchid Park Blok D-1 No 1 Gebang Raya, Kec. Periuk, Kota Tangerang',
            ),
            _buildInfoRow(Icons.person, 'Kepala Sekolah', 'EVIE SULIYANTI'),
            _buildInfoRow(
              Icons.support_agent,
              'Operator',
              'Virda Asmarani Alexandra',
            ),
            _buildInfoRow(Icons.phone, 'Telepon', '+62 878-8134-3541'),
            _buildInfoRow(Icons.email, 'Email', 'tk.annaafinur98@gmail.com'),
          ]),
          const SizedBox(height: 16),

          // School Details
          _buildInfoCard('Detail Sekolah', [
            _buildInfoRow(Icons.numbers, 'NPSN', '69909283'),
            _buildInfoRow(Icons.business, 'Status', 'Swasta'),
            _buildInfoRow(Icons.account_balance, 'Kepemilikan', 'Yayasan'),
            _buildInfoRow(Icons.book, 'Kurikulum', 'Kurikulum Merdeka'),
            _buildInfoRow(
              Icons.calendar_today,
              'SK Pendirian',
              ' AHU-1029.AH.01.04.Tahun 2012',
            ),
            _buildInfoRow(
              Icons.verified,
              'SK Operasional',
              '421.1/Kep.06-TK/BPPMPT/20',
            ),
          ]),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text('Lihat Lokasi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callSchool,
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text('Hubungi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps() async {
    // Alamat atau nama tempat yang ingin dicari
    const String query = "TK An-Naafi'Nur Perum Orchid Park Blok D-1 No 1";

    // Format URL yang benar untuk Google Maps
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}",
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // Beri pesan jika tidak bisa membuka maps
        print('Tidak dapat membuka Google Maps.');
      }
    } catch (e) {
      print('Error saat membuka peta: $e');
    }
  }

  void _callSchool() async {
    // Nomor telepon tujuan
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: '+6281234567890');

    try {
      if (await canLaunchUrl(phoneLaunchUri)) {
        await launchUrl(phoneLaunchUri);
      } else {
        // Beri pesan jika tidak bisa melakukan panggilan
        print('Tidak dapat melakukan panggilan.');
      }
    } catch (e) {
      print('Error saat melakukan panggilan: $e');
    }
  }
}
