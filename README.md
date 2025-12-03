# Filterable

[![pub package](https://img.shields.io/pub/v/filterable_annotation.svg)](https://pub.dev/packages/filterable_annotation)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/SamuelGFDias/filterable)](https://github.com/SamuelGFDias/filterable/stargazers)

A powerful and flexible code generation package for creating type-safe, dynamic filter and sort functionality for Dart and Flutter models. Build complex filtering UIs with ease!

## 🌟 Why Filterable?

- 🎯 **Type-Safe** - Compile-time validation ensures your filters are always correct
- ⚡ **High Performance** - Optimized generated code with minimal overhead
- 🎨 **UI-Ready** - Auto-generated metadata for building dynamic filter interfaces
- 🔧 **Highly Customizable** - Support for custom comparators and comparison functions
- 📝 **Enum Support** - Filter enums by value, index (int), or name (string)
- 📋 **List Operations** - Contains checks, length comparisons, and custom list filters
- 🧩 **Clean Code** - Well-structured, readable generated code
- 🚀 **Easy to Use** - Simple annotations, powerful results

## 📦 Packages

This repository contains two packages:

| Package | Version | Description |
|---------|---------|-------------|
| [filterable_annotation](packages/filterable_annotation) | [![pub](https://img.shields.io/pub/v/filterable_annotation.svg)](https://pub.dev/packages/filterable_annotation) | Annotations and runtime classes |
| [filterable_generator](packages/filterable_generator) | [![pub](https://img.shields.io/pub/v/filterable_generator.svg)](https://pub.dev/packages/filterable_generator) | Code generator |

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  filterable_annotation: ^1.0.0

dev_dependencies:
  filterable_generator: ^1.0.0
  build_runner: ^2.4.0
```

### Basic Usage

#### 1. Annotate your model

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

  @FilterableField(label: 'In Stock', comparatorsType: bool)
  final bool inStock;

  @FilterableField(label: 'Tags', comparatorsType: String)
  final List<String> tags;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.inStock,
    required this.tags,
  });
}
```

#### 2. Generate code

```bash
dart run build_runner build
```

#### 3. Use the generated extension

```dart
// Filter products by price
final priceCriteria = FilterCriteria(
  field: 'price',
  comparator: '>=',
  value: 50.0,
);
final expensiveProducts = products
    .where(ProductFilterExtension.buildPredicate(priceCriteria))
    .toList();

// Filter by name contains
final nameCriteria = FilterCriteria(
  field: 'name',
  comparator: 'contains',
  value: 'iPhone',
);
final iPhones = products
    .where(ProductFilterExtension.buildPredicate(nameCriteria))
    .toList();

// Sort products by price (descending)
final sortCriteria = SortCriteria(field: 'price', ascending: false);
products.sort(ProductFilterExtension.buildSorter(sortCriteria));

// Build dynamic UI from metadata
final fields = ProductFilterExtension.filterableFields;
for (final field in fields) {
  print('${field.label}: ${field.comparators}');
  // Output: Name: [==, !=, contains, startsWith, endsWith]
  //         Price: [==, !=, >, <, >=, <=]
  //         ...
}
```

## 🎯 Features in Detail

### Supported Types and Comparators

| Type | Comparators | Example |
|------|-------------|---------|
| `String` | `==`, `!=`, `contains`, `startsWith`, `endsWith` | `'iPhone'` |
| `int`, `double` | `==`, `!=`, `>`, `<`, `>=`, `<=` | `100.0` |
| `DateTime` | `==`, `!=`, `>`, `<`, `>=`, `<=` | `DateTime.now()` |
| `bool` | `==`, `!=` | `true` |
| `Enum` | `==`, `!=` | Value, index, or name |
| `List<T>` | `contains`, `notContains`, `length*` | Length comparisons |

### Enum Support

Enums can be filtered in three ways:

```dart
enum Status { active, inactive, pending }

@Filterable()
class Task {
  @FilterableField(label: 'Status', comparatorsType: Status)
  final Status status;
}

// By enum value
final c1 = FilterCriteria(field: 'status', comparator: '==', value: Status.active);

// By index (int)
final c2 = FilterCriteria(field: 'status', comparator: '==', value: 0);

// By name (string)
final c3 = FilterCriteria(field: 'status', comparator: '==', value: 'active');
```

### Custom Comparators

Restrict available comparators for specific fields:

```dart
@FilterableField(
  label: 'Status',
  comparatorsType: String,
  comparators: ['==', '!='], // Only equality checks allowed
)
final String status;
```

### Custom Comparison Functions

Use custom logic for complex types:

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
final filtered = orders
    .where(OrderFilterExtension.buildPredicate(criteria))
    .toList();
```

### List Operations

Filter lists by content or length:

```dart
@FilterableField(label: 'Tags', comparatorsType: String)
final List<String> tags;

// Contains check
final contains = FilterCriteria(
  field: 'tags',
  comparator: 'contains',
  value: 'featured',
);

// Length comparison
final lengthCheck = FilterCriteria(
  field: 'tags',
  comparator: 'length>=',
  value: 3,
);
```

### Nullable Fields

Automatically handles null-safe comparisons:

```dart
@FilterableField(label: 'Description', comparatorsType: String)
final String? description; // Null-safe comparisons generated
```

## 🎨 Building Dynamic UIs

Use the generated metadata to build filter interfaces:

```dart
class FilterDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fields = ProductFilterExtension.filterableFields;
    
    return ListView.builder(
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final field = fields[index];
        return ListTile(
          title: Text(field.label),
          subtitle: Text('Type: ${field.type}'),
          trailing: DropdownButton<String>(
            items: field.comparators.map((comparator) {
              return DropdownMenuItem(
                value: comparator,
                child: Text(comparator),
              );
            }).toList(),
            onChanged: (value) {
              // Build FilterCriteria
            },
          ),
        );
      },
    );
  }
}
```

## 📖 Complete Example

Check out the [example app](example/) for a full implementation including:

- Product listing with dynamic filters
- Sort by multiple fields
- Custom comparison functions
- UI integration with Flutter
- Multiple filter criteria
- Real-world usage patterns

## 🏗️ Architecture

```
filterable/
├── packages/
│   ├── filterable_annotation/    # Annotations and runtime classes
│   │   ├── lib/
│   │   │   ├── filterable.dart        # @Filterable, @FilterableField
│   │   │   ├── filter_criteria.dart   # FilterCriteria class
│   │   │   ├── sort_criteria.dart     # SortCriteria class
│   │   │   └── filterable_annotation.dart  # Main export
│   │   └── pubspec.yaml
│   │
│   └── filterable_generator/     # Code generator
│       ├── lib/
│       │   ├── filterable_generator.dart   # Main generator
│       │   └── builder.dart                # Builder configuration
│       └── pubspec.yaml
│
└── example/                      # Example Flutter app
    └── lib/
        └── models/
            ├── product.dart              # Annotated model
            └── product.filterable.g.dart # Generated code
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/SamuelGFDias/filterable.git
cd filterable

# Get dependencies for all packages
cd packages/filterable_annotation && flutter pub get && cd ../..
cd packages/filterable_generator && flutter pub get && cd ../..
cd example && flutter pub get && cd ..

# Run the example
cd example
flutter run
```

### Running Tests

```bash
cd packages/filterable_generator
dart test
```

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

## 🐛 Issues and Bugs

If you encounter any issues, please file them in the [issue tracker](https://github.com/SamuelGFDias/filterable/issues).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the powerful code generation capabilities of packages like `json_serializable` and `freezed`
- Built with [source_gen](https://pub.dev/packages/source_gen) and [build_runner](https://pub.dev/packages/build_runner)

## 💖 Support

If you find this package useful, please give it a ⭐ on [GitHub](https://github.com/SamuelGFDias/filterable)!

---

Made with ❤️ by [Samuel Dias](https://github.com/SamuelGFDias)
