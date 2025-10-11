import 'package:flutter/material.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Badges', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard)),
            Tab(text: 'Streaks', icon: Icon(Icons.local_fire_department)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBadgesTab(),
          _buildLeaderboardTab(),
          _buildStreaksTab(),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    final badges = [
      {
        'id': 'first_lesson',
        'title': 'First Steps',
        'description': 'Complete your first lesson',
        'icon': Icons.school,
        'color': Colors.blue,
        'earned': true,
        'earnedDate': '2024-01-15',
      },
      {
        'id': 'vocabulary_master',
        'title': 'Vocabulary Master',
        'description': 'Learn 100 vocabulary words',
        'icon': Icons.style,
        'color': Colors.green,
        'earned': true,
        'earnedDate': '2024-01-20',
      },
      {
        'id': 'quiz_champion',
        'title': 'Quiz Champion',
        'description': 'Score 90% or higher on 5 quizzes',
        'icon': Icons.quiz,
        'color': Colors.orange,
        'earned': true,
        'earnedDate': '2024-01-25',
      },
      {
        'id': 'video_watcher',
        'title': 'Video Scholar',
        'description': 'Watch 10 learning videos',
        'icon': Icons.play_circle,
        'color': Colors.purple,
        'earned': false,
        'earnedDate': null,
        'progress': 7,
        'target': 10,
      },
      {
        'id': 'streak_master',
        'title': 'Streak Master',
        'description': 'Study for 7 consecutive days',
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'earned': false,
        'earnedDate': null,
        'progress': 3,
        'target': 7,
      },
      {
        'id': 'perfectionist',
        'title': 'Perfectionist',
        'description': 'Score 100% on any quiz',
        'icon': Icons.star,
        'color': Colors.yellow,
        'earned': false,
        'earnedDate': null,
        'progress': 0,
        'target': 1,
      },
    ];

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh badges data
        await Future.delayed(const Duration(seconds: 1));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          return BadgeCard(badge: badge);
        },
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    final leaderboard = [
      {
        'rank': 1,
        'name': 'Alice Johnson',
        'score': 2850,
        'avatar': 'A',
        'badge': '🥇',
      },
      {
        'rank': 2,
        'name': 'Bob Smith',
        'score': 2720,
        'avatar': 'B',
        'badge': '🥈',
      },
      {
        'rank': 3,
        'name': 'Carol Davis',
        'score': 2680,
        'avatar': 'C',
        'badge': '🥉',
      },
      {
        'rank': 4,
        'name': 'You',
        'score': 2450,
        'avatar': 'Y',
        'badge': '⭐',
        'isCurrentUser': true,
      },
      {
        'rank': 5,
        'name': 'David Wilson',
        'score': 2320,
        'avatar': 'D',
        'badge': '',
      },
      {
        'rank': 6,
        'name': 'Emma Brown',
        'score': 2180,
        'avatar': 'E',
        'badge': '',
      },
      {
        'rank': 7,
        'name': 'Frank Miller',
        'score': 2050,
        'avatar': 'F',
        'badge': '',
      },
    ];

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh leaderboard data
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final player = leaderboard[index];
          return LeaderboardCard(
            player: player,
            isTopThree: index < 3,
          );
        },
      ),
    );
  }

  Widget _buildStreaksTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh streaks data
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current streak
            _buildCurrentStreakCard(),
            const SizedBox(height: 24),
            
            // Streak history
            const Text(
              'Streak History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Weekly calendar
            _buildStreakCalendar(),
            const SizedBox(height: 24),
            
            // Streak milestones
            const Text(
              'Streak Milestones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStreakMilestones(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Current Streak',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '5 days',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Keep it up! 🔥',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar() {
    final today = DateTime.now();
    final days = List.generate(21, (index) {
      final date = today.subtract(Duration(days: 20 - index));
      final isCompleted = index < 5; // Mock data: first 5 days completed
      final isToday = index == 20;
      
      return {
        'date': date,
        'isCompleted': isCompleted,
        'isToday': isToday,
      };
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last 3 weeks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${days.where((d) => d['isCompleted'] == true).length} days',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: day['isCompleted'] == true
                      ? Colors.green
                      : day['isToday'] == true
                          ? Colors.blue
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: day['isToday'] == true
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${(day['date'] as DateTime).day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: day['isCompleted'] == true || day['isToday'] == true
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakMilestones() {
    final milestones = [
      {'days': 3, 'title': 'Getting Started', 'earned': true},
      {'days': 7, 'title': 'One Week Warrior', 'earned': false},
      {'days': 14, 'title': 'Two Week Champion', 'earned': false},
      {'days': 30, 'title': 'Monthly Master', 'earned': false},
      {'days': 100, 'title': 'Century Scholar', 'earned': false},
    ];

    return Column(
      children: milestones.map((milestone) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: milestone['earned'] == true
                      ? Colors.green
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  milestone['earned'] == true
                      ? Icons.check
                      : Icons.lock,
                  color: milestone['earned'] == true
                      ? Colors.white
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${milestone['days']} days',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (milestone['earned'] == true)
                const Icon(Icons.emoji_events, color: Colors.orange),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;

  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final isEarned = badge['earned'] == true;
    final progress = badge['progress'] as int? ?? 0;
    final target = badge['target'] as int? ?? 1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isEarned
              ? LinearGradient(
                  colors: [
                    badge['color'].withOpacity(0.1),
                    badge['color'].withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEarned ? null : Colors.grey[100],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isEarned
                    ? badge['color']
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(30),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: badge['color'].withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                badge['icon'],
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            
            // Badge title
            Text(
              badge['title'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.black87 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Badge description
            Text(
              badge['description'],
              style: TextStyle(
                fontSize: 12,
                color: isEarned ? Colors.grey[700] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Progress or earned status
            if (isEarned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Earned',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              LinearProgressIndicator(
                value: progress / target,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(badge['color']),
              ),
              const SizedBox(height: 4),
              Text(
                '$progress/$target',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LeaderboardCard extends StatelessWidget {
  final Map<String, dynamic> player;
  final bool isTopThree;

  const LeaderboardCard({
    super.key,
    required this.player,
    required this.isTopThree,
  });

  @override
  Widget build(BuildContext context) {
    final rank = player['rank'] as int;
    final isCurrentUser = player['isCurrentUser'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Colors.blue[200]!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree
                  ? Colors.orange
                  : isCurrentUser
                      ? Colors.blue
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isCurrentUser ? Colors.blue : Colors.grey[400],
            child: Text(
              player['avatar'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Name and score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.blue : Colors.black87,
                        ),
                      ),
                    ),
                    if (player['badge'].isNotEmpty)
                      Text(
                        player['badge'],
                        style: const TextStyle(fontSize: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${player['score']} points',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
