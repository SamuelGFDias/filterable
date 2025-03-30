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