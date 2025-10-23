class ApiConfig {
  // ============================================================
  // 🌐 API Base URL Configuration
  // ============================================================

  // 👉 Android Emulator
  static const String baseUrl = 'http://10.0.2.2:4000';

  // 👉 For Real Android Device (replace with your computer's IP)
  // static const String baseUrl = 'http://192.168.1.100:4000';

  // 👉 iOS Simulator
  // static const String baseUrl = 'http://localhost:4000';

  // 👉 Real iOS Device (replace with your computer's IP)
  // static const String baseUrl = 'http://192.168.1.100:4000';

  // ============================================================
  // 🔐 Authentication
  // ============================================================
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String refreshEndpoint = '/api/auth/refresh';

  // ============================================================
  // 👤 User Profile & Progression
  // ============================================================
  static const String profileEndpoint = '/api/protected/me';
  static const String progressionEndpoint = '/api/progressions/me';
  static const String initializeProgressEndpoint = '/api/progressions/initialize';
  static const String completeTopicEndpoint = '/api/progressions/complete-topic';
  static const String topicStatusEndpoint = '/api/progressions/topic-status';
  static const String leaderboardEndpoint = '/api/progressions/leaderboard';
  static const String gamificationEndpoint = '/api/progressions/gamification';
  static const String unlockNextEndpoint = '/api/progressions/unlock-next';
  static const String updateStreakEndpoint = '/api/progressions/update-streak';

  // ============================================================
  // 📘 Lessons & Topics
  // ============================================================
  static const String lessonsEndpoint = '/api/lessons';
  static const String publishedLessonsEndpoint = '/api/lessons/published';
  static const String topicsByLessonEndpoint = '/api/topics'; // + /:lessonId
  static const String vocabByTopicEndpoint = '/api/vocab/topic'; // + /:topicId
  static const String quizByTopicEndpoint = '/api/quizzes/topic'; // + /:topicId

  // ============================================================
  // 🧠 Vocabulary & Quizzes
  // ============================================================
  static const String vocabEndpoint = '/api/vocab';
  static const String quizzesEndpoint = '/api/quizzes';
  static const String submitQuestionEndpoint = '/api/quizzes/submit-question';
  static const String submitQuizEndpoint = '/api/quizzes/submit';

  // ============================================================
  // 🎥 Videos
  // ============================================================
  static const String videosEndpoint = '/api/videos';
  static const String markVideoViewedEndpoint = '/api/videos'; // + /:id/mark-viewed
  static const String addSubtitlesEndpoint = '/api/videos'; // + /:id/subtitles
  static const String addWordDefinitionEndpoint = '/api/videos'; // + /:id/words
  static const String getWordDefinitionEndpoint = '/api/videos/words'; // + /:word

  // ============================================================
  // 📝 Topic Attempts
  // ============================================================
  static const String topicAttemptsEndpoint = '/api/topic-attempts';

  // ============================================================
  // 🌍 Translation
  // ============================================================
  static const String translationEndpoint = '/api/translation';

  // ============================================================
  // 🏅 Badges & Ranks
  // ============================================================
  static const String badgesEndpoint = '/api/badges';
  static const String ranksEndpoint = '/api/ranks';

  // ============================================================
  // 🔔 Notifications
  // ============================================================
  static const String notificationsEndpoint = '/api/notifications';

  // ============================================================
  // 🏰 Tower (Challenge)
  // ============================================================
  static const String towerLevelsEndpoint = '/api/tower-levels';
  static const String towerProgressEndpoint = '/api/tower-levels/progress/me'; // 🆕 thêm dòng này
  static const String towerCompleteEndpoint = '/api/tower/complete';

  // ============================================================
  // 👥 Users
  // ============================================================
  static const String usersEndpoint = '/api/users';

  // ============================================================
  // 📊 Reports
  // ============================================================
  static const String reportsEndpoint = '/api/reports';
}
