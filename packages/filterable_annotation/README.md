# filterable_annotation

O `filterable_annotation` fornece anotações para uso com o pacote `filterable_generator`, permitindo gerar filtros e ordenações dinamicamente para qualquer classe de modelo.

## ✨ Funcionalidades

- `@Filterable()` para marcar classes filtráveis.
- `@FilterableField()` para definir campos com suporte a filtros.
- Suporte a:
    - Comparadores padrão por tipo (`==`, `!=`, `>`, `contains`, etc)
    - Comparadores customizados (`comparators`)
    - Funções personalizadas de comparação (`customCompare`)

## 🚀 Instalação

Adicione ao seu `pubspec.yaml`:

```yaml
dependencies:
  filterable_annotation: ^0.1.0
```

## 🛠️ Como usar

```dart
import 'package:filterable_annotation/filterable_annotation.dart';

@Filterable()
class Produto {
  @FilterableField(label: 'Nome', comparatorsType: String)
  final String nome;

  @FilterableField(label: 'Preço', comparatorsType: double)
  final double preco;

  Produto({required this.nome, required this.preco});
}
```

Use junto com o pacote `filterable_generator` e `build_runner` para gerar os métodos `buildPredicate()` e `buildSorter()`.

## 📦 Integração com Generator

O código gerado inclui:
- `ProdutoFilterExtension.buildPredicate(...)`
- `ProdutoFilterExtension.buildSorter(...)`
- `ProdutoFilterExtension.filterableFields` para gerar UI dinamicamente

## 📄 Licença

MIT License
