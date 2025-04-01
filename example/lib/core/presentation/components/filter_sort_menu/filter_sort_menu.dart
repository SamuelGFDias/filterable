import 'package:example/core/providers/filter_criteria/filter_criteria.notifier.dart';
import 'package:filterable_annotation/filterable.dart';
import 'package:flutter/material.dart';

import '../modal_footer.dart';
import '../modal_header.dart';
import 'filter_sort_content.dart';

class FilterSortMenu<T> extends StatelessWidget {
  final void Function(FilterState) onUpdate;
  final List<FilterableFieldInfo> fields;
  final GlobalKey<FilterSortContentState<T>> _mainContentKey = GlobalKey();

  FilterSortMenu({super.key, required this.onUpdate, required this.fields});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showFilterSortModal(context),
      icon: Icon(Icons.filter_alt_outlined),
    );
  }

  _showFilterSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder:
          (context) => LayoutBuilder(
            builder:
                (context, constraints) => SizedBox(
                  height: constraints.maxHeight * 0.6,
                  child: Column(
                    children: [
                      ModalHeader(
                        title: "Filtro Avançado",
                        colors: [Colors.black45, Colors.black87],
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: FilterSortContent<T>(
                          key: _mainContentKey,
                          fields: fields,
                        ),
                      ),
                      ModalFooter(
                        onCancel: () => Navigator.of(context).pop(),
                        onConfirm: () {
                          final filters =
                              _mainContentKey.currentState?.currentFilters ??
                              [];
                          final sorts =
                              _mainContentKey.currentState?.currentSorts ?? [];

                          onUpdate(FilterState(filters: filters, sorts: sorts));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
