/// Represents a sort criterion for a specific field.
/// 
/// This class encapsulates the information needed to sort a collection
/// based on a field in ascending or descending order.
/// 
/// Example:
/// ```dart
/// final criteria = SortCriteria(
///   field: 'price',
///   ascending: false, // descending
/// );
/// ```
class SortCriteria {
  /// The name of the field to sort by.
  final String field;
  
  /// Whether to sort in ascending order.
  /// 
  /// If `true`, sorts from lowest to highest (A-Z, 0-9).
  /// If `false`, sorts from highest to lowest (Z-A, 9-0).
  final bool ascending;

  /// Creates a [SortCriteria] instance.
  const SortCriteria({
    required this.field,
    required this.ascending,
  });

  @override
  String toString() {
    return 'SortCriteria(field: $field, ascending: $ascending)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SortCriteria &&
        other.field == field &&
        other.ascending == ascending;
  }

  @override
  int get hashCode => Object.hash(field, ascending);
}
