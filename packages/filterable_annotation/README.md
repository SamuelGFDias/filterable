# filterable_annotation

[![pub package](https://img.shields.io/pub/v/filterable_annotation.svg)](https://pub.dev/packages/filterable_annotation)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Annotations for automatic generation of type-safe filter and sort functionality for Dart models. Works seamlessly with `filterable_generator` and `build_runner`.

## ✨ Features

- 🎯 **Type-safe filtering** - Automatic type validation at compile time
- 🔄 **Dynamic sorting** - Sort by any field with ascending/descending order
- 🎨 **UI-ready metadata** - Generate filter UIs dynamically with field information
- 🔧 **Customizable** - Custom comparators and comparison functions
- 📝 **Enum support** - Filter enums by value, index, or name (string)
- 📋 **List support** - Contains, length, and custom comparisons for lists
- ⚡ **Optimized** - Generated code is efficient and minimal

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  filterable_annotation: ^1.0.0

dev_dependencies:
  filterable_generator: ^1.0.0
  build_runner: ^2.4.0
```

## 🚀 Quick Start

### 1. Annotate your model

```dart
import 'package:filterable_annotation/filterable_annotation.dart';

part 'product.filterable.g.dart';

@Filterable()
class Product {
  @FilterableField(label: 'Name', comparatorsType: String)
  final String name;

  @FilterableField(label: 'Price', comparatorsType: double)
  final double price;

  @FilterableField(label: 'In Stock', comparatorsType: bool)
  final bool inStock;

  Product({
    required this.name,
    required this.price,
    required this.inStock,
  });
}
```

### 2. Generate code

```bash
dart run build_runner build
```

### 3. Use the generated extension

```dart
// Filter products
final criteria = FilterCriteria(
  field: 'price',
  comparator: '>=',
  value: 100.0,
);
final predicate = ProductFilterExtension.buildPredicate(criteria);
final expensiveProducts = products.where(predicate).toList();

// Sort products
final sortCriteria = SortCriteria(field: 'price', ascending: false);
final sorter = ProductFilterExtension.buildSorter(sortCriteria);
products.sort(sorter);

// Get field metadata for UI generation
final fields = ProductFilterExtension.filterableFields;
for (final field in fields) {
  print('${field.label}: ${field.comparators}');
}
```

## 📚 API Reference

### `@Filterable()`

Marks a class as filterable. Place this annotation on any class you want to generate filter/sort functionality for.

### `@FilterableField(...)`

Marks a field as filterable with configuration options:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `label` | `String` | ✅ | Display label for UI generation |
| `comparatorsType` | `Type` | ✅ | Type used for comparison operations |
| `comparators` | `List<String>?` | ❌ | Override default comparators |
| `customCompare` | `Function?` | ❌ | Custom comparison function |
| `isNullable` | `bool?` | ❌ | Auto-detected if not provided |

### `FilterCriteria`

Represents a filter condition:

```dart
FilterCriteria(
  field: 'fieldName',      // Field to filter
  comparator: '==',        // Comparison operator
  value: someValue,        // Value to compare against
);
```

### `SortCriteria`

Represents a sort condition:

```dart
SortCriteria(
  field: 'fieldName',      // Field to sort by
  ascending: true,         // Sort direction
);
```

## 🎯 Supported Types & Comparators

### String
`==`, `!=`, `contains`, `startsWith`, `endsWith`

### Numeric (int, double)
`==`, `!=`, `>`, `<`, `>=`, `<=`

### DateTime
`==`, `!=`, `>`, `<`, `>=`, `<=`

### bool
`==`, `!=`

### Enum
`==`, `!=` (supports enum value, int index, or string name)

### List
`contains`, `notContains`, `length==`, `length!=`, `length>`, `length<`, `length>=`, `length<=`

## 🔧 Advanced Usage

### Custom Comparators

```dart
@FilterableField(
  label: 'Status',
  comparatorsType: String,
  comparators: ['==', '!='], // Only allow equality checks
)
final String status;
```

### Custom Comparison Function

```dart
@Filterable()
class Order {
  @FilterableField(
    label: 'Items',
    comparatorsType: int,
    customCompare: Order.compareItemById,
  )
  final List<Item> items;

  static bool compareItemById(Item item, int id) {
    return item.id == id;
  }
}
```

### Enum Filtering

```dart
enum Status { active, inactive, pending }

@Filterable()
class Task {
  @FilterableField(label: 'Status', comparatorsType: Status)
  final Status status;
}

// Filter by enum value
final criteria1 = FilterCriteria(field: 'status', comparator: '==', value: Status.active);

// Filter by index
final criteria2 = FilterCriteria(field: 'status', comparator: '==', value: 0);

// Filter by name
final criteria3 = FilterCriteria(field: 'status', comparator: '==', value: 'active');
```

### Nullable Fields

```dart
@FilterableField(label: 'Email', comparatorsType: String)
final String? email; // Automatically detected as nullable
```

## 🤝 Related Packages

- [filterable_generator](https://pub.dev/packages/filterable_generator) - Code generator (required)
- [build_runner](https://pub.dev/packages/build_runner) - Build system (required)

## 📖 Examples

Check out the [example](https://github.com/SamuelGFDias/filterable/tree/main/example) directory for a complete Flutter app demonstrating all features.

## 🐛 Issues and Feedback

Please file issues, bugs, or feature requests in our [issue tracker](https://github.com/SamuelGFDias/filterable/issues).

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Contributing

Contributions are welcome! Please read our [contributing guidelines](https://github.com/SamuelGFDias/filterable/blob/main/CONTRIBUTING.md) first.
