/// Annotation to mark a class as filterable.
/// 
/// Use this annotation on a class to generate filter and sort extension methods.
/// 
/// Example:
/// ```dart
/// @Filterable()
/// class Product {
///   @FilterableField(label: 'Name', comparatorsType: String)
///   final String name;
/// }
/// ```
class Filterable {
  /// Creates a [Filterable] annotation.
  const Filterable();
}

/// Annotation to mark a field as filterable with specific configuration.
/// 
/// This annotation defines how a field can be filtered and sorted.
/// 
/// Parameters:
/// - [label]: The display label for the field in UI.
/// - [comparatorsType]: The type used for comparison operations.
/// - [comparators]: Optional list of allowed comparators. If null, defaults are used.
/// - [customCompare]: Optional custom comparison function.
/// - [isNullable]: Whether the field is nullable (auto-detected if not provided).
/// 
/// Example:
/// ```dart
/// @FilterableField(
///   label: 'Price',
///   comparatorsType: double,
///   comparators: ['==', '!=', '>', '<', '>=', '<='],
/// )
/// final double price;
/// ```
class FilterableField {
  /// The display label for this field.
  final String label;
  
  /// The type used for value comparison.
  final Type comparatorsType;
  
  /// Whether this field can be null.
  final bool isNullable;
  
  /// Optional list of allowed comparators.
  /// If null, default comparators for the type will be used.
  final List<String>? comparators;
  
  /// Optional custom comparison function.
  /// 
  /// The function signature should be: `bool customCompare(FieldType a, ComparatorType b)`
  final Function? customCompare;

  /// Creates a [FilterableField] annotation.
  const FilterableField({
    required this.label,
    required this.comparatorsType,
    this.comparators,
    this.customCompare,
    bool? isNullable,
  }) : isNullable = isNullable ?? false;
}

/// Metadata about a filterable field.
/// 
/// This class contains information about a field's filtering capabilities,
/// generated at build time for use in dynamic UI generation.
class FilterableFieldInfo {
  /// The field name in the class.
  final String field;
  
  /// The display label for the field.
  final String label;
  
  /// The field's type.
  final Type type;
  
  /// Whether the field is nullable.
  final bool isNullable;
  
  /// List of available comparators for this field.
  final List<String> comparators;

  /// Creates a [FilterableFieldInfo] instance.
  const FilterableFieldInfo({
    required this.field,
    required this.label,
    required this.type,
    required this.isNullable,
    required this.comparators,
  });
}
