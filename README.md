# 📱 English App Mobile

## ⚙️ Cài đặt
```bash
git clone https://github.com/lenhat8413/Learning-English-App.git
cd english-app-mobile
flutter pub get
flutter run
Ứng dụng mobile dành cho Học viên, với các tính năng chính:

Học từ vựng bằng flashcard, audio, ví dụ.

Làm quiz, xem video học có phụ đề.

Nhận huy hiệu, leo tầng, xem bảng xếp hạng.

Nhận thông báo realtime từ giảng viên.

🔗 Kết nối Backend
Cấu hình API trong file:

lib/config/api.dart

dart
Sao chép mã
const String apiBaseUrl = "http://localhost:4000";
🧠 Ghi chú phát triển
Flutter SDK >= 3.0

Android Studio hoặc VS Code

Kết nối backend qua RESTful API (JWT Auth + Prisma API)

