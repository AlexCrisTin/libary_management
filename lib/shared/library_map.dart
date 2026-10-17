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
  String? _error;
  int? _selectedFloor;
  String? _selectedLocationId;
  String? _selectedBookTitle;

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
                isEmpty: _shelves.isEmpty,
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
  const _SelectedShelfCard({required this.shelf, this.bookTitle});

  final Map<String, dynamic> shelf;
  final String? bookTitle;

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
      child: Row(
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
