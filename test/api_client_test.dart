import 'package:flutter_test/flutter_test.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient.resetBaseUrl();
  });

  test('chuẩn hóa IP thành API backend mặc định', () {
    expect(
      ApiClient.normalizeBaseUrl('192.168.1.25'),
      'http://192.168.1.25:3000/api',
    );
  });

  test('giữ nguyên địa chỉ API đầy đủ', () {
    expect(
      ApiClient.normalizeBaseUrl('http://192.168.1.25:4000/api'),
      'http://192.168.1.25:4000/api',
    );
  });

  test('lưu và nạp lại địa chỉ developer mode', () async {
    await ApiClient.saveBaseUrl('10.0.0.8');
    await ApiClient.initialize();

    expect(ApiClient.baseUrl, 'http://10.0.0.8:3000/api');
  });

  test('chỉ hiển thị tên khi tác giả là object JSON', () {
    expect(apiText({'name': 'Nguyễn Văn A', 'role': 'author'}), 'Nguyễn Văn A');
  });

  test('chuẩn hóa danh sách tác giả ở cả dạng object và chuỗi', () {
    expect(
      apiText([
        {'name': 'Nguyễn Văn A', 'role': 'author'},
        'Trần Thị B',
      ]),
      'Nguyễn Văn A, Trần Thị B',
    );
  });

  test('đọc được trường JSON đang lưu dưới dạng chuỗi', () {
    expect(
      apiText('[{"name":"Nguyễn Văn A","role":"author"}]'),
      'Nguyễn Văn A',
    );
  });

  test('không in nguyên object không có trường hiển thị', () {
    expect(apiText({'role': 'author'}), '—');
  });
}
