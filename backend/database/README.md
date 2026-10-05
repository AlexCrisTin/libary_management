# Cài đặt database

Backend sử dụng một bộ schema duy nhất. Không cần chạy từng migration riêng lẻ.

## Cài tự động

1. Bật MySQL/XAMPP.
2. Sao chép `.env.example` thành `.env` và điền thông tin MySQL.
3. Từ thư mục `backend`, chạy:

```bash
npm run db:setup
```

Lệnh này sẽ:

- tạo database nếu chưa tồn tại;
- tạo đủ 18 bảng;
- thêm dữ liệu demo nếu database đang trống;
- kiểm tra lại toàn bộ bảng sau khi cài.

Nếu database đã có người dùng, `db:setup` sẽ tự bỏ qua seed để không làm thay đổi dữ liệu hiện tại.

Các lệnh khác:

```bash
npm run db:schema
npm run db:seed
npm run db:reset -- --yes
```

- `db:schema`: chỉ cài cấu trúc bảng.
- `db:seed`: chủ động thêm dữ liệu demo vào database đã có schema; nên dùng cho database trống.
- `db:reset -- --yes`: xóa toàn bộ database, tạo lại schema và dữ liệu demo. Đây là lệnh phá hủy dữ liệu.

## Cài bằng MySQL Workbench

Nếu không muốn dùng Node.js:

1. Tạo database có charset `utf8mb4` và collation `utf8mb4_unicode_ci`.
2. Chọn database đó làm default schema.
3. Chạy `database/schema.sql`.
4. Chạy `database/seed.sql` nếu cần dữ liệu demo.

## Tài khoản demo

- Admin: `admin` / `Admin@123`
- Thủ thư: `librarian` / `Librarian@123`
- Độc giả: `reader.an` / `Reader@123`
- Độc giả: `reader.minh` / `Reader@123`

Hãy đổi mật khẩu trước khi triển khai thật.
