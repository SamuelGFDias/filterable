import 'package:example/models/product.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/filter_criteria/filter_criteria.notifier.dart';
import 'product.notifier.dart';


part 'filtered_products.state.g.dart';

@Riverpod(keepAlive: true)
List<Product> filteredProductsState(Ref ref) {
  final products = ref.watch(productProvider);
  final filterState = ref.watch(filterCriteriaProvider);

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
