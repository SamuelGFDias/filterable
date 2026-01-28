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
    final fieldsMap = <String, _FilterableFieldInfo>{};

    // 1. Processa parâmetros do construtor (Foco em Freezed)
    final constructor = element.unnamedConstructor;
    if (constructor != null) {
      for (final parameter in constructor.parameters) {
        final info = _parseElement(parameter, parameter.type, parameter.name);
        if (info != null) fieldsMap[parameter.name] = info;
      }
    }

    // 2. O PULO DO GATO: Se for Freezed Union, percorre os outros factory constructors
    for (final constructor in element.constructors) {
      if (constructor.isFactory) {
        for (final p in constructor.parameters) {
          // Se o campo já foi adicionado, não sobrescreve (evita duplicados em Unions)
          if (fieldsMap.containsKey(p.name)) continue;

          final info = _parseElement(p, p.type, p.name);
          if (info != null) fieldsMap[p.name] = info;
        }
      }
    }

    // 3. Mantém a busca por campos físicos (para classes normais)
    for (final field in element.fields) {
      if (fieldsMap.containsKey(field.name)) continue;
      final info = _parseElement(field, field.type, field.name);
      if (info != null) fieldsMap[field.name] = info;
    }

    return fieldsMap.values.toList();
  }

  _FilterableFieldInfo? _parseElement(
      Element element, DartType type, String name) {
    final metadata = element.metadata;

    final filterMetadata = metadata.where((m) {
      final constantValue = m.computeConstantValue();
      return constantValue?.type?.getDisplayString(withNullability: false) ==
          'FilterableField';
    }).toList();

    if (filterMetadata.isEmpty) return null;

    final constantValue = filterMetadata.first.computeConstantValue();
    if (constantValue == null) return null;

    final reader = ConstantReader(constantValue);

    // Extração de propriedades
    final label = reader.peek('label')?.stringValue ?? name;
    final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
    final isList = type.isDartCoreList;
    final isEnum = type.element is EnumElement;

    // Comparadores e Tipos Customizados
    final comparators = reader
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

    // Lógica para Listas
    String? listItemType;
    if (isList && type is ParameterizedType) {
      final typeArgs = type.typeArguments;
      if (typeArgs.isNotEmpty) {
        listItemType = typeArgs.first.getDisplayString(withNullability: false);
      }
    }

    final typeName = type.getDisplayString(withNullability: false);
    final ops = comparators ?? _defaultComparatorsForType(typeName, isList);

    return _FilterableFieldInfo(
      fieldName: name,
      label: label,
      isNullable: isNullable,
      isList: isList,
      isEnum: isEnum,
      typeName: typeName,
      comparatorTypeName: comparatorTypeName,
      comparatorFuncName: comparatorFuncName,
      listItemType: listItemType,
      comparators: ops,
    );
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
    final typeCast = field.comparatorTypeName ?? field.typeName;

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
        'criteria.value',
        field.isNullable,
        typeCast,
      );
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
    final typeCast = field.comparatorTypeName ?? field.typeName;

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
        op, 'e.${field.fieldName}.index', 'value', field.isNullable, typeCast);
    buffer.writeln("                return (e) => $indexComparison;");
    buffer.writeln("              } else {");
    buffer.writeln("                final value = criteria.value as String;");
    final nameComparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}.name', 'value', field.isNullable, typeCast);
    buffer.writeln("                return (e) => $nameComparison;");
    buffer.writeln("              }");
  }

  void _generateEnumStandardComparison(
    StringBuffer buffer,
    _FilterableFieldInfo field,
    String op,
    String typeCast,
  ) {
    final typeCast = field.comparatorTypeName ?? field.typeName;

    buffer.writeln("              if (criteria.value is $typeCast) {");
    buffer
        .writeln("                final value = criteria.value as $typeCast;");
    final comparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}', 'value', field.isNullable, typeCast);
    buffer.writeln("                return (e) => $comparison;");
    buffer.writeln("              } else if (criteria.value is int) {");
    buffer.writeln("                final value = criteria.value as int;");
    final indexComparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}.index', 'value', field.isNullable, typeCast);
    buffer.writeln("                return (e) => $indexComparison;");
    buffer.writeln("              } else {");
    buffer.writeln("                final value = criteria.value as String;");
    final nameComparison = _buildComparisonExpression(
        op, 'e.${field.fieldName}.name', 'value', field.isNullable, typeCast);
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
          op,
          'e.${field.fieldName}',
          'value',
          field.isNullable,
          typeCast,
        );
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
        // Ordenação por tamanho da lista
        buffer.writeln('        return (a, b) => criteria.ascending');
        buffer.writeln(
            '            ? a.${field.fieldName}.length.compareTo(b.${field.fieldName}.length)');
        buffer.writeln(
            '            : b.${field.fieldName}.length.compareTo(a.${field.fieldName}.length);');
      } else {
        // Para Enums, comparamos o .index. Para outros tipos, o valor direto.
        final suffix = field.isEnum ? '?.index' : '';

        // No Freezed, campos opcionais podem ser nulos.
        // Se um valor for nulo, tratamos como "menor que todos" usando um fallback.
        // final fallback = field.isEnum ||
        //         field.typeName == 'int' ||
        //         field.typeName == 'double'
        //     ? '-1'
        //     : 'null';

        buffer.writeln('        return (a, b) {');
        buffer.writeln('          final valA = a.${field.fieldName}$suffix;');
        buffer.writeln('          final valB = b.${field.fieldName}$suffix;');
        buffer.writeln('          if (valA == null && valB == null) return 0;');
        buffer.writeln(
            '          if (valA == null) return criteria.ascending ? -1 : 1;');
        buffer.writeln(
            '          if (valB == null) return criteria.ascending ? 1 : -1;');
        buffer.writeln('          return criteria.ascending');
        buffer.writeln('              ? valA.compareTo(valB)');
        buffer.writeln('              : valB.compareTo(valA);');
        buffer.writeln('        };');
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
    String op,
    String left,
    String right,
    bool isNullable,
    String typeName,
  ) {
    // Se for nulo, a maioria das operações (exceto !=) deve retornar false.
    // Usamos o operador '!' apenas se soubermos que o campo é nullable,
    // para evitar warnings de "unnecessary non-null assertion".
    final access = isNullable ? '$left!' : left;
    final nullGuardPre = isNullable ? '($left != null && ' : '';
    final nullGuardPost = isNullable ? ')' : '';

    final isDateTime = typeName == 'DateTime';

    switch (op) {
      case '==':
        return '$left == $right';
      case '!=':
        // No caso de diferente, se o campo for nulo, ele É diferente do valor (se o valor não for nulo)
        return '$left != $right';
      case '>':
        if (isDateTime) {
          return '$nullGuardPre $access.isAfter($right) $nullGuardPost';
        }
        return '$nullGuardPre $left > $right $nullGuardPost';
      case '<':
        if (isDateTime) {
          return '$nullGuardPre $access.isBefore($right) $nullGuardPost';
        }
        return '$nullGuardPre $left < $right $nullGuardPost';
      case '>=':
        if (isDateTime) {
          return '$nullGuardPre ($access.isAfter($right) || $access == $right) $nullGuardPost';
        }
        return '$nullGuardPre $left >= $right $nullGuardPost';
      case '<=':
        if (isDateTime) {
          return '$nullGuardPre ($access.isBefore($right) || $access == $right) $nullGuardPost';
        }
        return '$nullGuardPre $left <= $right $nullGuardPost';
      case 'contains':
        return '$nullGuardPre $access.contains($right) $nullGuardPost';
      case 'startsWith':
        return '$nullGuardPre $access.startsWith($right) $nullGuardPost';
      case 'endsWith':
        return '$nullGuardPre $access.endsWith($right) $nullGuardPost';
      default:
        return 'false';
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
