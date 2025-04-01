import 'package:example/core/providers/filter_criteria/filter_criteria.notifier.dart';
import 'package:example/features/products_view/providers/product/product.notifier.dart';
import 'package:example/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'filtered_products.state.g.dart';

@Riverpod(keepAlive: true)
List<Product> filteredProductsState(Ref ref) {
  final products = ref.watch(productNotifierProvider);
  final filterState = ref.watch(filterCriteriaNotifierProvider);

  List<Product> filtered =
      products.where((product) {
        return filterState.filters.every(
          (criteria) =>
              ProductFilterExtension.buildPredicate(criteria)(product),
        );
      }).toList();

  if (filterState.sorts.isNotEmpty) {
    filtered.sort((a, b) {
      for (final criteria in filterState.sorts) {
        final compare = ProductFilterExtension.buildSorter(criteria)(a, b);
        if (compare != 0) return compare;
      }
      return 0;
    });
  }
  return filtered;
}
