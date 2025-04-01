import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:filterable_annotation/filterable.dart';
import 'package:source_gen/source_gen.dart';

class FilterableGenerator extends GeneratorForAnnotation<Filterable> {
  @override
  String generateForAnnotatedElement(
      Element element,
      ConstantReader annotation,
      BuildStep buildStep,
      ) {
    if (element is! ClassElement) return '';

    final className = element.name;
    final buffer = StringBuffer();

    buffer.writeln('// ignore_for_file: dead_code');
    buffer.writeln('extension ${className}FilterExtension on $className {');

    buffer.writeln(
        '  static bool Function($className) buildPredicate(FilterCriteria criteria) {');
    buffer.writeln('    switch (criteria.field) {');

    final fieldInfoBuffer = StringBuffer();
    fieldInfoBuffer.writeln('  static List<FilterableFieldInfo> get filterableFields => [');

    for (final field in element.fields.where((f) => f.metadata.isNotEmpty)) {
      final fieldName = field.name;
      final metadata = ConstantReader(field.metadata.first.computeConstantValue());
      final label = metadata.peek('label')?.stringValue ?? fieldName;
      final comparators = metadata
          .peek('comparators')
          ?.listValue
          .map((v) => v.toStringValue())
          .whereType<String>()
          .toList();
      final constantValue = field.metadata.first.computeConstantValue();
      final customCompareValue = constantValue?.getField('customCompare');
      final comparatorFuncName = customCompareValue?.toFunctionValue()?.name;
      final comparatorsType = constantValue?.getField('comparatorsType');
      final comparatorTypeName = comparatorsType?.toTypeValue()?.getDisplayString();

      final isList = field.type.isDartCoreList;
      final listItemType = isList
          ? (field.type as ParameterizedType).typeArguments.first.getDisplayString()
          : null;

      final typeName = field.type.getDisplayString();
      final ops = comparators ?? _defaultComparatorsForType(typeName, isList);

      buffer.writeln("      case '$fieldName':");

      // Checagem de tipo
      buffer.writeln("        switch (criteria.comparator) {");

      if (isList) {
        final valueCastType = comparatorFuncName != null
            ? comparatorTypeName ?? listItemType
            : listItemType;

        buffer.writeln("          case 'contains':");
        buffer.writeln("          case 'notContains': {");
        buffer.writeln("            if (criteria.value is! $valueCastType) {");
        buffer.writeln("              throw ArgumentError('Expected value of type $valueCastType for field $fieldName');");
        buffer.writeln("            }");
        buffer.writeln("            final value = criteria.value as $valueCastType;");
        if (comparatorFuncName != null) {
          buffer.writeln("            return criteria.comparator == 'contains'");
          buffer.writeln("              ? (e) => e.$fieldName.any((item) => $className.$comparatorFuncName(item, value))");
          buffer.writeln("              : (e) => !e.$fieldName.any((item) => $className.$comparatorFuncName(item, value));");
        } else {
          buffer.writeln("            return criteria.comparator == 'contains'");
          buffer.writeln("              ? (e) => e.$fieldName.contains(value)");
          buffer.writeln("              : (e) => !e.$fieldName.contains(value);");
        }
        buffer.writeln("          }");

        // length comparators
        const lengthOps = ['==', '!=', '>', '<', '>=', '<='];
        for (final op in lengthOps) {
          final expr = _buildComparisonExpression(op, 'e.$fieldName.length', 'criteria.value');
          buffer.writeln("          case 'length$op': return (e) => $expr;");
        }
      } else {
        final typeCast = comparatorTypeName ?? typeName;

        buffer.writeln("          default: {");
        buffer.writeln("            if (criteria.value is! $typeCast) {");
        buffer.writeln("              throw ArgumentError('Expected value of type $typeCast for field $fieldName');");
        buffer.writeln("            }");
        buffer.writeln("            final value = criteria.value as $typeCast;");
        for (final op in ops) {
          if (comparatorFuncName != null) {
            final comparison = op == '!='
                ? '!$className.$comparatorFuncName(e.$fieldName, value)'
                : '$className.$comparatorFuncName(e.$fieldName, value)';
            buffer.writeln("            if (criteria.comparator == '$op') return (e) => $comparison;");
          } else {
            final comparison = _buildComparisonExpression(op, 'e.$fieldName', 'value');
            buffer.writeln("            if (criteria.comparator == '$op') {");
            buffer.writeln("              return (e) => $comparison;");
            buffer.writeln("            }");
          }
        }
        buffer.writeln("            return (_) => true;");
        buffer.writeln("          }");
      }

      buffer.writeln("        }");
      buffer.writeln("        break;");

      // Adiciona ao metadata
      fieldInfoBuffer.writeln('    FilterableFieldInfo(');
      fieldInfoBuffer.writeln("      field: '$fieldName',");
      fieldInfoBuffer.writeln("      label: '$label',");
      fieldInfoBuffer.writeln('      type: ${comparatorTypeName ?? typeName},');
      fieldInfoBuffer.writeln("      comparators: ${ops.map((e) => "'$e'").toList()},");
      fieldInfoBuffer.writeln('    ),');
    }

    buffer.writeln('    }');
    buffer.writeln('    return (_) => true;');
    buffer.writeln('  }');

    // buildSorter
    buffer.writeln('  static int Function($className, $className) buildSorter(SortCriteria criteria) {');
    buffer.writeln('    switch (criteria.field) {');
    for (final field in element.fields.where((f) => f.metadata.isNotEmpty)) {
      final fieldName = field.name;
      final isList = field.type.isDartCoreList;
      if (isList) {
        buffer.writeln("      case '$fieldName':");
        buffer.writeln('        return (a, b) => criteria.ascending');
        buffer.writeln('            ? a.$fieldName.length.compareTo(b.$fieldName.length)');
        buffer.writeln('            : b.$fieldName.length.compareTo(a.$fieldName.length);');
      } else {
        buffer.writeln("      case '$fieldName':");
        buffer.writeln('        return (a, b) => criteria.ascending');
        buffer.writeln('            ? a.$fieldName.compareTo(b.$fieldName)');
        buffer.writeln('            : b.$fieldName.compareTo(a.$fieldName);');
      }
    }
    buffer.writeln('    }');
    buffer.writeln('    return (a, b) => 0;');
    buffer.writeln('  }');

    // Metadados dos campos
    fieldInfoBuffer.writeln('  ];');
    buffer.writeln(fieldInfoBuffer.toString());
    buffer.writeln('}');

    return buffer.toString();
  }

  List<String> _defaultComparatorsForType(String type, bool isList) {
    if (isList) {
      return ['contains', 'notContains', 'length==', 'length!=', 'length>', 'length<', 'length>=', 'length<='];
    }
    switch (type) {
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

  String _buildComparisonExpression(String op, String left, String right) {
    switch (op) {
      case '==': return '$left == $right';
      case '!=': return '$left != $right';
      case '>': return '$left > $right';
      case '<': return '$left < $right';
      case '>=': return '$left >= $right';
      case '<=': return '$left <= $right';
      case 'contains': return '$left.contains($right)';
      case 'startsWith': return '$left.startsWith($right)';
      case 'endsWith': return '$left.endsWith($right)';
      default: return 'false';
    }
  }
}
