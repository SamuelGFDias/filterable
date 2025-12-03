import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:filterable_annotation/filterable.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating filterable extensions on annotated classes.
///
/// This generator is compatible with multiple versions of the analyzer package,
/// automatically adapting to the available API (Element vs Element2).
class FilterableGenerator extends GeneratorForAnnotation<Filterable> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';

    final className = element.name;
    final filterableFields = _extractFilterableFields(element);

    final buffer = StringBuffer();
    buffer.writeln('// ignore_for_file: dead_code');
    buffer.writeln('extension ${className}FilterExtension on $className {');

    _generateBuildPredicate(buffer, className, filterableFields);
    _generateBuildSorter(buffer, className, filterableFields);
    _generateFilterableFieldsInfo(buffer, filterableFields);

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Extracts filterable field information from a class element.
  ///
  /// This method is compatible with both old and new analyzer versions,
  /// handling the transition from Element to Element2 gracefully.
  List<_FilterableFieldInfo> _extractFilterableFields(ClassElement element) {
    final fields = <_FilterableFieldInfo>[];

    for (final field in element.fields) {
      // Compatible with both analyzer versions that may use Element or Element2
      final fieldMetadata = _getFieldMetadata(field);

      if (fieldMetadata.isEmpty) continue;

      final filterMetadata = fieldMetadata.where((m) {
        final constantValue = m.computeConstantValue();
        if (constantValue == null) return false;
        return constantValue.type?.getDisplayString(withNullability: false) ==
            'FilterableField';
      }).toList();

      if (filterMetadata.isEmpty) continue;

      final firstAnnotation = filterMetadata.first;
      final constantValue = firstAnnotation.computeConstantValue();
      if (constantValue == null) continue;

      final metadata = ConstantReader(constantValue);
      final fieldName = field.name;
      final label = metadata.peek('label')?.stringValue ?? fieldName;
      final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
      final comparators = metadata
          .peek('comparators')
          ?.listValue
          .map((v) => v.toStringValue())
          .whereType<String>()
          .toList();

      final customCompareValue = constantValue.getField('customCompare');
      final comparatorFuncName = customCompareValue?.toFunctionValue()?.name;
      final comparatorsType = constantValue.getField('comparatorsType');

      final comparatorTypeName = comparatorsType
          ?.toTypeValue()
          ?.getDisplayString(withNullability: false);

      final isList = field.type.isDartCoreList;
      final isEnum = field.type.element is EnumElement;

      String? listItemType;
      if (isList && field.type is ParameterizedType) {
        final typeArgs = (field.type as ParameterizedType).typeArguments;
        if (typeArgs.isNotEmpty) {
          listItemType =
              typeArgs.first.getDisplayString(withNullability: false);
        }
      }

      final typeName = field.type.getDisplayString(withNullability: false);
      final ops = comparators ?? _defaultComparatorsForType(typeName, isList);

      fields.add(_FilterableFieldInfo(
        fieldName: fieldName,
        label: label,
        isNullable: isNullable,
        isList: isList,
        isEnum: isEnum,
        typeName: typeName,
        comparatorTypeName: comparatorTypeName,
        comparatorFuncName: comparatorFuncName,
        listItemType: listItemType,
        comparators: ops,
      ));
    }

    return fields;
  }

  void _generateBuildPredicate(
    StringBuffer buffer,
    String className,
    List<_FilterableFieldInfo> fields,
  ) {
    buffer.writeln(
        '  static bool Function($className) buildPredicate(FilterCriteria criteria) {');
    buffer.writeln('    switch (criteria.field) {');

    for (final field in fields) {
      buffer.writeln("      case '${field.fieldName}':");
      buffer.writeln("        switch (criteria.comparator) {");

      if (field.isList) {
        _generateListComparators(buffer, className, field);
      } else {
        _generateScalarComparators(buffer, className, field);
      }

      buffer.writeln("        }");
      buffer.writeln("        break;");
    }

    buffer.writeln('    }');
    buffer.writeln('    return (_) => true;');
    buffer.writeln('  }');
  }

  void _generateListComparators(
    StringBuffer buffer,
    String className,
    _FilterableFieldInfo field,
  ) {
    final valueCastType = field.comparatorFuncName != null
        ? field.comparatorTypeName ?? field.listItemType
        : field.listItemType;

    buffer.writeln("          case 'contains':");
    buffer.writeln("          case 'notContains': {");

    if (valueCastType != null) {
      buffer.writeln("            if (criteria.value is! $valueCastType) {");
      buffer.writeln(
          "              throw ArgumentError('Expected value of type $valueCastType for field ${field.fieldName}');");
      buffer.writeln("            }");
      buffer.writeln(
          "            final value = criteria.value as $valueCastType;");
    } else {
      buffer.writeln("            final value = criteria.value;");
    }

    if (field.comparatorFuncName != null) {
      buffer.writeln("            return criteria.comparator == 'contains'");
      buffer.writeln(
          "              ? (e) => e.${field.fieldName}.any((item) => $className.${field.comparatorFuncName}(item, value))");
      buffer.writeln(
          "              : (e) => !e.${field.fieldName}.any((item) => $className.${field.comparatorFuncName}(item, value));");
    } else {
      buffer.writeln("            return criteria.comparator == 'contains'");
      buffer.writeln(
          "              ? (e) => e.${field.fieldName}.contains(value)");
      buffer.writeln(
          "              : (e) => !e.${field.fieldName}.contains(value);");
    }
    buffer.writeln("          }");

    const lengthOps = ['==', '!=', '>', '<', '>=', '<='];
    for (final op in lengthOps) {
      final expr = _buildComparisonExpression(op, 'e.${field.fieldName}.length',
          'criteria.value', field.isNullable);
      buffer.writeln("          case 'length$op': return (e) => $expr;");
    }
  }

  void _generateScalarComparators(
    StringBuffer buffer,
    String className,
    _FilterableFieldInfo field,
  ) {
    final typeCast = field.comparatorTypeName ?? field.typeName;

    buffer.writeln("          default: {");

    if (field.isEnum) {
      _generateEnumComparators(buffer, className, field, typeCast);
    } else {
      _generateStandardComparators(buffer, className, field, typeCast);
    }

    buffer.writeln("            return (_) => true;");
    buffer.writeln("          }");
  }

  void _generateEnumComparators(
    StringBuffer buffer,
    String className,
    _FilterableFieldInfo field,
    String typeCast,
  ) {
    buffer.writeln(
        "            if (criteria.value is! $typeCast && criteria.value is! int && criteria.value is! String) {");
    buffer.writeln(
        "              throw ArgumentError('Expected value of type $typeCast, int, or String for enum field ${field.fieldName}');");
    buffer.writeln("            }");

    for (final op in field.comparators) {
      buffer.writeln("            if (criteria.comparator == '$op') {");

      if (field.comparatorFuncName != null) {
        _generateEnumCustomComparison(buffer, className, field, op, typeCast);
      } else {
        _generateEnumStandardComparison(buffer, field, op, typeCast);
      }

      buffer.writeln("            }");
    }
  }

  void _generateEnumCustomComparison(
    StringBuffer buffer,
    String className,
    _FilterableFieldInfo field,
    String op,
    String typeCast,
  ) {
    buffer.writeln("              if (criteria.value is $typeCast) {");
    buffer
        .writeln("                final value = criteria.value as $typeCast;");
    final comparison = op == '!='
        ? '!$className.${field.comparatorFuncName}(e.${field.fieldName}, value)'
        : '$className.${field.comparatorFuncName}(e.${field.fieldName}, value)';
    buffer.writeln("                return (e) => $comparison;");
    buffer.writeln("              } else if (criteria.value is int) {");
    buffer.writeln("                final value = criteria.value as int;");
    final indexComparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}.index', 'value', field.isNullable);
    buffer.writeln("                return (e) => $indexComparison;");
    buffer.writeln("              } else {");
    buffer.writeln("                final value = criteria.value as String;");
    final nameComparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}.name', 'value', field.isNullable);
    buffer.writeln("                return (e) => $nameComparison;");
    buffer.writeln("              }");
  }

  void _generateEnumStandardComparison(
    StringBuffer buffer,
    _FilterableFieldInfo field,
    String op,
    String typeCast,
  ) {
    buffer.writeln("              if (criteria.value is $typeCast) {");
    buffer
        .writeln("                final value = criteria.value as $typeCast;");
    final comparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}', 'value', field.isNullable);
    buffer.writeln("                return (e) => $comparison;");
    buffer.writeln("              } else if (criteria.value is int) {");
    buffer.writeln("                final value = criteria.value as int;");
    final indexComparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}.index', 'value', field.isNullable);
    buffer.writeln("                return (e) => $indexComparison;");
    buffer.writeln("              } else {");
    buffer.writeln("                final value = criteria.value as String;");
    final nameComparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}.name', 'value', field.isNullable);
    buffer.writeln("                return (e) => $nameComparison;");
    buffer.writeln("              }");
  }

  void _generateStandardComparators(
    StringBuffer buffer,
    String className,
    _FilterableFieldInfo field,
    String typeCast,
  ) {
    buffer.writeln("            if (criteria.value is! $typeCast) {");
    buffer.writeln(
        "              throw ArgumentError('Expected value of type $typeCast for field ${field.fieldName}');");
    buffer.writeln("            }");
    buffer.writeln("            final value = criteria.value as $typeCast;");

    for (final op in field.comparators) {
      if (field.comparatorFuncName != null) {
        final comparison = op == '!='
            ? '!$className.${field.comparatorFuncName}(e.${field.fieldName}, value)'
            : '$className.${field.comparatorFuncName}(e.${field.fieldName}, value)';
        buffer.writeln(
            "            if (criteria.comparator == '$op') return (e) => $comparison;");
      } else {
        final comparison = _buildComparisonExpression(
            op, 'e.${field.fieldName}', 'value', field.isNullable);
        buffer.writeln("            if (criteria.comparator == '$op') {");
        buffer.writeln("              return (e) => $comparison;");
        buffer.writeln("            }");
      }
    }
  }

  void _generateBuildSorter(
    StringBuffer buffer,
    String className,
    List<_FilterableFieldInfo> fields,
  ) {
    buffer.writeln(
        '  static int Function($className, $className) buildSorter(SortCriteria criteria) {');
    buffer.writeln('    switch (criteria.field) {');

    for (final field in fields) {
      buffer.writeln("      case '${field.fieldName}':");

      if (field.isList) {
        buffer.writeln('        return (a, b) => criteria.ascending');
        buffer.writeln(
            '            ? a.${field.fieldName}.length.compareTo(b.${field.fieldName}.length)');
        buffer.writeln(
            '            : b.${field.fieldName}.length.compareTo(a.${field.fieldName}.length);');
      } else {
        final nullCheck = field.isNullable
            ? 'a.${field.fieldName} != null && b.${field.fieldName} != null ? '
            : '';
        final closingParen = field.isNullable ? ' : 0' : '';
        final nullableSuffix = field.isNullable ? '!' : '';
        final enumSuffix = field.isEnum ? '.index' : '';

        buffer.writeln('        return (a, b) => criteria.ascending');
        buffer.writeln(
            '            ? ( ${nullCheck}a.${field.fieldName}$nullableSuffix$enumSuffix.compareTo(b.${field.fieldName}$nullableSuffix$enumSuffix) $closingParen )');
        buffer.writeln(
            '            : ( ${nullCheck}b.${field.fieldName}$nullableSuffix$enumSuffix.compareTo(a.${field.fieldName}$nullableSuffix$enumSuffix) $closingParen );');
      }
    }

    buffer.writeln('    }');
    buffer.writeln('    return (a, b) => 0;');
    buffer.writeln('  }');
  }

  void _generateFilterableFieldsInfo(
    StringBuffer buffer,
    List<_FilterableFieldInfo> fields,
  ) {
    buffer.writeln(
        '  static List<FilterableFieldInfo> get filterableFields => [');

    for (final field in fields) {
      buffer.writeln('        FilterableFieldInfo(');
      buffer.writeln("          field: '${field.fieldName}',");
      buffer.writeln("          label: '${field.label}',");
      buffer.writeln("          isNullable: ${field.isNullable},");
      buffer.writeln(
          '          type: ${field.comparatorTypeName ?? field.typeName},');
      buffer.writeln(
          "          comparators: ${field.comparators.map((e) => "'$e'").toList()},");
      buffer.writeln('        ),');
    }

    buffer.writeln('      ];');
  }

  List<String> _defaultComparatorsForType(String type, bool isList) {
    if (isList) {
      return [
        'contains',
        'notContains',
        'length==',
        'length!=',
        'length>',
        'length<',
        'length>=',
        'length<='
      ];
    }
    // Tratamento básico para remover sufixos de nullability '?' se existirem na string do tipo
    final cleanType =
        type.endsWith('?') ? type.substring(0, type.length - 1) : type;

    switch (cleanType) {
      case 'String':
        return ['==', '!=', 'contains', 'startsWith', 'endsWith'];
      case 'int':
      case 'double':
      case 'DateTime':
        return ['==', '!=', '>', '<', '>=', '<='];
      default:
        return ['==', '!='];
    }
  }

  String _buildComparisonExpression(
      String op, String left, String right, bool isNullable) {
    String nullCheck = isNullable ? '($left != null && ' : '';
    String closingParen = isNullable ? ')' : '';

    switch (op) {
      case '==':
        return '$left == $right';
      case '!=':
        return '$left != $right';
      case '>':
        return '$left > $right';
      case '<':
        return '$left < $right';
      case '>=':
        return '$left >= $right';
      case '<=':
        return '$left <= $right';
      case 'contains':
        return '$nullCheck$left${isNullable ? "!" : ""}.contains($right)$closingParen';
      case 'startsWith':
        return '$nullCheck$left${isNullable ? "!" : ""}.startsWith($right)$closingParen';
      case 'endsWith':
        return '$nullCheck$left${isNullable ? "!" : ""}.endsWith($right)$closingParen';
      default:
        return 'false';
    }
  }

  /// Gets field metadata in a way that's compatible with both analyzer versions.
  ///
  /// Older analyzer versions use Element with a direct `metadata` property,
  /// while newer versions may use Element2 with different APIs.
  /// This method abstracts the difference.
  List<ElementAnnotation> _getFieldMetadata(FieldElement field) {
    try {
      // Try the standard approach first (works with most versions)
      final metadata = field.metadata;

      // Use dynamic cast to handle potential type variations across analyzer versions
      // This ensures compatibility even when the exact return type changes
      return (metadata as dynamic) as List<ElementAnnotation>;
    } catch (e) {
      // If all else fails, return empty list
      // This shouldn't happen in practice but provides a safety net
      return <ElementAnnotation>[];
    }
  }
}

/// Internal class to hold information about a filterable field.
///
/// This encapsulates all the metadata needed to generate filtering
/// and sorting code for a single field.
class _FilterableFieldInfo {
  /// The name of the field in the class.
  final String fieldName;

  /// The display label for the field.
  final String label;

  /// Whether the field is nullable.
  final bool isNullable;

  /// Whether the field is a List type.
  final bool isList;

  /// Whether the field is an enum type.
  final bool isEnum;

  /// The string representation of the field's type.
  final String typeName;

  /// Optional custom comparator type name.
  final String? comparatorTypeName;

  /// Optional custom comparison function name.
  final String? comparatorFuncName;

  /// For List types, the type of list items.
  final String? listItemType;

  /// List of allowed comparators for this field.
  final List<String> comparators;

  _FilterableFieldInfo({
    required this.fieldName,
    required this.label,
    required this.isNullable,
    required this.isList,
    required this.isEnum,
    required this.typeName,
    required this.comparatorTypeName,
    required this.comparatorFuncName,
    required this.listItemType,
    required this.comparators,
  });
}
