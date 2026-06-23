import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/stock_filter.dart';

/// A collapsible card for editing stock filter criteria on the strategy edit page.
class StockFilterEditCard extends StatefulWidget {
  final StockFilter? initialFilter;
  final ValueChanged<StockFilter?> onChanged;

  const StockFilterEditCard({
    super.key,
    this.initialFilter,
    required this.onChanged,
  });

  @override
  State<StockFilterEditCard> createState() => _StockFilterEditCardState();
}

class _StockFilterEditCardState extends State<StockFilterEditCard> {
  bool _isExpanded = false;

  // Price range controllers
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  // Change range controllers
  final _minChangeCtrl = TextEditingController();
  final _maxChangeCtrl = TextEditingController();

  // Turnover range controllers
  final _minTurnoverCtrl = TextEditingController();
  final _maxTurnoverCtrl = TextEditingController();

  // Board selection
  final _selectedBoards = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFromFilter(widget.initialFilter);
    _isExpanded = widget.initialFilter != null && widget.initialFilter!.isActive;
  }

  void _loadFromFilter(StockFilter? f) {
    if (f == null) return;
    if (f.minPrice != null) _minPriceCtrl.text = f.minPrice!.toStringAsFixed(0);
    if (f.maxPrice != null) _maxPriceCtrl.text = f.maxPrice!.toStringAsFixed(0);
    if (f.changeRange != null) {
      _minChangeCtrl.text = f.changeRange!.$1.toStringAsFixed(1);
      _maxChangeCtrl.text = f.changeRange!.$2.toStringAsFixed(1);
    }
    if (f.turnoverRange != null) {
      _minTurnoverCtrl.text = f.turnoverRange!.$1.toStringAsFixed(1);
      _maxTurnoverCtrl.text = f.turnoverRange!.$2.toStringAsFixed(1);
    }
    if (f.boards != null) _selectedBoards.addAll(f.boards!);
  }

  void _notifyChanged() {
    final hasPrice = _minPriceCtrl.text.isNotEmpty || _maxPriceCtrl.text.isNotEmpty;
    final hasChange = _minChangeCtrl.text.isNotEmpty || _maxChangeCtrl.text.isNotEmpty;
    final hasTurnover = _minTurnoverCtrl.text.isNotEmpty || _maxTurnoverCtrl.text.isNotEmpty;
    final hasBoards = _selectedBoards.isNotEmpty;

    if (!hasPrice && !hasChange && !hasTurnover && !hasBoards) {
      widget.onChanged(null);
      return;
    }

    final filter = StockFilter(
      minPrice: hasPrice ? double.tryParse(_minPriceCtrl.text) : null,
      maxPrice: hasPrice ? double.tryParse(_maxPriceCtrl.text) : null,
      changeRange: hasChange
          ? (double.tryParse(_minChangeCtrl.text) ?? -100.0,
             double.tryParse(_maxChangeCtrl.text) ?? 100.0)
          : null,
      turnoverRange: hasTurnover
          ? (double.tryParse(_minTurnoverCtrl.text) ?? 0.0,
             double.tryParse(_maxTurnoverCtrl.text) ?? 100.0)
          : null,
      boards: hasBoards ? _selectedBoards.toList() : null,
    );
    widget.onChanged(filter);
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minChangeCtrl.dispose();
    _maxChangeCtrl.dispose();
    _minTurnoverCtrl.dispose();
    _maxTurnoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeDesc = widget.initialFilter?.description ?? '全市场';
    final isActive = widget.initialFilter != null && widget.initialFilter!.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20, color: isActive ? StockColors.brand : context.sc.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('股票筛选', style: AppTextStyles.h2),
                        const SizedBox(height: 2),
                        Text(
                          isActive ? activeDesc : '不限制（全市场扫描）',
                          style: AppTextStyles.caption.copyWith(color: context.sc.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    TextButton(
                      onPressed: () {
                        _minPriceCtrl.clear();
                        _maxPriceCtrl.clear();
                        _minChangeCtrl.clear();
                        _maxChangeCtrl.clear();
                        _minTurnoverCtrl.clear();
                        _maxTurnoverCtrl.clear();
                        _selectedBoards.clear();
                        _notifyChanged();
                      },
                      child: const Text('清除', style: TextStyle(fontSize: 12)),
                    ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: context.sc.textTertiary),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price range
                  _buildRangeRow('价格范围（元）', _minPriceCtrl, _maxPriceCtrl, '最低', '最高'),
                  const SizedBox(height: 12),

                  // Change range
                  _buildRangeRow('涨跌幅范围（%）', _minChangeCtrl, _maxChangeCtrl, '最低', '最高'),
                  const SizedBox(height: 12),

                  // Turnover range
                  _buildRangeRow('换手率范围（%）', _minTurnoverCtrl, _maxTurnoverCtrl, '最低', '最高'),
                  const SizedBox(height: 16),

                  // Board selection
                  Text('交易板块', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildBoardChip('main', '主板'),
                      _buildBoardChip('gem', '创业板'),
                      _buildBoardChip('star', '科创板'),
                      _buildBoardChip('bse', '北交所'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeRow(
    String label,
    TextEditingController minCtrl,
    TextEditingController maxCtrl,
    String minHint,
    String maxHint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minCtrl,
                decoration: InputDecoration(
                  hintText: minHint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notifyChanged(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('~', style: TextStyle(color: context.sc.textTertiary)),
            ),
            Expanded(
              child: TextField(
                controller: maxCtrl,
                decoration: InputDecoration(
                  hintText: maxHint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notifyChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoardChip(String value, String label) {
    final selected = _selectedBoards.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (on) {
        setState(() {
          if (on) {
            _selectedBoards.add(value);
          } else {
            _selectedBoards.remove(value);
          }
        });
        _notifyChanged();
      },
    );
  }
}
