import 'package:flutter/material.dart';
import '../screens/lesson_option_screen.dart';

/// Helper để mở trang Option chung cho mọi lesson
Future<void> openLessonOptions(BuildContext context, {required String lessonId, required String lessonTitle}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LessonOptionScreen(lessonId: lessonId, lessonTitle: lessonTitle),
    ),
  );
}