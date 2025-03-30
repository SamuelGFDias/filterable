class FilterCriteria<T> {
  final String field;
  final String comparator;
  final T value;

  const FilterCriteria({
    required this.field,
    required this.comparator,
    required this.value,
  });
}