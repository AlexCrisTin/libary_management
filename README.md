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

## Cấu trúc thư mục

```text
lib/
├── login/       # Các màn hình xác thực
├── reader/      # Các chức năng dành cho độc giả
└── main.dart    # Điểm khởi chạy ứng dụng
```

