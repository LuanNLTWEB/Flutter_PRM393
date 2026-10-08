# 🏠 HomeFix - Dự Án Quản Lý & Cung Cấp Dịch Vụ Sửa Chữa Tại Nhà

Dự án áp dụng mô hình **Monorepo** độc lập gồm 2 phần chính:
- **`backend/`**: RESTful API sử dụng Node.js, Express và MongoDB Atlas.
- **`frontend/`**: Ứng dụng di động đa nền tảng sử dụng Flutter (Provider, Feature-first).

---

## 🚀 1. Hướng Dẫn Khởi Chạy (Quick Start)

### Yêu cầu môi trường:
- **Node.js**: phiên bản 18+ (hoặc mới nhất)
- **Flutter SDK**: 3.x+ (Dart 3.x, null-safety)
- **MongoDB Atlas** (hoặc local MongoDB URI)

### 🔹 Khởi Chạy Backend:
```bash
cd backend
cp .env.example .env     # Cập nhật thông tin MONGO_URI và PORT trong file .env
npm install
npm run dev              # Chạy môi trường dev với nodemon (hoặc 'npm start')
```
*Health Check endpoint:* `GET http://localhost:5000/api/health`

### 🔹 Khởi Chạy Frontend:
```bash
cd frontend
flutter pub get
flutter run
```

---

## 🤖 2. BỘ QUY TẮC PHÁT TRIỂN DÀNH CHO AI & DEVELOPER (AI CODING RULES)

> [!IMPORTANT]
> **Tất cả các AI Coding Assistant (Antigravity, Cursor, Copilot, ChatGPT, Claude,...) hoặc Developer khi tham gia phát triển dự án này BẮT BUỘC phải tuân thủ nghiêm ngặt các quy tắc dưới đây.**

---

### RULE 1: Tuân Thủ Tuyệt Đối Ngăn Xếp Công Nghệ (Tech Stack Lock)
* **Backend:**
  - **Chỉ sử dụng:** JavaScript (Node.js/Express, CommonJS `require`), Mongoose (kết nối MongoDB Atlas), `dotenv`, `cors`.
  - **TUYỆT ĐỐI KHÔNG:** Sinh code bằng ngôn ngữ khác (C#, Java, Python, Go, PHP, TypeScript trừ khi có yêu cầu chuyển đổi rõ ràng).
  - **TUYỆT ĐỐI KHÔNG:** Đổi sang ORM khác (như Prisma, Sequelize, TypeORM).
* **Frontend:**
  - **Chỉ sử dụng:** Flutter & Dart (null-safety), State Management: `Provider`.
  - **TUYỆT ĐỐI KHÔNG:** Tự ý cài đặt các thư viện state management khác (như Bloc, Riverpod, GetX, MobX) nếu chưa được yêu cầu.
  - **TUYỆT ĐỐI KHÔNG:** Đưa code framework khác vào (React Native, Kotlin native, Swift native,...).

---

### RULE 2: Kiểm Soát Phạm Vi (Strict Scope)
- **Chỉ code đúng những gì được yêu cầu trong prompt:** Tuyệt đối không tự ý thêm bất kỳ màn hình, logic, tính năng hay cài đặt thêm package nào ngoài yêu cầu.

---

### RULE 3: Kiến Trúc & Cấu Trúc Thư Mục Chuẩn (Architecture Pattern)

#### 📂 Backend (`backend/`): Kiến trúc MVC phân lớp rõ ràng
```text
backend/
├── config/         # Cấu hình hệ thống (db.js, ...)
├── controllers/    # Xử lý logic nghiệp vụ request/response
├── models/         # Khai báo Mongoose Schema
├── routes/         # Định tuyến API endpoints
├── middlewares/    # Middleware xác thực, phân quyền, validate dữ liệu, bắt lỗi
├── .env.example    # Mẫu biến môi trường
├── package.json
└── server.js       # Entry point khởi tạo app Express & lắng nghe cổng
```
* **Quy chuẩn file:**
  - `controllers/` chỉ nhận dữ liệu, gọi model xử lý, trả về response JSON chuẩn.
  - `routes/` chỉ làm nhiệm vụ gắn route URL với hàm trong controller và middleware.
  - Xử lý lỗi luôn bọc trong `try / catch` và trả mã HTTP status code chuẩn.

#### 📂 Frontend (`frontend/`): Kiến trúc Feature-first / Clean Architecture
```text
frontend/lib/
├── core/                       # Dùng chung cho toàn bộ ứng dụng
│   ├── constants/              # Biến hằng số (app_constants.dart, ...)
│   ├── network/                # Cấu hình API endpoints, HTTP client
│   └── theme/                  # Cấu hình Theme, Màu sắc, Typography
├── features/                   # Mỗi chức năng là một module độc lập
│   └── [feature_name]/         # Ví dụ: home, auth, booking, repair_service...
│       ├── data/               # Models, Data sources, Repositories
│       ├── domain/             # Entities, Use cases (nếu cần)
│       └── presentation/       # Widgets, Screens, Providers
└── main.dart                   # Entry point cực kỳ ngắn gọn
```
* **Tiêu chuẩn bắt buộc cho `frontend/lib/main.dart`:**
  - Giữ **dưới 50 dòng code**.
  - **Chỉ làm:** `WidgetsFlutterBinding.ensureInitialized()`, nạp theme từ `AppTheme`, gắn root widget `MyApp()` và chạy `runApp()`.
  - **TUYỆT ĐỐI KHÔNG:** Viết logic nghiệp vụ, gọi API hay viết trực tiếp code layout giao diện trong file này.

---

### RULE 4: Chuẩn Hóa Giao Tiếp & Đồng Bộ Dữ Liệu (API & Data Synchronization)
1. **Chuẩn RESTful API:**
   - URL tài nguyên dùng danh từ số nhiều: `/api/services`, `/api/bookings`, `/api/users`.
   - Phương thức HTTP: `GET` (đọc), `POST` (tạo mới), `PUT/PATCH` (cập nhật), `DELETE` (xóa).
2. **Cấu trúc phản hồi JSON thống nhất (Standard JSON Response):**
   - Thành công:
     ```json
     {
       "success": true,
       "message": "Thông báo ngắn gọn",
       "data": { ... }
     }
     ```
   - Thất bại:
     ```json
     {
       "success": false,
       "message": "Nội dung thông báo lỗi cụ thể",
       "error": "Mã lỗi hoặc chi tiết lỗi kỹ thuật (nếu dev mode)"
     }
     ```
3. **Quy ước đặt tên (Naming Conventions):**
   - Backend JSON keys: thống nhất sử dụng `camelCase` (ví dụ: `userId`, `fullName`, `serviceType`).
   - Frontend Dart Model: sử dụng `camelCase` cho property và viết phương thức `fromJson` / `toJson` tương ứng chính xác với Backend.

---

### RULE 5: Quy Chuẩn Code Sạch (Clean Code Standards)
- **Không hardcode:**
  - Backend: Tất cả Port, Database URL, Secret Key đều phải đọc từ `process.env`.
  - Frontend: Tất cả Base URL, Api Endpoint phải định nghĩa trong `lib/core/network/api_endpoints.dart`. Màu sắc và kiểu chữ định nghĩa trong `lib/core/theme/app_theme.dart`.
- **Xử lý bất đồng bộ:** Luôn dùng `async/await` với khối `try/catch` đầy đủ.
- **Tính tự làm sạch:** Khi sửa đổi mã nguồn, xóa bỏ các import không dùng (unused imports), các biến thừa và đảm bảo không có cảnh báo nghiêm trọng từ linter (`flutter analyze` đạt 0 issues).

---

### RULE 6: Quy Định Git, Commit & Minh Chứng Đóng Góp (Git & Contribution Rules)

* **Cấm dồn commit (No Code Dump):** Tuyệt đối không chấp nhận việc dồn toàn bộ code vào một commit duy nhất ở giai đoạn cuối dự án. Phải commit chia nhỏ theo từng chức năng/tiến độ rõ ràng.
* **Code AI / Copy:** Việc đưa các khối code lớn do AI tạo ra hoặc copy về mà không có bằng chứng review, refactor hay test sẽ bị đánh giá là thiếu minh chứng đóng góp.
* **Định dạng Commit Message khuyến nghị:**
  ```text
  [Mã số SV/Tên] [Module/Màn hình] Mô tả ngắn gọn
  ```
  * **Ví dụ:** `[SE123456] [Booking] Add validation and submit state`
  * **Ví dụ thực tế dự án:** `[SE190980] [Review] Hoan thien module danh gia tho rate UC-RAT-01`