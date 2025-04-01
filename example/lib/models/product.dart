import 'package:filterable_annotation/filter_criteria.dart';
import 'package:filterable_annotation/filterable.dart';
import 'package:filterable_annotation/sort_criteria.dart';

import 'client.dart';

part 'product.filterable.g.dart';

@Filterable()
class Product {
  @FilterableField(label: 'Id', comparatorsType: int)
  final int id;
  @FilterableField(label: 'Descrição', comparatorsType: String)
  final String description;
  @FilterableField(label: 'Preço', comparatorsType: double)
  final double price;
  @FilterableField(
    label: 'Clientes',
    comparatorsType: int,
    customCompare: Product.compareClient,
  )
  final List<Client> clients;

  Product({
    required this.id,
    required this.description,
    required this.price,
    required this.clients,
  });

  static bool compareClient(Client a, int b) {
    return a.id == b;
  }
}
