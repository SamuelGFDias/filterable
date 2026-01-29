# filterable_generator

[![pub package](https://img.shields.io/pub/v/filterable_generator.svg)](https://pub.dev/packages/filterable_generator)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Code generator for creating type-safe filter and sort functionality for Dart models annotated with `@Filterable`. Works with `build_runner` to generate extension methods that enable dynamic filtering and sorting.

## ✨ Features

- 🎯 **Type-safe code generation** - Compile-time type validation
- ⚡ **High performance** - Optimized generated code
- 🔧 **Highly customizable** - Custom comparators and comparison functions
- 📝 **Enum support** - Filter by value, index (int), or name (string)
- 📋 **List operations** - Contains checks and length comparisons
- 🎨 **UI-ready** - Generates field metadata for dynamic UI generation
- 🧩 **Clean architecture** - Well-structured, maintainable generated code

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  filterable_annotation: ^1.0.0

dev_dependencies:
  filterable_generator: ^1.1.3
  build_runner: ^2.4.0  # or ^2.3.0, works with multiple versions
```

### Version Compatibility

`filterable_generator` is designed to work with a wide range of dependency versions:

- **Build Runner**: 2.4.0 - 2.10.x ✅ **TESTED**
- **Analyzer**: 5.2.0 - 9.x (supports both Element and Element2 APIs)
- **Build**: 2.4.0 - 4.x (works across major versions)
- **Source Gen**: 1.2.0 - 4.x (adaptive version support)
- **Flutter**: 3.0.0+ and Dart 3.0.0+

#### Recommended Versions

For **maximum compatibility** (works with most other packages):
```yaml
dev_dependencies:
  filterable_generator: ^^1.1.3
  build_runner: ^2.4.0  # Most compatible
```

For **latest features** (newer projects):
```yaml
dev_dependencies:
  filterable_generator: ^1.1.3
  build_runner: ^2.7.0  # Latest
```

This ensures compatibility with:
- ✅ Older Flutter projects (SDK 3.0.0+)
- ✅ Latest Flutter stable
- ✅ Mixed dependency environments
- ✅ Other code generators (json_serializable, freezed, riverpod_generator, etc.)

See [COMPATIBILITY.md](COMPATIBILITY.md) and [TEST_RESULTS.md](../../TEST_RESULTS.md) for detailed version information and test results.

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

  @FilterableField(label: 'Category', comparatorsType: String)
  final String category;

  @FilterableField(label: 'Tags', comparatorsType: String)
  final List<String> tags;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.tags,
  });
}
```

### 2. Run code generation

```bash
# One-time generation
dart run build_runner build

# Watch for changes
dart run build_runner watch

# Clean and rebuild
dart run build_runner build --delete-conflicting-outputs
```

### 3. Use generated code

```dart
// Filter products
final criteria = FilterCriteria(
  field: 'price',
  comparator: '>=',
  value: 100.0,
);
final predicate = ProductFilterExtension.buildPredicate(criteria);
final filtered = products.where(predicate).toList();

// Sort products
final sortCriteria = SortCriteria(field: 'name', ascending: true);
final sorter = ProductFilterExtension.buildSorter(sortCriteria);
products.sort(sorter);

// Access metadata
final fields = ProductFilterExtension.filterableFields;
```

## 📋 Generated Code

For the example above, the generator creates:

```dart
extension ProductFilterExtension on Product {
  static bool Function(Product) buildPredicate(FilterCriteria criteria) {
    // Generated filtering logic
  }

  static int Function(Product, Product) buildSorter(SortCriteria criteria) {
    // Generated sorting logic
  }

  static List<FilterableFieldInfo> get filterableFields => [
    // Field metadata for UI generation
  ];
}
```

## 🎯 Supported Operations

### String Fields
- `==`, `!=` - Equality/inequality
- `contains` - Substring search
- `startsWith`, `endsWith` - Prefix/suffix matching

### Numeric Fields (int, double)
- `==`, `!=` - Equality/inequality
- `>`, `<`, `>=`, `<=` - Comparison

### DateTime Fields
- `==`, `!=` - Equality/inequality
- `>`, `<`, `>=`, `<=` - Date comparison

### Boolean Fields
- `==`, `!=` - Equality/inequality

### Enum Fields
- `==`, `!=` - Can compare by:
  - Enum value: `Status.active`
  - Index (int): `0`, `1`, `2`
  - Name (string): `'active'`, `'inactive'`

### List Fields
- `contains`, `notContains` - Element presence
- `length==`, `length!=`, `length>`, `length<`, `length>=`, `length<=` - Length comparison

## 🔧 Advanced Usage

### Custom Comparators

Limit allowed comparison operators:

```dart
@FilterableField(
  label: 'Status',
  comparatorsType: String,
  comparators: ['==', '!='], // Only equality checks
)
final String status;
```

### Custom Comparison Functions

Use custom logic for complex comparisons:

```dart
@Filterable()
class Order {
  @FilterableField(
    label: 'Items',
    comparatorsType: int,
    customCompare: Order.itemHasId,
  )
  final List<OrderItem> items;

  Order({required this.items});

  static bool itemHasId(OrderItem item, int id) {
    return item.id == id;
  }
}

// Usage
final criteria = FilterCriteria(
  field: 'items',
  comparator: 'contains',
  value: 123,
);
```

### Enum Filtering

```dart
enum Priority { low, medium, high, critical }

@Filterable()
class Task {
  @FilterableField(label: 'Priority', comparatorsType: Priority)
  final Priority priority;
}

// Filter by enum value
final c1 = FilterCriteria(field: 'priority', comparator: '==', value: Priority.high);

// Filter by index
final c2 = FilterCriteria(field: 'priority', comparator: '>=', value: 2);

// Filter by name
final c3 = FilterCriteria(field: 'priority', comparator: '==', value: 'critical');
```

### Nullable Fields

Automatically handles null safety:

```dart
@FilterableField(label: 'Description', comparatorsType: String)
final String? description; // Null-safe comparisons generated
```

## 🏗️ Architecture

The generator uses a clean, modular architecture:

- **Field Extraction** - Parses annotations and field metadata
- **Predicate Generation** - Creates type-safe filter functions
- **Sorter Generation** - Creates comparison functions
- **Metadata Generation** - Produces UI-ready field information

Key components:
- `_extractFilterableFields()` - Processes field annotations
- `_generateBuildPredicate()` - Generates filter logic
- `_generateBuildSorter()` - Generates sort logic
- `_generateFilterableFieldsInfo()` - Generates metadata

### Analyzer Compatibility

The generator is designed to work with multiple versions of the `analyzer` package:

- **Automatic Detection**: Detects available API (Element vs Element2)
- **Wide Version Range**: Supports analyzer 5.x through 9.x
- **Graceful Adaptation**: Uses compatible API calls for each version
- **No Breaking Changes**: Works seamlessly across analyzer updates

## 🧪 Testing

The generated code is tested through:
1. Type safety validation at compile time
2. Runtime testing in the example app
3. Integration with real-world use cases

## 🤝 Related Packages

- [filterable_annotation](https://pub.dev/packages/filterable_annotation) - Annotations (required)
- [build_runner](https://pub.dev/packages/build_runner) - Build system (required)

## 📖 Examples

Check out the [example app](https://github.com/SamuelGFDias/filterable/tree/main/example) for:
- Complete working implementation
- UI integration examples
- Custom comparator usage
- Dynamic filter generation

## 🐛 Issues and Feedback

File issues, bugs, or feature requests in our [issue tracker](https://github.com/SamuelGFDias/filterable/issues).

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Contributing

Contributions welcome! Please read our [contributing guidelines](https://github.com/SamuelGFDias/filterable/blob/main/CONTRIBUTING.md) first.

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
