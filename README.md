# Libary management - Hệ thống quản lý thư viện

Đồ án chuyên ngành - Nhóm N01

### Thành viên
- Trần Ngọc An - AlexCrisTin
- Nguyễn Gia Bảo - KURO2303

# Readily – Hệ thống quản lý thư viện

Readily là hệ thống quản lý thư viện gồm **ứng dụng di động/đa nền tảng viết bằng Flutter** và **backend REST API viết bằng Node.js (Express) + MySQL**. Hệ thống phục vụ ba nhóm người dùng: **độc giả**, **thủ thư** và **quản trị viên**, bao phủ toàn bộ nghiệp vụ thư viện: danh mục sách, mượn/trả, gia hạn, tiền phạt, đăng ký báo khi có sách, đặt slot nhận sách, thông báo tự động, nhắn tin và trợ lý AI cho thủ thư.

## Mục lục

- [Tính năng](#tính-năng)
- [Công nghệ](#công-nghệ)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Cài đặt và chạy](#cài-đặt-và-chạy)
- [Cấu hình môi trường](#cấu-hình-môi-trường)
- [Tài khoản demo](#tài-khoản-demo)
- [Quy tắc nghiệp vụ](#quy-tắc-nghiệp-vụ)
- [Tác vụ chạy nền](#tác-vụ-chạy-nền)
- [Trợ lý AI](#trợ-lý-ai)
- [Tổng quan API](#tổng-quan-api)
- [Cơ sở dữ liệu](#cơ-sở-dữ-liệu)
- [Bảo mật](#bảo-mật)
- [Kiểm thử](#kiểm-thử)
- [Build APK cho điện thoại thật](#build-apk-cho-điện-thoại-thật)
- [Lưu ý khi sử dụng mã nguồn](#lưu-ý-khi-sử-dụng-mã-nguồn)

## Tính năng

### Độc giả
- Màn hình chào, đăng nhập, đăng ký, quên/đặt lại mật khẩu bằng OTP.
- Trang chủ gợi ý sách; tìm kiếm, xem danh sách và chi tiết đầu sách; đánh dấu (bookmark) sách.
- Xem sách đang mượn, lịch sử mượn/trả, các khoản phạt; gửi yêu cầu gia hạn.
- Đăng ký nhận thông báo khi sách có sẵn (hold) và đặt slot đến lấy sách (pickup reservation).
- Nhận thông báo (sắp đến hạn, quá hạn, thẻ hết hạn, sách đã có), nhắn tin với thủ thư.
- Xem sơ đồ thư viện / vị trí kệ sách; quản lý hồ sơ cá nhân và ảnh đại diện.

### Thủ thư
- Bảng điều khiển thống kê và báo cáo mượn/trả.
- Quản lý đầu sách, bản sao (barcode, tình trạng), kệ sách, danh mục, nhà xuất bản; tải ảnh bìa lên.
- Quản lý độc giả: tạo hồ sơ, cập nhật trạng thái thẻ.
- Quy trình mượn – trả (hỗ trợ quét mã bằng camera), duyệt/từ chối gia hạn, thu tiền phạt, báo cáo hư hỏng/mất sách (kèm ảnh bằng chứng).
- Duyệt hoặc từ chối yêu cầu đặt slot nhận sách; xem danh sách hold.
- Hộp thư trao đổi với độc giả, thông báo cho thủ thư.
- Trợ lý AI tra cứu dữ liệu thư viện bằng tiếng Việt.
- Quản lý tài khoản người dùng: tạo, đổi vai trò, khóa/mở, đặt lại mật khẩu, xóa.

## Công nghệ

| Thành phần | Công nghệ |
| --- | --- |
| Ứng dụng | Flutter (Dart SDK `^3.8.1`), Material Design |
| Thư viện Flutter chính | `http`, `shared_preferences`, `mobile_scanner`, `file_picker`, `image` |
| Nền tảng hỗ trợ | Android, web, Windows, macOS, Linux |
| Backend | Node.js, Express 4 |
| Cơ sở dữ liệu | MySQL / MariaDB (`mysql2`) |
| Xác thực | JWT (`jsonwebtoken`), mã hoá mật khẩu `bcryptjs` |
| Bảo vệ API | `express-rate-limit`, CORS có kiểm soát, header bảo mật |
| Tải file | `multer` (kiểm tra MIME thật, giới hạn 5 MB) |
| Tài liệu API | Swagger UI / OpenAPI |
| Trợ lý AI | OpenRouter (function calling) |
| Kiểm thử | `node:test` (backend), `flutter_test` (ứng dụng) |

## Cấu trúc thư mục

```text
.
├── lib/                         # Mã nguồn Flutter
│   ├── main.dart                # Điểm khởi chạy
│   ├── core/                    # api_client, trạng thái API, xử lý ảnh cục bộ
│   ├── login/                   # Chào mừng, đăng nhập, đăng ký, quên mật khẩu
│   ├── reader/                  # Giao diện độc giả
│   ├── librarian/               # Giao diện thủ thư/quản trị
│   └── shared/                  # Thành phần dùng chung (sơ đồ thư viện)
├── backend/                     # API Node.js
│   ├── server.js                # Khởi động server + tác vụ nền
│   ├── src/
│   │   ├── app.js               # Cấu hình Express, route, Swagger, /health
│   │   ├── config/              # Kết nối DB, cấu hình bảo mật
│   │   ├── middlewares/         # auth, phân quyền, rate limit, xử lý lỗi
│   │   ├── modules/             # Các module nghiệp vụ (routes/controller/service)
│   │   ├── jobs/                # Tác vụ chạy nền
│   │   ├── docs/swagger.json    # Đặc tả OpenAPI
│   │   └── utils/               # Phân trang, định dạng phản hồi
│   ├── database/                # schema.sql, seed.sql và hướng dẫn cài DB
│   ├── scripts/setup-database.js
│   ├── test/                    # Kiểm thử nghiệp vụ (DB giả lập)
│   ├── test-real/               # Kiểm thử E2E trên MySQL thật
│   └── uploads/                 # Nơi lưu file tải lên
├── database/                    # Bản dump phpMyAdmin, migration lịch sử, books.csv
├── assets/                      # Ảnh và bộ icon SVG
├── scripts/build_pixel_apk.sh   # Build APK trỏ tới IP backend trong LAN
├── test/                        # Kiểm thử Flutter
├── android/ ios/ web/ windows/ macos/ linux/   # Mã nền tảng của Flutter
└── pubspec.yaml
```

### Các module backend

| Module | Chức năng |
| --- | --- |
| `auth` | Đăng ký, đăng nhập, hồ sơ, đổi/đặt lại mật khẩu, đăng xuất |
| `users` | Quản lý tài khoản (chỉ admin) |
| `books` | Tìm kiếm, chi tiết, quét mã, CRUD đầu sách, bản sao, bookmark |
| `categories`, `publishers`, `shelves` | Danh mục, nhà xuất bản, kệ sách |
| `readers` | Hồ sơ độc giả, thẻ, sách đang mượn, lịch sử, tuỳ chọn |
| `circulation` | Mượn, trả, gia hạn, phạt, báo hư hỏng/mất sách |
| `holds` | Đăng ký báo khi có sách |
| `pickupReservations` | Đặt slot đến lấy sách |
| `notifications`, `chat` | Thông báo và nhắn tin |
| `uploads` | Ảnh bìa, ảnh đại diện, ảnh bằng chứng |
| `dashboard` | Thống kê cho thủ thư |
| `ai` | Trợ lý AI cho thủ thư |

## Cài đặt và chạy

### Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.8.1`)
- Node.js (khuyến nghị bản LTS) và npm
- MySQL hoặc MariaDB (ví dụ XAMPP)

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env        # rồi điền thông tin, xem phần Cấu hình môi trường
openssl rand -hex 32        # dán kết quả vào JWT_SECRET trong .env
npm run db:setup            # tạo DB, 20 bảng, index và dữ liệu demo (nếu DB trống)
npm start                   # hoặc: npm run dev (tự reload)
```

Sau khi chạy:

- API: `http://localhost:3000/api`
- Kiểm tra sức khoẻ: `http://localhost:3000/health`
- Tài liệu Swagger: `http://localhost:3000/api-docs` (JSON: `/api-docs.json`)

Các lệnh quản lý cơ sở dữ liệu:

| Lệnh | Tác dụng |
| --- | --- |
| `npm run db:setup` | Tạo DB, schema, bổ sung index; seed nếu DB chưa có người dùng |
| `npm run db:schema` | Chỉ cài cấu trúc bảng |
| `npm run db:seed` | Thêm dữ liệu demo (nên dùng cho DB trống) |
| `npm run db:reset -- --yes` | **Xoá toàn bộ DB**, tạo lại schema và dữ liệu demo |

Nếu không dùng Node.js để cài DB, có thể chạy `backend/database/schema.sql` rồi `seed.sql` trong MySQL Workbench (charset `utf8mb4`, collation `utf8mb4_unicode_ci`).

### 2. Ứng dụng Flutter

```bash
flutter pub get
flutter run
```

Địa chỉ API mặc định của ứng dụng:

- Android Emulator: `http://10.0.2.2:3000/api`
- Các nền tảng khác: `http://127.0.0.1:3000/api`
- Ghi đè khi chạy/build: `--dart-define=API_BASE_URL=http://<ip>:3000/api`

Kiểm tra chất lượng mã nguồn:

```bash
flutter analyze
```

## Cấu hình môi trường

File `backend/.env` (mẫu: `backend/.env.example`):

| Biến | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `PORT`, `HOST` | `3000`, `0.0.0.0` | Cổng và địa chỉ lắng nghe |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | `localhost`, `3306`, `root`, rỗng, `library_db` | Kết nối MySQL |
| `JWT_SECRET` | — (**bắt buộc**) | Khoá ký JWT, tối thiểu 32 ký tự, không dùng khoá mẫu cũ |
| `JWT_EXPIRES_IN` | `7d` | Thời hạn token |
| `DEV_OTP_ENABLED` | `false` | Hiển thị OTP trong phản hồi (chỉ khi không phải production) |
| `CORS_ORIGINS` | `http://localhost:3000,http://localhost:8080` | Danh sách origin được phép, phân tách bằng dấu phẩy |
| `OPENROUTER_API_KEY` | — | Khoá OpenRouter cho trợ lý AI |
| `OPENROUTER_MODEL` | `openrouter/free` | Mô hình AI |
| `OPENROUTER_SITE_URL`, `OPENROUTER_APP_NAME` | — | Thông tin gửi kèm OpenRouter |
| `AI_MAX_OUTPUT_TOKENS`, `AI_TIMEOUT_MS` | `1000`, `30000` | Giới hạn đầu ra và thời gian chờ của AI |
| `AUTOMATIONS_ENABLED` | `true` | Bật/tắt toàn bộ tác vụ nền |
| `OVERDUE_SCAN_INTERVAL_MINUTES` | `60` | Chu kỳ quét sách quá hạn/sắp đến hạn |
| `CARD_SCAN_INTERVAL_MINUTES` | `60` | Chu kỳ quét thẻ sắp hết hạn |
| `PICKUP_SCAN_INTERVAL_MINUTES` | `15` | Chu kỳ giải phóng slot nhận sách hết hạn |
| `HOLD_SCAN_INTERVAL_MINUTES` | `15` | Chu kỳ xử lý hold hết hạn |

## Tài khoản demo

Dữ liệu seed tạo sẵn các tài khoản sau (đổi mật khẩu trước khi triển khai thật):

| Vai trò | Tên đăng nhập | Mật khẩu |
| --- | --- | --- |
| Quản trị viên | `admin` | `Admin@123` |
| Thủ thư | `librarian` | `Librarian@123` |
| Độc giả | `reader.an` | `Reader@123` |
| Độc giả | `reader.minh` | `Reader@123` |

## Quy tắc nghiệp vụ

Các giá trị dưới đây lấy từ mã nguồn backend.

- **Vai trò:** `admin`, `librarian`, `reader`. Đăng ký công khai luôn tạo tài khoản `reader`.
- **Loại độc giả:** `student`, `lecturer`, `staff`, `public`. Mỗi độc giả có hạn mức mượn (`max_books`, mặc định **5 cuốn**).
- **Mượn sách:** hạn trả mặc định **14 ngày** (cho phép 1–365 ngày). Thẻ phải ở trạng thái hoạt động và chưa hết hạn; không được vượt hạn mức mượn.
- **Gia hạn:** mỗi lượt gia hạn **1–7 ngày**, tối đa **2 lần** cho mỗi lượt mượn. Độc giả gửi yêu cầu, thủ thư duyệt hoặc từ chối.
- **Tiền phạt:** mặc định **2.000 VNĐ/ngày** quá hạn (làm tròn lên theo ngày). Thủ thư ghi nhận thanh toán phạt; có thêm luồng báo hư hỏng và báo mất sách.
- **Trạng thái lượt mượn:** `borrowed`, `returned`, `overdue`, `lost`.
- **Hold (đăng ký báo khi có sách):** chỉ là đăng ký nhận thông báo, **không giữ hay ưu tiên bản sao**. Hiệu lực **14 ngày**. Trạng thái: `waiting`, `notified`, `fulfilled`, `cancelled`, `expired`.
- **Đặt slot nhận sách (pickup reservation):** độc giả đặt cho đầu sách đang còn bản sẵn có, thời hạn đến lấy **tối đa 7 ngày**; thủ thư duyệt hoặc từ chối. Độc giả đang mượn đầu sách đó không thể đặt thêm. Trạng thái: `pending`, `approved`, `rejected`, `cancelled`, `fulfilled`, `expired`.
- **Thông báo:** `hold_available`, `due_soon`, `overdue`, `card_expired`, `system`.

## Tác vụ chạy nền

Khởi động cùng `server.js` khi `AUTOMATIONS_ENABLED` khác `false`, và dừng an toàn khi nhận `SIGINT`/`SIGTERM`. Bộ lập lịch không cho một tác vụ chạy chồng lên chính nó.

| Tác vụ | Công việc | Chu kỳ mặc định |
| --- | --- | --- |
| Overdue | Đánh dấu sách quá hạn, gửi thông báo quá hạn và sắp đến hạn | 60 phút |
| Card expiration | Thông báo thẻ sắp hết hạn (trong 7 ngày), cập nhật thẻ đã hết hạn | 60 phút |
| Pickup reservation | Hết hạn các slot nhận sách và giải phóng bản sao | 15 phút |
| Hold expiration | Hết hạn hold chờ sau 14 ngày, đóng hold đã báo, giải phóng bản sao mồ côi | 15 phút |

Thủ thư cũng có thể kích hoạt thủ công quét quá hạn và quét thẻ hết hạn qua API thông báo.

## Trợ lý AI

Trợ lý AI dành cho **thủ thư và quản trị viên**, chạy qua OpenRouter với cơ chế function calling. Trợ lý được yêu cầu luôn trả lời bằng tiếng Việt và chỉ dựa trên dữ liệu do công cụ trả về, không bịa số liệu. Các công cụ hiện có:

`searchBooks`, `getBookAvailability`, `getOverdueLoans`, `getLoansDueSoon`, `getActiveLoans`, `getReaderSummary`, `getDashboardStatistics`, `getPopularBooks`, `getUnpaidFines`, `getExpiringReaderCards`.

Lịch sử hội thoại và mức sử dụng được lưu trong các bảng `ai_conversations`, `ai_messages`, `ai_usage_logs`. Cần đặt `OPENROUTER_API_KEY` để dùng tính năng này.

## Tổng quan API

Tiền tố chung: `/api`. Các route cần đăng nhập gửi header `Authorization: Bearer <token>`. Danh sách đầy đủ có tại Swagger (`/api-docs`).

| Nhóm | Đường dẫn | Ghi chú |
| --- | --- | --- |
| Xác thực | `/api/auth` | `register`, `login`, `me`, `profile`, `change-password`, `forgot-password`, `reset-password`, `logout` |
| Người dùng | `/api/users` | Chỉ admin |
| Sách | `/api/books` | Đọc công khai; ghi cần thủ thư/admin; bookmark dành cho độc giả |
| Danh mục / NXB / Kệ | `/api/categories`, `/api/publishers`, `/api/shelves` | Đọc công khai; ghi cần thủ thư/admin |
| Độc giả | `/api/readers` | Độc giả chỉ truy cập hồ sơ của mình; thủ thư/admin truy cập tất cả |
| Mượn trả | `/api/circulation` | `borrow`, `return`, `renew`, `renew-requests`, `active`, `history`, `pay-fine`, `report`, `lost` |
| Hold | `/api/holds` | `my-holds`, tạo, huỷ, danh sách (thủ thư) |
| Slot nhận sách | `/api/pickup-reservations` | `my-reservations`, tạo, `approve`, `reject`, `cancel` |
| Thông báo | `/api/notifications` | Độc giả và thủ thư có nhóm route riêng |
| Nhắn tin | `/api/chat` | Độc giả gửi/nhận; thủ thư xem hội thoại theo độc giả |
| Tải file | `/api/uploads` | `book-cover`, `reader-avatar`, `report-evidence` |
| Thống kê | `/api/dashboard/statistics` | Thủ thư/admin |
| Trợ lý AI | `/api/ai/librarian/...` | Thủ thư/admin |
| Sức khoẻ | `/health` | Kiểm tra server và kết nối DB |

File tải lên được phục vụ tĩnh tại `/uploads`.

## Cơ sở dữ liệu

Nguồn schema chính thức là `backend/database/schema.sql` (20 bảng, MySQL/MariaDB, `utf8mb4`):

| Nhóm | Bảng |
| --- | --- |
| Tài khoản | `users`, `readers`, `reader_preferences`, `password_resets`, `token_blacklist` |
| Danh mục sách | `bibliographic_records`, `book_copies`, `publishers`, `categories`, `shelf_locations`, `reader_bookmarks` |
| Nghiệp vụ | `borrow_transactions`, `renewal_requests`, `holds`, `pickup_reservations` |
| Giao tiếp | `notifications`, `chat_messages` |
| Trợ lý AI | `ai_conversations`, `ai_messages`, `ai_usage_logs` |

Thư mục `database/` ở gốc là tài liệu lịch sử: bản dump phpMyAdmin `library_db.sql`, các migration theo ngày trong `database/migrations/` và tập dữ liệu sách `database/data/books.csv` (cột theo dạng Goodreads). Khi cài mới, chỉ cần dùng `backend/database/schema.sql` thông qua `npm run db:setup`, không cần chạy từng migration.

Chi tiết thêm: [`backend/database/README.md`](backend/database/README.md).

## Bảo mật

- `JWT_SECRET` bắt buộc, tối thiểu 32 ký tự; server từ chối khởi động nếu thiếu hoặc dùng khoá mẫu cũ.
- Mật khẩu băm bằng `bcryptjs`; token đăng xuất được đưa vào danh sách chặn (`token_blacklist`); OTP đặt lại mật khẩu được băm bằng HMAC và so sánh thời gian hằng định.
- Phân quyền theo vai trò bằng middleware cho từng route.
- Giới hạn tần suất: đăng nhập 5 lần/15 phút, đăng ký 10 lần/giờ, API chung 500 yêu cầu/15 phút, kèm giới hạn riêng cho OTP và AI.
- CORS chỉ cho phép origin trong `CORS_ORIGINS` (cho phép `localhost` khi không ở production); ứng dụng di động không gửi `Origin` nên vẫn hoạt động.
- Header bảo mật: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`; tắt `X-Powered-By`; giới hạn body JSON 1 MB.
- Tải file: chỉ nhận ảnh, kiểm tra MIME thật qua nội dung file, tối đa 5 MB.

## Kiểm thử

### Backend

```bash
cd backend
npm test          # kiểm thử nghiệp vụ với DB giả lập (node:test)
npm run test:e2e  # kiểm thử xuyên suốt trên MySQL thật
```

- `npm test` bao gồm nghiệp vụ sách, mượn trả, dashboard, hold, slot nhận sách, tác vụ tự động, thông báo thủ thư, chat và xoá người dùng.
- `npm run test:e2e` chạy luồng đăng nhập, phân quyền, mượn/trả, gia hạn, tiền phạt và đặt slot trên MySQL cấu hình trong `.env`. Dữ liệu thử dùng mã ngẫu nhiên và được dọn sạch sau khi chạy. Không dùng `db:reset` cho việc này.

### Ứng dụng Flutter

```bash
flutter test
flutter analyze
```

## Build APK cho điện thoại thật

APK chạy trên điện thoại không dùng được `10.0.2.2` (chỉ dành cho Android Emulator); điện thoại phải gọi tới IP của máy đang chạy backend trong cùng mạng Wi-Fi.

1. Nối máy chạy backend và điện thoại vào cùng một mạng Wi-Fi.
2. Bật MySQL và chạy backend: `cd backend && npm start`.
3. Từ thư mục gốc, chạy:

```bash
./scripts/build_pixel_apk.sh
```

Script tự lấy IP Wi-Fi (macOS, giao diện `en0`/`en1`) và truyền vào Flutter qua `API_BASE_URL`. Nếu không tự tìm được IP, chỉ định thủ công:

```bash
API_HOST=192.168.x.x ./scripts/build_pixel_apk.sh
```

APK tạo tại `build/app/outputs/flutter-apk/app-release.apk`, cài bằng Android Studio hoặc:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Kiểm tra kết nối trước khi mở app bằng cách truy cập `http://<IP>:3000/health` trên trình duyệt của điện thoại. Máy chạy backend cần bật, và tường lửa phải cho phép Node.js nhận kết nối. Cách này chỉ phù hợp khi demo trong cùng mạng; muốn dùng ở mọi nơi cần triển khai backend và MySQL lên máy chủ có HTTPS.

