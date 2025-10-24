import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api_client.dart'; // dùng biến dio toàn cục của bạn
import '../config/api_config.dart';
import 'quiz_screen.dart';

class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _levels = [];

  @override
  void initState() {
    super.initState();
    _fetchLevels();
  }

  Future<void> _fetchLevels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // GET /api/tower-levels
      final res = await dio.get("${ApiConfig.baseUrl}/api/tower-levels");
      final data = res.data;
      if (data is List) {
        // sort theo levelNumber tăng dần (nếu backend chưa sort)
        data.sort((a, b) {
          final lnA = (a['levelNumber'] ?? 0) as int;
          final lnB = (b['levelNumber'] ?? 0) as int;
          return lnA.compareTo(lnB);
        });
        setState(() => _levels = data);
      } else {
        setState(() => _error = "Unexpected response format.");
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLevel(dynamic level) async {
    final String levelId = level['_id']?.toString() ?? '';
    if (levelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LevelId không hợp lệ')),
      );
      return;
    }
    // Mở QuizScreen theo chế độ TOWER: chỉ truyền levelId
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(levelId: levelId),
      ),
    );

    if (mounted) await _fetchLevels(); // refresh levels sau khi quay lại
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rank Tower', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _levels.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _fetchLevels,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _levels.length,
          itemBuilder: (_, i) {
            final level = _levels[i];
            final levelNum = level['levelNumber'] ?? (i + 1);
            final title = (level['title'] ?? 'Tower Level $levelNum').toString();

            return InkWell(
              onTap: () => _openLevel(level),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tầng $levelNum',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchLevels,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_clear, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Chưa có tầng nào.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchLevels,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}
