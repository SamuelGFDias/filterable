import 'package:example/core/providers/filter_criteria/filter_criteria.notifier.dart';
import 'package:filterable_annotation/filter_criteria.dart';
import 'package:filterable_annotation/filterable.dart';
import 'package:filterable_annotation/sort_criteria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class FilterSortContent<T> extends ConsumerStatefulWidget {
  final List<FilterableFieldInfo> fields;

  const FilterSortContent({super.key, required this.fields});

  @override
  ConsumerState<FilterSortContent<T>> createState() =>
      FilterSortContentState<T>();
}

class FilterSortContentState<T> extends ConsumerState<FilterSortContent<T>> {
  final List<FilterCriteria> filters = [];
  final List<SortCriteria> sorts = [];

  List<FilterCriteria> get currentFilters => filters;

  List<SortCriteria> get currentSorts => sorts;

  @override
  void initState() {
    final state = ref.read(filterCriteriaNotifierProvider);
    filters.addAll(state.filters);
    sorts.addAll(state.sorts);
    super.initState();
  }

  dynamic parseValue(String value, Type type) {
    if (type == int) return int.tryParse(value);
    if (type == double) return double.tryParse(value);
    if (type == DateTime) return DateTime.tryParse(value);
    return value;
  }

  Future<SortCriteria?> showAddSorterDialog() async {
    FilterableFieldInfo? selectedField;
    bool ascending = true;

    return showDialog<SortCriteria>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Novo Classificador'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<FilterableFieldInfo>(
                      hint: const Text('Selecione o campo'),
                      value: selectedField,
                      items:
                          widget.fields.map((field) {
                            return DropdownMenuItem(
                              value: field,
                              child: Text(field.label),
                            );
                          }).toList(),
                      onChanged: (field) {
                        setState(() => selectedField = field);
                      },
                    ),
                    if (selectedField != null)
                      DropdownButton<String>(
                        value: ascending ? "Crescente" : "Decrescente",
                        items: const [
                          DropdownMenuItem(
                            value: "Crescente",
                            child: Text("Crescente"),
                          ),
                          DropdownMenuItem(
                            value: "Decrescente",
                            child: Text("Decrescente"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => ascending = value == "Crescente");
                        },
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedField != null) {
                        Navigator.pop(
                          context,
                          SortCriteria(
                            field: selectedField!.field,
                            ascending: ascending,
                          ),
                        );
                      }
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<FilterCriteria?> showAddFilterDialog() async {
    FilterableFieldInfo? selectedField;
    String? selectedComparator;
    dynamic enteredValue;

    return showDialog<FilterCriteria>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Novo Filtro'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<FilterableFieldInfo>(
                      hint: const Text('Selecione o campo'),
                      value: selectedField,
                      items:
                          widget.fields.map((field) {
                            return DropdownMenuItem(
                              value: field,
                              child: Text(field.label),
                            );
                          }).toList(),
                      onChanged: (field) {
                        setState(() {
                          selectedField = field;
                          selectedComparator = null;
                        });
                      },
                    ),
                    if (selectedField != null)
                      DropdownButton<String>(
                        hint: const Text('Operador'),
                        value: selectedComparator,
                        items:
                            selectedField!.comparators.map((op) {
                              return DropdownMenuItem(
                                value: op,
                                child: Text(op),
                              );
                            }).toList(),
                        onChanged:
                            (value) =>
                                setState(() => selectedComparator = value),
                      ),
                    if (selectedComparator != null)
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Valor para ${selectedField!.label}',
                        ),
                        onChanged: (value) {
                          enteredValue = parseValue(value, selectedField!.type);
                        },
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedField != null && selectedComparator != null) {
                        Navigator.pop(
                          context,
                          FilterCriteria(
                            field: selectedField!.field,
                            comparator: selectedComparator!,
                            value: enteredValue,
                          ),
                        );
                      }
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget buildActiveFilters() {
    return Wrap(
      spacing: 8.0,
      children:
          filters.map((filter) {
            return Chip(
              label: Text(
                '${filter.field} ${filter.comparator} ${filter.value}',
              ),
              onDeleted:
                  () => setState(() {
                    filters.remove(filter);
                  }),
            );
          }).toList(),
    );
  }

  Widget buildActiveSorts() {
    return Wrap(
      spacing: 8.0,
      children:
          sorts.map((sort) {
            return Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sort.field),
                  Icon(
                    sort.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ],
              ),
              onDeleted:
                  () => setState(() {
                    sorts.remove(sort);
                  }),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.filter_alt),
              label: const Text('Adicionar Filtro'),
              onPressed: () async {
                final filter = await showAddFilterDialog();
                if (filter != null) {
                  setState(() => filters.add(filter));
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.filter_list_sharp),
              label: const Text('Adicionar Classificador'),
              onPressed: () async {
                final sort = await showAddSorterDialog();
                if (sort != null) {
                  setState(() => sorts.add(sort));
                }
              },
            ),
            buildActiveFilters(),
            buildActiveSorts(),
          ],
        ),
      ),
    );
  }
}
