# Readily – Ứng dụng quản lý thư viện



## Chức năng hiện có

- Màn hình chào mừng, đăng nhập, đăng ký và quên mật khẩu.
- Trang chủ gợi ý sách và điều hướng nhanh đến các khu vực chính.
- Tìm kiếm sách và xem thông tin chi tiết của một đầu sách.
- Theo dõi sách đang mượn, lịch sử mượn/trả và các khoản phạt.
- Xem thông báo, hồ sơ cá nhân và chỉnh sửa thông tin hồ sơ.
- Khu vực nhắn tin với AI hoặc thủ thư ở giao diện mẫu.



## Công nghệ

- Flutter và Dart
- Material Design
- Hỗ trợ Android, iOS và các nền tảng Flutter khác

## Cài đặt và chạy dự án

Yêu cầu: [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run
```

Để kiểm tra chất lượng mã nguồn:

```bash
flutter analyze
```

## Xuất APK để dùng trên Google Pixel

APK chạy trên điện thoại thật không thể dùng địa chỉ `10.0.2.2`; địa chỉ đó chỉ
dùng cho Android Emulator. Pixel phải gọi đến IP Wi-Fi của Mac đang chạy
backend.

1. Kết nối Mac và Pixel vào cùng một mạng Wi-Fi.
2. Bật MySQL và chạy backend:

```bash
cd backend
npm start
```

3. Từ thư mục gốc dự án, build APK bằng lệnh:

```bash
./scripts/build_pixel_apk.sh
```

Script sẽ tự lấy IP Wi-Fi của Mac và truyền địa chỉ đó vào Flutter qua
`API_BASE_URL`. APK nằm tại:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Có thể cài qua Android Studio hoặc ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Để kiểm tra kết nối trước khi mở ứng dụng, truy cập trên Chrome của Pixel:

```text
http://IP-CUA-MAC:3000/health
```

Nếu script không tự tìm được IP, truyền thủ công:

```bash
API_HOST=192.168.x.x ./scripts/build_pixel_apk.sh
```

Mac phải đang bật, backend phải đang chạy và tường lửa macOS phải cho phép
Node.js nhận kết nối. Cách này chỉ phù hợp khi demo trong cùng mạng Wi-Fi. Muốn
dùng ở bất kỳ đâu cần triển khai backend và MySQL lên máy chủ có HTTPS.

## Cấu trúc thư mục

```text
lib/
├── login/       # Các màn hình xác thực
├── reader/      # Các chức năng dành cho độc giả
└── main.dart    # Điểm khởi chạy ứng dụng
```
