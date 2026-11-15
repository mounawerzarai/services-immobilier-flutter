import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../listings/format.dart';
import 'filters.dart';

/// Ouvre la feuille de filtres. Renvoie les nouveaux filtres, ou null si on ferme sans appliquer.
Future<Filters?> showFilterSheet(BuildContext context, Filters current) {
  return showModalBottomSheet<Filters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final Filters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  // Brouillon : copie modifiable, qui ne devient le filtre actif qu'au clic sur « Appliquer ».
  String? _transactionType;
  String? _propertyType;
  int? _minRooms;
  late final TextEditingController _city;
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _transactionType = f.transactionType;
    _propertyType = f.propertyType;
    _minRooms = f.minRooms;
    _city = TextEditingController(text: f.city);
    _minPrice = TextEditingController(text: f.minPrice?.toString() ?? '');
    _maxPrice = TextEditingController(text: f.maxPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _city.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _transactionType = null;
      _propertyType = null;
      _minRooms = null;
      _city.clear();
      _minPrice.clear();
      _maxPrice.clear();
    });
  }

  void _apply() {
    var min = parsePrice(_minPrice.text);
    var max = parsePrice(_maxPrice.text);
    if (min != null && max != null && min > max) {
      final tmp = min;
      min = max;
      max = tmp;
    }
    Navigator.of(context).pop(
      Filters(
        transactionType: _transactionType,
        propertyType: _propertyType,
        city: _city.text.trim(),
        minPrice: min,
        maxPrice: max,
        minRooms: _minRooms,
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.text,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: const StadiumBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Remonte le contenu quand le clavier est ouvert.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Vente ou location'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Tous', _transactionType == null,
                            () => setState(() => _transactionType = null)),
                        _chip('Vente', _transactionType == 'sale',
                            () => setState(() => _transactionType = 'sale')),
                        _chip('Location', _transactionType == 'rent',
                            () => setState(() => _transactionType = 'rent')),
                      ],
                    ),
                    _label('Type de bien'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Tous', _propertyType == null,
                            () => setState(() => _propertyType = null)),
                        for (final k in kPropertyTypeKeys)
                          _chip(propertyTypeLabel(k), _propertyType == k,
                              () => setState(() => _propertyType = k)),
                      ],
                    ),
                    _label('Ville'),
                    TextField(
                      controller: _city,
                      autocorrect: false,
                      decoration:
                          const InputDecoration(hintText: 'Ex. Tunis, Sousse…'),
                    ),
                    _label('Prix (DT)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPrice,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(hintText: 'Min'),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('–',
                              style: TextStyle(
                                  fontSize: 18, color: AppColors.muted)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxPrice,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(hintText: 'Max'),
                          ),
                        ),
                      ],
                    ),
                    _label('Pièces (minimum)'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Tous', _minRooms == null,
                            () => setState(() => _minRooms = null)),
                        for (final n in kRoomChoices)
                          _chip('$n+', _minRooms == n,
                              () => setState(() => _minRooms = n)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
