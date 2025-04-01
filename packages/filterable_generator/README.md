# filterable_generator

Gera automaticamente métodos `buildPredicate` e `buildSorter` para classes anotadas com `@Filterable`, com base nos campos anotados com `@FilterableField`.

## Instalação

```yaml
dependencies:
  filterable_annotation: ^0.1.0
  filterable_generator: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.7
```

## Como usar

```dart
@Filterable()
class Produto {
  @FilterableField(label: 'Nome', comparatorsType: String)
  final String nome;

  @FilterableField(label: 'Preço', comparatorsType: double)
  final double preco;

  Produto({required this.nome, required this.preco});
}
```

### Gerar código

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

O código gerado incluirá:

```dart
ProdutoFilterExtension.buildPredicate(criteria);
ProdutoFilterExtension.buildSorter(criteria);
```

## Funcionalidades avançadas

- Suporte a operadores customizados (`comparators`)
- Suporte a funções de comparação customizadas (`customCompare`)

## Licença

MIT
