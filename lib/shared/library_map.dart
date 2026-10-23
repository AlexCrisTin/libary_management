import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

const _mapBrown = Color(0xFF8F6264);
const _mapBrownDark = Color(0xFF73383A);
const _mapBeige = Color(0xFFDFBDA5);
const _mapCream = Color(0xFFF6EFE9);
const _mapGreen = Color(0xFF69B58E);

class LibraryMapPage extends StatefulWidget {
  const LibraryMapPage({super.key});

  @override
  State<LibraryMapPage> createState() => _LibraryMapPageState();
}

class _LibraryMapPageState extends State<LibraryMapPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _shelves = const [];
  bool _loading = true;
  bool _searching = false;
  bool _savingShelf = false;
  String? _error;
  int? _selectedFloor;
  String? _selectedLocationId;
  String? _selectedBookTitle;

  bool get _canManageShelves {
    final role = AppSession.user?['role']?.toString();
    return role == 'librarian' || role == 'admin';
  }

  List<int> get _floors {
    final values =
        _shelves
            .map((shelf) => int.tryParse('${shelf['floor']}'))
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _floorShelves {
    final items = _shelves.where((shelf) {
      return int.tryParse('${shelf['floor']}') == _selectedFloor;
    }).toList();
    items.sort((a, b) {
      final section = apiText(a['section']).compareTo(apiText(b['section']));
      if (section != 0) return section;
      final shelf = apiText(a['shelf']).compareTo(apiText(b['shelf']));
      if (shelf != 0) return shelf;
      return apiText(a['position']).compareTo(apiText(b['position']));
    });
    return items;
  }

  Map<String, dynamic>? get _selectedShelf {
    final id = _selectedLocationId;
    if (id == null) return null;
    for (final shelf in _shelves) {
      if (apiText(shelf['location_id'], fallback: '') == id) return shelf;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadShelves();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShelves() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shelves = apiList(await ApiClient.get('/shelves'));
      final floors =
          shelves
              .map((shelf) => int.tryParse('${shelf['floor']}'))
              .whereType<int>()
              .toList()
            ..sort();
      if (!mounted) return;
      setState(() {
        _shelves = shelves;
        if (_selectedFloor == null || !floors.contains(_selectedFloor)) {
          _selectedFloor = floors.isEmpty ? null : floors.first;
        }
        if (_selectedLocationId != null &&
            !shelves.any(
              (shelf) =>
                  apiText(shelf['location_id'], fallback: '') ==
                  _selectedLocationId,
            )) {
          _selectedLocationId = null;
          _selectedBookTitle = null;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchBook() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      final response = apiMap(
        await ApiClient.get(
          '/books',
          query: {'keyword': keyword, 'page': 1, 'limit': 20},
        ),
      );
      final books = apiList(response['items']);
      if (!mounted) return;
      if (books.isEmpty) {
        _showMessage('Không tìm thấy sách phù hợp.');
        return;
      }
      final selected = await _chooseBook(books);
      if (selected == null || !mounted) return;
      await _focusBook(selected);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<Map<String, dynamic>?> _chooseBook(List<Map<String, dynamic>> books) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _mapCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: math.min(MediaQuery.sizeOf(context).height * .67, 560),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 2, 20, 15),
                child: Text(
                  'Chọn sách cần tìm vị trí',
                  style: TextStyle(
                    color: _mapBrownDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final book = books[index];
                    final available =
                        int.tryParse('${book['available_copies']}') ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: available > 0
                            ? _mapGreen.withValues(alpha: .18)
                            : _mapBeige.withValues(alpha: .45),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: available > 0 ? _mapGreen : _mapBrown,
                        ),
                      ),
                      title: Text(
                        apiText(book['title']),
                        style: const TextStyle(
                          color: _mapBrownDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'ISBN: ${apiText(book['isbn'])} • '
                        '${available > 0 ? '$available bản có sẵn' : 'Hiện không có sẵn'}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(sheetContext, book),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _focusBook(Map<String, dynamic> book) async {
    final id = apiText(book['bib_id'], fallback: '');
    if (id.isEmpty) return;
    final detail = apiMap(await ApiClient.get('/books/$id'));
    final copies = apiList(detail['copies']);
    final located = copies.where((copy) {
      return apiText(copy['location_id'], fallback: '').isNotEmpty;
    }).toList();
    if (located.isEmpty) {
      _showMessage('Sách này chưa được cập nhật vị trí kệ.');
      return;
    }

    final unique = <String, Map<String, dynamic>>{};
    for (final copy in located) {
      final locationId = apiText(copy['location_id'], fallback: '');
      final existing = unique[locationId];
      final copyAvailable = apiText(copy['status']) == 'available';
      final existingAvailable =
          existing != null && apiText(existing['status']) == 'available';
      if (existing == null || (copyAvailable && !existingAvailable)) {
        unique[locationId] = copy;
      }
    }
    final locations = unique.values.toList()
      ..sort((a, b) {
        final aAvailable = apiText(a['status']) == 'available' ? 0 : 1;
        final bAvailable = apiText(b['status']) == 'available' ? 0 : 1;
        return aAvailable.compareTo(bAvailable);
      });

    Map<String, dynamic>? selected;
    if (locations.length == 1) {
      selected = locations.first;
    } else {
      selected = await _chooseLocation(locations);
    }
    if (selected == null || !mounted) return;
    _selectLocation(
      apiText(selected['location_id'], fallback: ''),
      bookTitle: apiText(detail['title']),
    );
  }

  Future<Map<String, dynamic>?> _chooseLocation(
    List<Map<String, dynamic>> locations,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      backgroundColor: _mapCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn vị trí cần xem',
                style: TextStyle(
                  color: _mapBrownDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...locations.map((copy) {
                final available = apiText(copy['status']) == 'available';
                return ListTile(
                  leading: Icon(
                    Icons.location_on_rounded,
                    color: available ? _mapGreen : _mapBrown,
                  ),
                  title: Text(
                    _locationLabel(copy),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    available ? 'Có bản sẵn trên kệ' : 'Bản hiện chưa có sẵn',
                  ),
                  onTap: () => Navigator.pop(sheetContext, copy),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLocation(String locationId, {String? bookTitle}) {
    if (locationId.isEmpty) return;
    Map<String, dynamic>? shelf;
    for (final item in _shelves) {
      if (apiText(item['location_id'], fallback: '') == locationId) {
        shelf = item;
        break;
      }
    }
    if (shelf == null) {
      _showMessage('Không tìm thấy vị trí này trên sơ đồ.');
      return;
    }
    setState(() {
      _selectedLocationId = locationId;
      _selectedFloor = int.tryParse('${shelf?['floor']}');
      _selectedBookTitle = bookTitle;
    });
  }

  Future<void> _openShelfForm({Map<String, dynamic>? shelf}) async {
    if (!_canManageShelves || _savingShelf) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _mapCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ShelfFormSheet(
        existingShelf: shelf,
        initialFloor: _selectedFloor ?? 1,
      ),
    );
    if (result == null || !mounted) return;
    await _saveShelf(result, existingShelf: shelf);
  }

  Future<void> _saveShelf(
    Map<String, dynamic> payload, {
    Map<String, dynamic>? existingShelf,
  }) async {
    final existingId = existingShelf == null
        ? ''
        : apiText(existingShelf['location_id'], fallback: '');
    final duplicate = _shelves.any((item) {
      final itemId = apiText(item['location_id'], fallback: '');
      if (itemId == existingId) return false;
      return int.tryParse('${item['floor']}') == payload['floor'] &&
          apiText(item['section'], fallback: '').toUpperCase() ==
              payload['section'] &&
          apiText(item['shelf'], fallback: '').toUpperCase() ==
              payload['shelf'] &&
          apiText(item['position'], fallback: '').toUpperCase() ==
              (payload['position']?.toString().toUpperCase() ?? '');
    });
    if (duplicate) {
      _showMessage('Vị trí tầng, khu, kệ và ngăn này đã tồn tại.');
      return;
    }

    setState(() => _savingShelf = true);
    try {
      String locationId = existingId;
      if (existingShelf == null) {
        final created = apiMap(await ApiClient.post('/shelves', body: payload));
        locationId = apiText(created['location_id'], fallback: '');
      } else {
        await ApiClient.put('/shelves/$existingId', body: payload);
      }
      await _loadShelves();
      if (!mounted) return;
      if (locationId.isNotEmpty) _selectLocation(locationId);
      _showMessage(
        existingShelf == null
            ? 'Đã thêm vị trí kệ mới.'
            : 'Đã cập nhật vị trí kệ.',
      );
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _savingShelf = false);
    }
  }

  Future<void> _confirmDeleteShelf(Map<String, dynamic> shelf) async {
    if (!_canManageShelves || _savingShelf) return;
    final currentBooks = int.tryParse('${shelf['current_books_count']}') ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa vị trí kệ?'),
        content: Text(
          '${_locationLabel(shelf)} sẽ bị xóa.'
          '${currentBooks > 0 ? '\n\n$currentBooks bản sao trên kệ sẽ chuyển sang trạng thái chưa xếp kệ.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC95F63),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa kệ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final id = apiText(shelf['location_id'], fallback: '');
    if (id.isEmpty) return;
    setState(() => _savingShelf = true);
    try {
      await ApiClient.delete('/shelves/$id');
      if (_selectedLocationId == id) {
        _selectedLocationId = null;
        _selectedBookTitle = null;
      }
      await _loadShelves();
      _showMessage('Đã xóa vị trí kệ.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _savingShelf = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedShelf = _selectedShelf;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 17),
              decoration: const BoxDecoration(
                color: _mapBeige,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Sơ đồ thư viện',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _mapBrown,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: _loading ? null : _loadShelves,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ApiStateView(
                loading: _loading,
                error: _error,
                isEmpty: _shelves.isEmpty && !_canManageShelves,
                onRetry: _loadShelves,
                emptyMessage: 'Chưa có dữ liệu vị trí kệ sách',
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchBook(),
                            decoration: InputDecoration(
                              hintText: 'Tìm tên sách hoặc ISBN...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: _mapCream,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: _mapBrown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _searching ? null : _searchBook,
                            child: _searching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.location_searching_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    if (_canManageShelves) ...[
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: _mapCream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _mapBeige),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quản lý vị trí kệ',
                                    style: TextStyle(
                                      color: _mapBrownDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Chạm một kệ để sửa hoặc xóa',
                                    style: TextStyle(
                                      color: _mapBrown,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _mapBrown,
                              ),
                              onPressed: _savingShelf
                                  ? null
                                  : () => _openShelfForm(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Thêm kệ'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_floors.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _floors.map((floor) {
                            final selected = floor == _selectedFloor;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('Tầng $floor'),
                                selected: selected,
                                selectedColor: _mapBrown,
                                backgroundColor: _mapCream,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : _mapBrownDark,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) => setState(() {
                                  _selectedFloor = floor;
                                  final selectedShelfFloor = int.tryParse(
                                    '${_selectedShelf?['floor']}',
                                  );
                                  if (selectedShelfFloor != floor) {
                                    _selectedLocationId = null;
                                    _selectedBookTitle = null;
                                  }
                                }),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _FloorPlanCard(
                      shelves: _floorShelves,
                      selectedLocationId: _selectedLocationId,
                      onShelfTap: (shelf) => setState(() {
                        _selectedLocationId = apiText(
                          shelf['location_id'],
                          fallback: '',
                        );
                        _selectedBookTitle = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (selectedShelf != null)
                      _SelectedShelfCard(
                        shelf: selectedShelf,
                        bookTitle: _selectedBookTitle,
                        onEdit: _canManageShelves && !_savingShelf
                            ? () => _openShelfForm(shelf: selectedShelf)
                            : null,
                        onDelete: _canManageShelves && !_savingShelf
                            ? () => _confirmDeleteShelf(selectedShelf)
                            : null,
                      )
                    else
                      const _MapHintCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelfFormSheet extends StatefulWidget {
  const _ShelfFormSheet({this.existingShelf, required this.initialFloor});

  final Map<String, dynamic>? existingShelf;
  final int initialFloor;

  @override
  State<_ShelfFormSheet> createState() => _ShelfFormSheetState();
}

class _ShelfFormSheetState extends State<_ShelfFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _floorController;
  late final TextEditingController _sectionController;
  late final TextEditingController _shelfController;
  late final TextEditingController _positionController;
  late final TextEditingController _capacityController;
  late final TextEditingController _ddcController;

  bool get _editing => widget.existingShelf != null;

  int get _currentBooks => _editing
      ? int.tryParse('${widget.existingShelf!['current_books_count']}') ?? 0
      : 0;

  @override
  void initState() {
    super.initState();
    final shelf = widget.existingShelf;
    _floorController = TextEditingController(
      text: shelf == null
          ? '${widget.initialFloor}'
          : '${shelf['floor'] ?? ''}',
    );
    _sectionController = TextEditingController(
      text: shelf == null ? '' : apiText(shelf['section'], fallback: ''),
    );
    _shelfController = TextEditingController(
      text: shelf == null ? '' : apiText(shelf['shelf'], fallback: ''),
    );
    _positionController = TextEditingController(
      text: shelf == null ? '' : apiText(shelf['position'], fallback: ''),
    );
    _capacityController = TextEditingController(
      text: shelf == null ? '50' : '${shelf['capacity'] ?? 50}',
    );
    _ddcController = TextEditingController(
      text: shelf == null ? '' : apiText(shelf['ddc_range'], fallback: ''),
    );
  }

  @override
  void dispose() {
    _floorController.dispose();
    _sectionController.dispose();
    _shelfController.dispose();
    _positionController.dispose();
    _capacityController.dispose();
    _ddcController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final position = _positionController.text.trim();
    final ddcRange = _ddcController.text.trim();
    Navigator.pop(context, <String, dynamic>{
      'floor': int.parse(_floorController.text.trim()),
      'section': _sectionController.text.trim().toUpperCase(),
      'shelf': _shelfController.text.trim().toUpperCase(),
      'position': position.isEmpty ? null : position,
      'capacity': int.parse(_capacityController.text.trim()),
      'ddc_range': ddcRange.isEmpty ? null : ddcRange,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editing ? 'Chỉnh sửa vị trí kệ' : 'Thêm vị trí kệ',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _mapBrownDark,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _shelfInputDecoration(
                        label: 'Tầng',
                        hint: 'Ví dụ: 1',
                        icon: Icons.layers_outlined,
                      ),
                      validator: (value) {
                        final floor = int.tryParse(value?.trim() ?? '');
                        if (floor == null || floor < 1) {
                          return 'Nhập tầng hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sectionController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: _shelfInputDecoration(
                        label: 'Khu',
                        hint: 'Ví dụ: A',
                        icon: Icons.grid_view_rounded,
                      ),
                      validator: (value) => _requiredShelfValue(
                        value,
                        fieldName: 'khu vực',
                        maxLength: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _shelfController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: _shelfInputDecoration(
                        label: 'Mã kệ',
                        hint: 'Ví dụ: A01',
                        icon: Icons.view_column_outlined,
                      ),
                      validator: (value) => _requiredShelfValue(
                        value,
                        fieldName: 'mã kệ',
                        maxLength: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _positionController,
                      textInputAction: TextInputAction.next,
                      decoration: _shelfInputDecoration(
                        label: 'Ngăn',
                        hint: 'Không bắt buộc',
                        icon: Icons.table_rows_outlined,
                      ),
                      validator: (value) {
                        if ((value?.trim().length ?? 0) > 10) {
                          return 'Tối đa 10 ký tự';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _shelfInputDecoration(
                  label: 'Sức chứa tối đa',
                  hint: 'Ví dụ: 50',
                  icon: Icons.inventory_2_outlined,
                  helper: _editing && _currentBooks > 0
                      ? 'Kệ hiện có $_currentBooks cuốn sách'
                      : null,
                ),
                validator: (value) {
                  final capacity = int.tryParse(value?.trim() ?? '');
                  if (capacity == null || capacity < 1) {
                    return 'Sức chứa phải lớn hơn 0';
                  }
                  if (capacity < _currentBooks) {
                    return 'Không thể nhỏ hơn số sách hiện có ($_currentBooks)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ddcController,
                textInputAction: TextInputAction.done,
                decoration: _shelfInputDecoration(
                  label: 'Dải phân loại DDC',
                  hint: 'Ví dụ: 000-099',
                  icon: Icons.numbers_rounded,
                ),
                validator: (value) {
                  if ((value?.trim().length ?? 0) > 50) {
                    return 'Tối đa 50 ký tự';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _mapBrown,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                icon: Icon(_editing ? Icons.save_rounded : Icons.add_rounded),
                label: Text(_editing ? 'Lưu thay đổi' : 'Thêm kệ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloorPlanCard extends StatelessWidget {
  const _FloorPlanCard({
    required this.shelves,
    required this.selectedLocationId,
    required this.onShelfTap,
  });

  final List<Map<String, dynamic>> shelves;
  final String? selectedLocationId;
  final ValueChanged<Map<String, dynamic>> onShelfTap;

  @override
  Widget build(BuildContext context) {
    final rows = math.max(1, (shelves.length / 4).ceil());
    final canvasHeight = math.max(520.0, 230 + rows * 82.0);
    const canvasWidth = 760.0;
    final canvasSize = Size(canvasWidth, canvasHeight);
    final layouts = _shelfLayouts(shelves, canvasSize);

    return Container(
      height: math.min(MediaQuery.sizeOf(context).height * .48, 520),
      decoration: BoxDecoration(
        color: _mapCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _mapBeige, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        minScale: .55,
        maxScale: 3,
        boundaryMargin: const EdgeInsets.all(80),
        constrained: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            for (final layout in layouts.reversed) {
              if (layout.rect.contains(details.localPosition)) {
                onShelfTap(layout.shelf);
                return;
              }
            }
          },
          child: CustomPaint(
            size: canvasSize,
            painter: _LibraryMapPainter(
              shelves: shelves,
              selectedLocationId: selectedLocationId,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfLayout {
  const _ShelfLayout(this.shelf, this.rect);

  final Map<String, dynamic> shelf;
  final Rect rect;
}

List<_ShelfLayout> _shelfLayouts(
  List<Map<String, dynamic>> shelves,
  Size size,
) {
  const columns = 4;
  const horizontalPadding = 46.0;
  const top = 155.0;
  const shelfWidth = 125.0;
  const shelfHeight = 48.0;
  const rowHeight = 82.0;
  final cellWidth = (size.width - horizontalPadding * 2) / columns;

  return List.generate(shelves.length, (index) {
    final column = index % columns;
    final row = index ~/ columns;
    final left =
        horizontalPadding + column * cellWidth + (cellWidth - shelfWidth) / 2;
    final rect = Rect.fromLTWH(
      left,
      top + row * rowHeight,
      shelfWidth,
      shelfHeight,
    );
    return _ShelfLayout(shelves[index], rect);
  });
}

class _LibraryMapPainter extends CustomPainter {
  const _LibraryMapPainter({
    required this.shelves,
    required this.selectedLocationId,
  });

  final List<Map<String, dynamic>> shelves;
  final String? selectedLocationId;

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..color = _mapBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final room = RRect.fromRectAndRadius(
      Rect.fromLTWH(22, 22, size.width - 44, size.height - 44),
      const Radius.circular(20),
    );
    canvas.drawRRect(room, Paint()..color = Colors.white);
    canvas.drawRRect(room, wall);

    _drawBox(
      canvas,
      const Rect.fromLTWH(48, 53, 210, 68),
      'QUẦY THỦ THƯ',
      _mapBeige,
    );
    _drawBox(
      canvas,
      Rect.fromLTWH(size.width - 270, 53, 220, 68),
      'KHU ĐỌC SÁCH',
      const Color(0xFFE9E1D9),
    );

    for (final layout in _shelfLayouts(shelves, size)) {
      final shelf = layout.shelf;
      final id = apiText(shelf['location_id'], fallback: '');
      final selected = id == selectedLocationId;
      final section = apiText(shelf['section'], fallback: '?');
      final shelfCode = apiText(shelf['shelf'], fallback: '?');
      final color = selected ? const Color(0xFFD37C7E) : _sectionColor(section);
      canvas.drawRRect(
        RRect.fromRectAndRadius(layout.rect, const Radius.circular(8)),
        Paint()..color = color,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(layout.rect, const Radius.circular(8)),
        Paint()
          ..color = selected ? _mapBrownDark : _mapBrown
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 4 : 2,
      );
      _drawCenteredText(
        canvas,
        layout.rect,
        'Khu $section • Kệ $shelfCode',
        selected ? Colors.white : _mapBrownDark,
        14,
      );
    }

    final entrance = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 39),
      width: 160,
      height: 34,
    );
    canvas.drawRect(entrance, Paint()..color = _mapCream);
    _drawCenteredText(
      canvas,
      entrance,
      'LỐI VÀO',
      _mapBrownDark,
      15,
      bold: true,
    );

    if (shelves.isEmpty) {
      _drawCenteredText(
        canvas,
        Rect.fromLTWH(80, 190, size.width - 160, 120),
        'Tầng này chưa có dữ liệu kệ',
        _mapBrown,
        18,
      );
    }
  }

  void _drawBox(Canvas canvas, Rect rect, String text, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = color,
    );
    _drawCenteredText(canvas, rect, text, _mapBrownDark, 15, bold: true);
  }

  void _drawCenteredText(
    Canvas canvas,
    Rect rect,
    String text,
    Color color,
    double fontSize, {
    bool bold = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - 8);
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  Color _sectionColor(String section) {
    const colors = [
      Color(0xFFE9D2C3),
      Color(0xFFDDE6D7),
      Color(0xFFD9E3EC),
      Color(0xFFE7DBE8),
      Color(0xFFF0DFC2),
    ];
    return colors[section.hashCode.abs() % colors.length];
  }

  @override
  bool shouldRepaint(covariant _LibraryMapPainter oldDelegate) {
    return oldDelegate.shelves != shelves ||
        oldDelegate.selectedLocationId != selectedLocationId;
  }
}

class _SelectedShelfCard extends StatelessWidget {
  const _SelectedShelfCard({
    required this.shelf,
    this.bookTitle,
    this.onEdit,
    this.onDelete,
  });

  final Map<String, dynamic> shelf;
  final String? bookTitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse('${shelf['current_books_count']}') ?? 0;
    final capacity = int.tryParse('${shelf['capacity']}') ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mapBeige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD37C7E),
                child: Icon(Icons.location_on_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bookTitle != null && bookTitle!.isNotEmpty) ...[
                      Text(
                        bookTitle!,
                        style: const TextStyle(
                          color: _mapBrownDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      _locationLabel(shelf),
                      style: const TextStyle(
                        color: _mapBrownDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Sức chứa: $current/$capacity cuốn'
                      '${apiText(shelf['ddc_range'], fallback: '').isEmpty ? '' : ' • DDC ${apiText(shelf['ddc_range'])}'}',
                      style: const TextStyle(color: _mapBrown),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onEdit != null || onDelete != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _mapBrownDark,
                        side: const BorderSide(color: _mapBeige),
                      ),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 10),
                if (onDelete != null)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC95F63),
                      ),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Xóa kệ'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MapHintCard extends StatelessWidget {
  const _MapHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _mapCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, color: _mapBrown),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tìm một cuốn sách hoặc chạm trực tiếp vào kệ để xem vị trí. '
              'Bạn có thể kéo và phóng to sơ đồ.',
              style: TextStyle(color: _mapBrownDark, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

String _locationLabel(Map<String, dynamic> value) {
  final floor = apiText(value['floor'], fallback: '?');
  final section = apiText(value['section'], fallback: '?');
  final shelf = apiText(value['shelf'], fallback: '?');
  final position = apiText(value['position'], fallback: '');
  return 'Tầng $floor • Khu $section • Kệ $shelf'
      '${position.isEmpty ? '' : ' • Ngăn $position'}';
}

InputDecoration _shelfInputDecoration({
  required String label,
  required String hint,
  required IconData icon,
  String? helper,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    prefixIcon: Icon(icon, color: _mapBrown),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _mapBeige),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _mapBrown, width: 2),
    ),
  );
}

String? _requiredShelfValue(
  String? value, {
  required String fieldName,
  required int maxLength,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Nhập $fieldName';
  if (text.length > maxLength) return 'Tối đa $maxLength ký tự';
  return null;
}
