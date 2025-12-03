/// Annotations and classes for generating filterable and sortable models.
/// 
/// This library provides annotations and supporting classes to enable
/// automatic generation of filter and sort functionality for Dart models
/// using code generation via `filterable_generator` and `build_runner`.
/// 
/// ## Usage
/// 
/// 1. Add the annotation to your model class:
/// ```dart
/// import 'package:filterable_annotation/filterable_annotation.dart';
/// 
/// @Filterable()
/// class Product {
///   @FilterableField(label: 'Name', comparatorsType: String)
///   final String name;
///   
///   @FilterableField(label: 'Price', comparatorsType: double)
///   final double price;
///   
///   Product({required this.name, required this.price});
/// }
/// ```
/// 
/// 2. Run code generation:
/// ```bash
/// dart run build_runner build
/// ```
/// 
/// 3. Use the generated extension:
/// ```dart
/// final criteria = FilterCriteria(field: 'price', comparator: '>=', value: 100.0);
/// final predicate = ProductFilterExtension.buildPredicate(criteria);
/// final filteredProducts = products.where(predicate).toList();
/// ```
library;

export 'filterable.dart';
export 'filter_criteria.dart';
export 'sort_criteria.dart';
