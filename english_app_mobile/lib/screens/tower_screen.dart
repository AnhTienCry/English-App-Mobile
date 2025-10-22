import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tower_provider.dart';
import 'quiz_screen.dart';

class TowerScreen extends StatefulWidget {
  @override
  _TowerScreenState createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch levels khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TowerProvider>().fetchLevels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TowerProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${provider.error}'),
              ElevatedButton(
                onPressed: () => provider.fetchLevels(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final levels = provider.levels;
    if (levels.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No tower levels available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rank Tower')),
      body: ListView.builder(
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isUnlocked = provider.isLevelUnlocked(index);
          return ListTile(
            title: Text('Level ${level['levelNumber']}: ${level['title']}'),
            subtitle: Text('Reward: ${level['rewardPoints']} points'),
            enabled: isUnlocked,
            onTap: isUnlocked
                ? () async {
                    // Chuyển sang QuizScreen (giả định cần topicId từ level, nếu không có thì sửa)
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(
                          topicId: level['_id'] ?? '', // sửa nếu cần
                          lessonId: '',
                        ),
                      ),
                    );
                    // Nếu quiz hoàn thành, mark level completed và refresh
                    if (result == true) {
                      provider.markLevelCompleted(level['_id'] ?? '');
                      // Refresh levels từ server để đảm bảo UI update với data mới
                      provider.fetchLevels();
                    }
                  }
                : null,
          );
        },
      ),
    );
  }
}