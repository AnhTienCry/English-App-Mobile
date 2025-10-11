import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'New Lesson Available!',
      'message': 'Check out the new "Advanced Grammar" lesson',
      'type': 'lesson',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
      'icon': Icons.book,
      'color': Colors.blue,
    },
    {
      'id': '2',
      'title': 'Quiz Reminder',
      'message': 'Don\'t forget to complete your vocabulary quiz',
      'type': 'quiz',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'isRead': false,
      'icon': Icons.quiz,
      'color': Colors.green,
    },
    {
      'id': '3',
      'title': 'Achievement Unlocked!',
      'message': 'Congratulations! You earned the "Vocabulary Master" badge',
      'type': 'achievement',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
      'icon': Icons.emoji_events,
      'color': Colors.orange,
    },
    {
      'id': '4',
      'title': 'Streak Alert!',
      'message': 'Keep your 5-day streak going! Study for just 10 minutes today',
      'type': 'streak',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      'isRead': true,
      'icon': Icons.local_fire_department,
      'color': Colors.red,
    },
    {
      'id': '5',
      'title': 'New Video Uploaded',
      'message': 'Watch the new pronunciation guide video',
      'type': 'video',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'icon': Icons.play_circle,
      'color': Colors.purple,
    },
    {
      'id': '6',
      'title': 'Weekly Progress Report',
      'message': 'You completed 3 lessons this week. Great job!',
      'type': 'progress',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'isRead': true,
      'icon': Icons.trending_up,
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'clear_read':
                  _clearReadNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear read notifications'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                    onDismiss: () => _dismissNotification(notification['id']),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you about new lessons, achievements, and more!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Add a new notification for demo
    final newNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Welcome Back!',
      'message': 'Continue your English learning journey',
      'type': 'general',
      'timestamp': DateTime.now(),
      'isRead': false,
      'icon': Icons.waving_hand,
      'color': Colors.blue,
    };
    
    setState(() {
      notifications.insert(0, newNotification);
    });
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });

    // Navigate based on notification type
    switch (notification['type']) {
      case 'lesson':
        // Navigate to lessons
        break;
      case 'quiz':
        // Navigate to quizzes
        break;
      case 'achievement':
        // Navigate to achievements
        break;
      case 'video':
        // Navigate to videos
        break;
      case 'progress':
        // Navigate to progress
        break;
      default:
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${notification['title']}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _dismissNotification(String notificationId) {
    setState(() {
      notifications.removeWhere((n) => n['id'] == notificationId);
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _clearReadNotifications() {
    setState(() {
      notifications.removeWhere((n) => n['isRead'] == true);
    });
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] == true;
    final timestamp = notification['timestamp'] as DateTime;

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isRead ? 2 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isRead ? null : Border.all(color: Colors.blue[200]!, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Notification icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    notification['icon'],
                    color: notification['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action button
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right),
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  Map<String, bool> notificationSettings = {
    'lessons': true,
    'quizzes': true,
    'achievements': true,
    'videos': true,
    'progress': true,
    'streaks': true,
    'general': false,
    'push_notifications': true,
    'email_notifications': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notification Types'),
          _buildNotificationToggle(
            'New Lessons',
            'Get notified when new lessons are available',
            'lessons',
            Icons.book,
          ),
          _buildNotificationToggle(
            'Quiz Reminders',
            'Receive reminders to complete quizzes',
            'quizzes',
            Icons.quiz,
          ),
          _buildNotificationToggle(
            'Achievements',
            'Celebrate when you unlock new badges',
            'achievements',
            Icons.emoji_events,
          ),
          _buildNotificationToggle(
            'New Videos',
            'Stay updated with new video content',
            'videos',
            Icons.play_circle,
          ),
          _buildNotificationToggle(
            'Progress Updates',
            'Weekly progress reports and milestones',
            'progress',
            Icons.trending_up,
          ),
          _buildNotificationToggle(
            'Streak Alerts',
            'Reminders to maintain your study streak',
            'streaks',
            Icons.local_fire_department,
          ),
          _buildNotificationToggle(
            'General Updates',
            'App updates and general announcements',
            'general',
            Icons.info,
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Delivery Methods'),
          _buildNotificationToggle(
            'Push Notifications',
            'Receive notifications on your device',
            'push_notifications',
            Icons.notifications,
          ),
          _buildNotificationToggle(
            'Email Notifications',
            'Get updates via email',
            'email_notifications',
            Icons.email,
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Quiet Hours'),
          _buildQuietHoursCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    String key,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: notificationSettings[key] ?? false,
          onChanged: (value) {
            setState(() {
              notificationSettings[key] = value;
            });
          },
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Quiet Hours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: false,
                  onChanged: (value) {
                    // Handle quiet hours toggle
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Set specific hours when you don\'t want to receive notifications',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '10:00 PM',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '8:00 AM',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
