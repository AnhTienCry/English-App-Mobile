# 🔄 API Migration Summary - Mobile App

## Ngày cập nhật: 2025-10-22

## ✅ Các thay đổi đã thực hiện

### 1. **API Config Updates** (`lib/config/api_config.dart`)

#### **Progression Endpoints** (đã cập nhật)
```dart
// ❌ CŨ (SAI)
static const String progressionEndpoint = '/api/progression/user';
static const String initializeProgressEndpoint = '/api/progression/initialize';

// ✅ MỚI (ĐÚNG theo backend)
static const String progressionEndpoint = '/api/progressions/me';
static const String initializeProgressEndpoint = '/api/progressions/initialize';
static const String completeTopicEndpoint = '/api/progressions/complete-topic';
static const String topicStatusEndpoint = '/api/progressions/topic-status'; // + /:lessonId
static const String leaderboardEndpoint = '/api/progressions/leaderboard';
static const String gamificationEndpoint = '/api/progressions/gamification';
static const String unlockNextEndpoint = '/api/progressions/unlock-next';
static const String updateStreakEndpoint = '/api/progressions/update-streak';
```

#### **Tower Endpoints** (mới thêm)
```dart
static const String towerLevelsEndpoint = '/api/tower-levels';
static const String towerCompleteEndpoint = '/api/tower/complete';
```

#### **Users & Reports Endpoints** (mới thêm)
```dart
static const String usersEndpoint = '/api/users';
static const String reportsEndpoint = '/api/reports';
```

---

### 2. **Screen Updates**

#### **progress_screen.dart**
- ✅ Đã thêm import `ApiConfig`
- ✅ Đổi từ hardcoded paths sang sử dụng `ApiConfig.progressionEndpoint`
- ✅ Đổi từ hardcoded paths sang sử dụng `ApiConfig.initializeProgressEndpoint`

#### **lesson_topics_screen.dart**
- ✅ Đổi từ `/api/topics/${lessonId}` sang `${ApiConfig.topicsByLessonEndpoint}/${lessonId}`

#### **home_screen.dart** (đã đúng)
- ✅ Đã sử dụng `ApiConfig.profileEndpoint`
- ✅ Đã sử dụng `ApiConfig.progressionEndpoint` (sẽ tự động dùng endpoint mới)
- ✅ Đã sử dụng `ApiConfig.initializeProgressEndpoint` (sẽ tự động dùng endpoint mới)

---

## 🔍 Backend Routes Reference

### Auth Routes (`/api/auth`)
- ✅ `POST /api/auth/login` - Đăng nhập
- ✅ `POST /api/auth/register` - Đăng ký student
- ✅ `POST /api/auth/refresh` - Refresh token

### Protected Routes (`/api/protected`)
- ✅ `GET /api/protected/me` - Lấy thông tin user

### Lessons Routes (`/api/lessons`)
- ✅ `GET /api/lessons/published` - Lấy lessons đã xuất bản
- ✅ `GET /api/lessons` - Lấy tất cả lessons (cần auth)
- ✅ `GET /api/lessons/:id` - Lấy chi tiết lesson
- ✅ `POST /api/lessons/submit` - Submit lesson result

### Topics Routes (`/api/topics`)
- ✅ `GET /api/topics/:lessonId` - Lấy topics theo lesson
- ✅ `POST /api/topics/:id/attempts` - Submit topic attempt

### Vocab Routes (`/api/vocab`)
- ✅ `GET /api/vocab` - Lấy tất cả vocab
- ✅ `GET /api/vocab/topic/:topicId` - Lấy vocab theo topic

### Quiz Routes (`/api/quizzes`)
- ✅ `GET /api/quizzes` - Lấy tất cả quizzes
- ✅ `GET /api/quizzes/topic/:topicId` - Lấy quizzes theo topic
- ✅ `POST /api/quizzes/submit` - Submit quiz result
- ✅ `POST /api/quizzes/submit-question` - Submit từng câu hỏi

### Video Routes (`/api/videos`)
- ✅ `GET /api/videos` - Lấy tất cả videos
- ✅ `GET /api/videos/:id` - Lấy chi tiết video
- ✅ `GET /api/videos/lesson/:lessonId` - Lấy videos theo lesson
- ✅ `GET /api/videos/search` - Tìm kiếm videos
- ✅ `POST /api/videos/:id/subtitles` - Thêm subtitles
- ✅ `POST /api/videos/:id/words` - Thêm word definition
- ✅ `GET /api/videos/words/:word` - Lấy word definition

### Progression Routes (`/api/progressions`) ⚠️ **CHÚ Ý: đổi từ /progression sang /progressions**
- ✅ `POST /api/progressions/initialize` - Khởi tạo progress
- ✅ `GET /api/progressions/me` - Lấy progression của user
- ✅ `POST /api/progressions/complete-topic` - Hoàn thành topic
- ✅ `GET /api/progressions/topic-status/:lessonId` - Lấy trạng thái topic
- ✅ `GET /api/progressions/leaderboard` - Lấy bảng xếp hạng
- ✅ `GET /api/progressions/gamification` - Lấy thông tin gamification
- ✅ `POST /api/progressions/unlock-next` - Mở khóa lesson tiếp theo
- ✅ `POST /api/progressions/update-streak` - Cập nhật streak

### Translation Routes (`/api/translation`)
- ✅ `POST /api/translation/en-to-vi` - Dịch EN -> VI
- ✅ `POST /api/translation/vi-to-en` - Dịch VI -> EN
- ✅ `POST /api/translation/custom` - Dịch tùy chỉnh
- ✅ `GET /api/translation/languages` - Lấy ngôn ngữ hỗ trợ
- ✅ `POST /api/translation/vocab` - Dịch vocab (cần auth)
- ✅ `GET /api/translation/history` - Lịch sử dịch (cần auth)
- ✅ `POST /api/translation/contextual` - Dịch theo ngữ cảnh (cần auth)
- ✅ `POST /api/translation/manual` - Dịch thủ công (cần auth)
- ✅ `GET /api/translation/history/new` - Lịch sử dịch mới (cần auth)

### Tower Routes (`/api/tower-levels`, `/api/tower`)
- ✅ `GET /api/tower-levels` - Lấy danh sách tầng
- ✅ `GET /api/tower-levels/:id` - Lấy chi tiết tầng (cần auth)
- ✅ `POST /api/tower/complete` - Hoàn thành challenge (student only)

### Badge Routes (`/api/badges`)
- ✅ `GET /api/badges` - Lấy danh sách badges

### Rank Routes (`/api/ranks`)
- ✅ `GET /api/ranks` - Lấy danh sách ranks

### Notification Routes (`/api/notifications`)
- ✅ `GET /api/notifications` - Lấy danh sách thông báo

### Users Routes (`/api/users`)
- ✅ Các endpoints liên quan đến user management

### Reports Routes (`/api/reports`)
- ✅ Các endpoints liên quan đến báo cáo

---

## ⚠️ Breaking Changes

### **1. Progression API Path Changed**
```
/api/progression/user  →  /api/progressions/me
/api/progression/initialize  →  /api/progressions/initialize
```

**Ảnh hưởng:**
- ✅ `home_screen.dart` - ĐÃ SỬA
- ✅ `progress_screen.dart` - ĐÃ SỬA

### **2. Quiz Submit Endpoint**
Backend endpoint: `POST /api/quizzes/submit`
- Body chỉ cần: `{ topicId: string }`
- Backend tự tính score từ quiz attempts đã submit trước đó

---

## 📋 Checklist - Những việc cần làm tiếp

### ✅ Đã hoàn thành:
- [x] Cập nhật `api_config.dart` với tất cả endpoints
- [x] Sửa `progress_screen.dart` để dùng ApiConfig
- [x] Sửa `lesson_topics_screen.dart` để dùng ApiConfig
- [x] Đảm bảo `home_screen.dart` tương thích

### 🔄 Cần kiểm tra thêm:
- [ ] Test login flow
- [ ] Test get lessons + topics
- [ ] Test vocabulary screen
- [ ] Test quiz flow (submit-question + submit)
- [ ] Test video learning
- [ ] Test translation features
- [ ] Test tower/challenge features
- [ ] Test progression tracking
- [ ] Test leaderboard
- [ ] Test notifications

### 📝 Gợi ý cải thiện:
1. **Tạo Models/DTOs**: Tạo Dart models cho các response từ backend
   - `User`, `Lesson`, `Topic`, `Quiz`, `Video`, `Progress`, etc.
   
2. **Service Layer**: Tách logic API calls ra khỏi screens
   - `AuthService`, `LessonService`, `ProgressService`, etc.

3. **Error Handling**: Thống nhất cách xử lý errors
   - Global error handler
   - User-friendly error messages

4. **State Management**: Cân nhắc dùng Provider/Riverpod/Bloc
   - Để quản lý state tốt hơn
   - Tránh prop drilling

---

## 🧪 Test Cases Quan Trọng

### 1. Authentication Flow
```
1. Login với student@example.com / 123123
2. Token được lưu vào SharedPreferences
3. Auto-refresh token khi hết hạn
4. Logout và clear data
```

### 2. Lesson Flow
```
1. Fetch published lessons
2. Click vào lesson → fetch topics
3. Click vào topic → chọn Vocab hoặc Quiz
4. Hoàn thành Quiz → backend tự cập nhật progress
5. Back về lessons → progress bar cập nhật
```

### 3. Quiz Flow
```
1. Fetch quiz questions by topicId
2. User answer từng câu → gọi submit-question
3. Khi hoàn thành → gọi submit với chỉ topicId
4. Backend tự tính score từ attempts
```

---

## 🚀 Deployment Notes

### Environment Variables
```
Backend URL: http://10.0.2.2:4000 (Android Emulator)
Backend URL: http://192.168.1.xxx:4000 (Real Device)
```

### Backend Requirements
- ✅ CORS đã config cho mobile app
- ✅ JWT auth với refresh token
- ✅ All routes được mount đúng trong app.ts

---

## 📞 Contact

Nếu có vấn đề hoặc câu hỏi, hãy kiểm tra:
1. Backend logs trong console
2. Mobile app debug console
3. Network requests trong DevTools (Flutter)
4. Database state nếu cần

---

**Last Updated:** 2025-10-22 13:47 UTC
**Updated By:** AI Assistant
**Status:** ✅ Core APIs đã được cập nhật và aligned với backend
