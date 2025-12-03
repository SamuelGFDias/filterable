/// Represents a filter criterion for a specific field.
/// 
/// This class encapsulates the information needed to filter a collection
/// based on a field value and comparison operator.
/// 
/// Example:
/// ```dart
/// final criteria = FilterCriteria(
///   field: 'price',
///   comparator: '>=',
///   value: 100.0,
/// );
/// ```
class FilterCriteria<T> {
  /// The name of the field to filter.
  final String field;
  
  /// The comparison operator to use.
  /// 
  /// Common operators: '==', '!=', '>', '<', '>=', '<=', 'contains', 'startsWith', 'endsWith'
  final String comparator;
  
  /// The value to compare against.
  final T value;

  /// Creates a [FilterCriteria] instance.
  const FilterCriteria({
    required this.field,
    required this.comparator,
    required this.value,
  });

  @override
  String toString() {
    return 'FilterCriteria(field: $field, comparator: $comparator, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterCriteria<T> &&
        other.field == field &&
        other.comparator == comparator &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(field, comparator, value);
}