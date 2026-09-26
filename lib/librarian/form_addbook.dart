import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';

class FormAddBook extends StatefulWidget {
  const FormAddBook({super.key});

  @override
  State<FormAddBook> createState() => _FormAddBookState();
}

class _FormAddBookState extends State<FormAddBook> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _isbn = TextEditingController();
  final _authorInput = TextEditingController();
  final _publisherName = TextEditingController();
  final _year = TextEditingController();
  final _subjectInput = TextEditingController();
  final _language = TextEditingController(text: 'vi');
  final _pages = TextEditingController();
  final _callNumber = TextEditingController();
  final _copies = TextEditingController(text: '1');
  final _edition = TextEditingController();
  final _ddcClass = TextEditingController();
  final _description = TextEditingController();

  final List<String> _authors = [];
  final List<String> _subjects = [];
  List<Map<String, dynamic>> _shelves = const [];
  String? _locationId;
  bool _loading = false;
  bool _loadingShelves = true;
  String _coverData = '';

  @override
  void initState() {
    super.initState();
    _loadShelves();
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _subtitle,
      _isbn,
      _authorInput,
      _publisherName,
      _year,
      _subjectInput,
      _language,
      _pages,
      _callNumber,
      _copies,
      _edition,
      _ddcClass,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadShelves() async {
    try {
      final data = await ApiClient.get('/shelves');
      if (mounted) setState(() => _shelves = apiList(data));
    } catch (error) {
      if (mounted) _show('Không tải được danh sách kệ: $error');
    } finally {
      if (mounted) setState(() => _loadingShelves = false);
    }
  }

  void _addValue(TextEditingController controller, List<String> target) {
    final value = controller.text.trim();
    if (value.isEmpty || target.contains(value)) return;
    setState(() {
      target.add(value);
      controller.clear();
    });
  }

  Future<void> _selectCoverImage() async {
    try {
      final data = await pickLocalImageAsDataUri();
      if (data != null && mounted) setState(() => _coverData = data);
    } catch (error) {
      if (mounted) _show(error.toString());
    }
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      _show('Tên sách không được để trống.');
      return;
    }
    if (_title.text.trim().length > 500) {
      _show('Tên sách không được vượt quá 500 ký tự.');
      return;
    }
    if (_isbn.text.trim().length > 20) {
      _show('ISBN không được vượt quá 20 ký tự.');
      return;
    }
    if (_authorInput.text.trim().isNotEmpty) {
      _addValue(_authorInput, _authors);
    }
    if (_subjectInput.text.trim().isNotEmpty) {
      _addValue(_subjectInput, _subjects);
    }

    final publishYear = _optionalPositiveInt(_year, 'Năm xuất bản');
    if (_year.text.trim().isNotEmpty && publishYear == null) return;
    final pageCount = _optionalPositiveInt(_pages, 'Số trang');
    if (_pages.text.trim().isNotEmpty && pageCount == null) return;
    final initialCopies = _optionalPositiveInt(_copies, 'Số bản sao');
    if (initialCopies == null) return;

    setState(() => _loading = true);
    try {
      await _ensureIsbnIsUnique();
      String? uploadedCoverUrl;
      if (_coverData.isNotEmpty) {
        final bytes = decodeDataImage(_coverData);
        if (bytes == null) {
          throw const FormatException('Không đọc được ảnh bìa đã chọn.');
        }
        final uploadResult = apiMap(
          await ApiClient.uploadImage('/uploads/book-cover', bytes: bytes),
        );
        uploadedCoverUrl = apiText(uploadResult['url'], fallback: '');
      }
      await ApiClient.post(
        '/books',
        body: {
          'title': _title.text.trim(),
          'subtitle': _nullable(_subtitle.text),
          'isbn': _nullable(_isbn.text),
          'authors': _authors,
          // Chưa có API danh mục nhà xuất bản: lưu tên vào metadata thay vì
          // gửi nó vào khóa ngoại publisher_id và làm MySQL từ chối bản ghi.
          'publisher_id': null,
          'publish_year': publishYear,
          'edition': _nullable(_edition.text),
          'language': _language.text.trim().isEmpty
              ? 'vi'
              : _language.text.trim(),
          'description': _nullable(_description.text),
          'page_count': pageCount,
          'call_number': _nullable(_callNumber.text),
          'ddc_class': _nullable(_ddcClass.text),
          'subject_headings': _subjects,
          'cover_url': uploadedCoverUrl,
          'initial_copies': initialCopies,
          'location_id': _locationId,
          'metadata': {
            if (_publisherName.text.trim().isNotEmpty)
              'publisher_name': _publisherName.text.trim(),
          },
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _show(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _nullable(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  int? _optionalPositiveInt(TextEditingController controller, String label) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null || value < 0) {
      _show('$label phải là số nguyên không âm.');
      return null;
    }
    return value;
  }

  Future<void> _ensureIsbnIsUnique() async {
    final isbn = _isbn.text.trim();
    if (isbn.isEmpty) return;
    final result = apiMap(
      await ApiClient.get('/books', query: {'keyword': isbn, 'limit': 20}),
    );
    final duplicate = apiList(
      result['items'],
    ).any((book) => book['isbn']?.toString().trim() == isbn);
    if (duplicate) {
      throw const ApiException('ISBN này đã tồn tại trong thư viện.');
    }
  }

  void _openTab(int index) {
    if (index == 1) {
      Navigator.pop(context);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LibrarianShell(initialIndex: index)),
      (_) => false,
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Thêm sách', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 34),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
                    decoration: BoxDecoration(
                      color: kLibCardFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Thông tin sách',
                          style: TextStyle(
                            color: kLibBookTitle,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          width: 124,
                          height: 1,
                          margin: const EdgeInsets.only(top: 8, bottom: 26),
                          color: kLibBrownTitle.withValues(alpha: .4),
                        ),
                        _CoverPicker(
                          data: _coverData,
                          onTap: _selectCoverImage,
                          onRemove: _coverData.isEmpty
                              ? null
                              : () => setState(() => _coverData = ''),
                        ),
                        const SizedBox(height: 26),
                        _FullField(
                          label: 'Tên sách',
                          controller: _title,
                          required: true,
                        ),
                        _FullField(label: 'Phụ đề', controller: _subtitle),
                        _FullField(label: 'ISBN', controller: _isbn),
                        _MultiValueField(
                          label: 'Tác giả',
                          controller: _authorInput,
                          values: _authors,
                          onAdd: () => _addValue(_authorInput, _authors),
                          onRemove: (value) =>
                              setState(() => _authors.remove(value)),
                        ),
                        _TwoFields(
                          leftLabel: 'Nhà xuất bản',
                          leftController: _publisherName,
                          rightLabel: 'Năm xuất bản',
                          rightController: _year,
                          rightKeyboard: TextInputType.number,
                        ),
                        _MultiValueField(
                          label: 'Thể loại',
                          controller: _subjectInput,
                          values: _subjects,
                          onAdd: () => _addValue(_subjectInput, _subjects),
                          onRemove: (value) =>
                              setState(() => _subjects.remove(value)),
                        ),
                        _TwoFields(
                          leftLabel: 'Ngôn ngữ',
                          leftController: _language,
                          rightLabel: 'Số trang',
                          rightController: _pages,
                          rightKeyboard: TextInputType.number,
                        ),
                        _TwoFields(
                          leftLabel: 'Mã xếp giá',
                          leftController: _callNumber,
                          rightLabel: 'Bản sao',
                          rightController: _copies,
                          rightKeyboard: TextInputType.number,
                        ),
                        _ShelfField(
                          loading: _loadingShelves,
                          shelves: _shelves,
                          value: _locationId,
                          onChanged: (value) =>
                              setState(() => _locationId = value),
                        ),
                        _TwoFields(
                          leftLabel: 'Ấn bản',
                          leftController: _edition,
                          rightLabel: 'Mã DDC',
                          rightController: _ddcClass,
                        ),
                        _FullField(
                          label: 'Mô tả',
                          controller: _description,
                          lines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 136,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLibGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Tạo',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: LibrarianBottomBar(
        currentIndex: 1,
        onSelect: _openTab,
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibrarianScanner()),
        ),
      ),
    );
  }
}

const _labelStyle = TextStyle(
  color: kLibBrownTitle,
  fontSize: 15,
  fontWeight: FontWeight.w700,
);

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  final String data;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataImage(data);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 142,
            height: 94,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? const Icon(
                    Icons.image_rounded,
                    color: Color(0xFF405170),
                    size: 38,
                  )
                : Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onRemove ?? onTap,
          icon: Icon(
            onRemove == null ? Icons.folder_open_rounded : Icons.delete_outline,
            size: 19,
          ),
          label: Text(onRemove == null ? 'Chọn ảnh từ máy' : 'Xóa ảnh'),
        ),
      ],
    );
  }
}

class _FullField extends StatelessWidget {
  const _FullField({
    required this.label,
    required this.controller,
    this.required = false,
    this.lines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: lines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 82,
            child: Padding(
              padding: EdgeInsets.only(top: lines > 1 ? 10 : 0),
              child: Text('$label${required ? ' *' : ''}', style: _labelStyle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _InputBox(controller: controller, lines: lines),
          ),
        ],
      ),
    );
  }
}

class _MultiValueField extends StatelessWidget {
  const _MultiValueField({
    required this.label,
    required this.controller,
    required this.values,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final TextEditingController controller;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 82, child: Text(label, style: _labelStyle)),
              const SizedBox(width: 8),
              Expanded(
                child: _InputBox(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                height: 38,
                child: IconButton.filled(
                  onPressed: onAdd,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(backgroundColor: kLibBeigeButton),
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
          if (values.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 90, top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: values
                      .map(
                        (value) => InputChip(
                          label: Text(value),
                          onDeleted: () => onRemove(value),
                          backgroundColor: kLibBeigeSoft,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({
    required this.leftLabel,
    required this.leftController,
    required this.rightLabel,
    required this.rightController,
    this.rightKeyboard,
  });

  final String leftLabel;
  final TextEditingController leftController;
  final String rightLabel;
  final TextEditingController rightController;
  final TextInputType? rightKeyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leftLabel, style: _labelStyle),
                const SizedBox(height: 5),
                _InputBox(controller: leftController),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rightLabel, style: _labelStyle),
                const SizedBox(height: 5),
                _InputBox(
                  controller: rightController,
                  keyboardType: rightKeyboard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfField extends StatelessWidget {
  const _ShelfField({
    required this.loading,
    required this.shelves,
    required this.value,
    required this.onChanged,
  });

  final bool loading;
  final List<Map<String, dynamic>> shelves;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 82,
            child: Text('Vị trí kệ', style: _labelStyle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: value,
                        isExpanded: true,
                        hint: const Text('Chọn kệ'),
                        items: shelves.map((shelf) {
                          final id = apiText(
                            shelf['location_id'],
                            fallback: '',
                          );
                          final label =
                              'Tầng ${shelf['floor']} • ${shelf['section']}-${shelf['shelf']} ${apiText(shelf['position'], fallback: '')}';
                          return DropdownMenuItem(
                            value: id,
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: onChanged,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    this.keyboardType,
    this.lines = 1,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int lines;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: lines,
      maxLines: lines,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
