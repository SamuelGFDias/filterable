class Filterable {
  const Filterable();
}

class FilterableField {
  final String label;
  final Type comparatorsType;
  final List<String>? comparators;
  final Function? customCompare;

  const FilterableField({
    required this.label,
    required this.comparatorsType,
    this.comparators,
    this.customCompare,
  });
}

class FilterableFieldInfo {
  final String field;
  final String label;
  final Type type;
  final List<String> comparators;

  const FilterableFieldInfo({
    required this.field,
    required this.label,
    required this.type,
    required this.comparators,
  });
}
