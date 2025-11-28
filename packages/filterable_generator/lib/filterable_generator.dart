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

    // Início do buildPredicate
    buffer.writeln(
        '  static bool Function($className) buildPredicate(FilterCriteria criteria) {');
    buffer.writeln('    switch (criteria.field) {');

    // Buffer para a lista de metadados (filterableFields)
    final fieldInfoBuffer = StringBuffer();
    fieldInfoBuffer.writeln('  static List<FilterableFieldInfo> get filterableFields => [');

    // Loop corrigido para iterar campos e acessar metadados seguramente
    for (final field in element.fields) {
      // FIX: Cast explícito via dynamic para resolver conflito de tipo 'Metadata' vs 'List<ElementAnnotation>'
      final List<ElementAnnotation> fieldMetadata = (field.metadata as dynamic) as List<ElementAnnotation>;

      // Evita erros se o campo não tiver anotações
      if (fieldMetadata.isEmpty) continue;

      // Pega a primeira anotação (assumindo que é a @FilterableField ou similar)
      final firstAnnotation = fieldMetadata.first;
      final constantValue = firstAnnotation.computeConstantValue();

      // Se não for uma constante válida, pula
      if (constantValue == null) continue;

      final metadata = ConstantReader(constantValue);
      final fieldName = field.name;
      
      final label = metadata.peek('label')?.stringValue ?? fieldName;
      final comparators = metadata
          .peek('comparators')
          ?.listValue
          .map((v) => v.toStringValue())
          .whereType<String>()
          .toList();

      final customCompareValue = constantValue.getField('customCompare');
      final comparatorFuncName = customCompareValue?.toFunctionValue()?.name;
      final comparatorsType = constantValue.getField('comparatorsType');
      final comparatorTypeName = comparatorsType?.toTypeValue()?.getDisplayString(); // Ajuste para versões novas do analyzer

      final isList = field.type.isDartCoreList;
      // Ajuste seguro para pegar tipos genéricos
      String? listItemType;
      if (isList && field.type is ParameterizedType) {
        final typeArgs = (field.type as ParameterizedType).typeArguments;
        if (typeArgs.isNotEmpty) {
          listItemType = typeArgs.first.getDisplayString();
        }
      }

      final typeName = field.type.getDisplayString();
      final ops = comparators ?? _defaultComparatorsForType(typeName, isList);

      buffer.writeln("      case '$fieldName':");

      // Lógica de Comparadores
      buffer.writeln("        switch (criteria.comparator) {");

      if (isList) {
        final valueCastType = comparatorFuncName != null
            ? comparatorTypeName ?? listItemType
            : listItemType;

        buffer.writeln("          case 'contains':");
        buffer.writeln("          case 'notContains': {");
        // Validação de tipo em runtime
        if (valueCastType != null) {
            buffer.writeln("            if (criteria.value is! $valueCastType) {");
            buffer.writeln("              throw ArgumentError('Expected value of type $valueCastType for field $fieldName');");
            buffer.writeln("            }");
            buffer.writeln("            final value = criteria.value as $valueCastType;");
        } else {
             buffer.writeln("            final value = criteria.value;");
        }

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

      // Adiciona info ao array estático
      fieldInfoBuffer.writeln('    FilterableFieldInfo(');
      fieldInfoBuffer.writeln("      field: '$fieldName',");
      fieldInfoBuffer.writeln("      label: '$label',");
      fieldInfoBuffer.writeln('      type: ${comparatorTypeName ?? typeName},');
      fieldInfoBuffer.writeln("      comparators: ${ops.map((e) => "'$e'").toList()},");
      fieldInfoBuffer.writeln('    ),');
    }

    buffer.writeln('    }'); // Fecha switch field
    buffer.writeln('    return (_) => true;');
    buffer.writeln('  }'); // Fecha buildPredicate

    // buildSorter
    buffer.writeln('  static int Function($className, $className) buildSorter(SortCriteria criteria) {');
    buffer.writeln('    switch (criteria.field) {');
    
    // Reutiliza loop para sorter
    for (final field in element.fields) {
      // FIX: Cast explícito via dynamic também aqui
      final List<ElementAnnotation> fieldMetadata = (field.metadata as dynamic) as List<ElementAnnotation>;
      if (fieldMetadata.isEmpty) continue;
      
      final fieldName = field.name;
      final isList = field.type.isDartCoreList;
      
      buffer.writeln("      case '$fieldName':");
      if (isList) {
        buffer.writeln('        return (a, b) => criteria.ascending');
        buffer.writeln('            ? a.$fieldName.length.compareTo(b.$fieldName.length)');
        buffer.writeln('            : b.$fieldName.length.compareTo(a.$fieldName.length);');
      } else {
        buffer.writeln('        return (a, b) => criteria.ascending');
        buffer.writeln('            ? a.$fieldName.compareTo(b.$fieldName)');
        buffer.writeln('            : b.$fieldName.compareTo(a.$fieldName);');
      }
    }
    
    buffer.writeln('    }');
    buffer.writeln('    return (a, b) => 0;');
    buffer.writeln('  }');

    // Fecha lista de metadados
    fieldInfoBuffer.writeln('  ];');
    buffer.writeln(fieldInfoBuffer.toString());
    
    buffer.writeln('}'); // Fecha extension

    return buffer.toString();
  }

  List<String> _defaultComparatorsForType(String type, bool isList) {
    if (isList) {
      return ['contains', 'notContains', 'length==', 'length!=', 'length>', 'length<', 'length>=', 'length<='];
    }
    // Tratamento básico para remover sufixos de nullability '?' se existirem na string do tipo
    final cleanType = type.endsWith('?') ? type.substring(0, type.length - 1) : type;
    
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