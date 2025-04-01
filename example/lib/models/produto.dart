
import 'package:filterable_annotation/filter_criteria.dart';
import 'package:filterable_annotation/filterable.dart';
import 'package:filterable_annotation/sort_criteria.dart';

import 'cliente.dart';

part 'produto.filterable.g.dart';

@Filterable()
class Produto {
  @FilterableField(label: "Nome", comparatorsType: String)
  final String nome;
  @FilterableField(label: "Preço", comparatorsType: double)
  final double preco;
  @FilterableField(
    label: "Cliente",
    comparatorsType: int,
    customCompare: Produto.clienteCompare,
  )
  final List<Cliente> clientes;

  Produto({required this.nome, required this.preco, required this.clientes});

  static bool clienteCompare(Cliente a, int b) =>
      a.id == b;
}
