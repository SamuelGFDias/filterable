import 'package:example/core/presentation/components/custom_navigation_bar.dart';
import 'package:example/core/presentation/components/filter_sort_menu/filter_sort_menu.dart';
import 'package:example/core/providers/filter_criteria/filter_criteria.notifier.dart';
import 'package:example/features/products_view/providers/product/filtered_products.state.dart';
import 'package:example/features/products_view/providers/product/product.notifier.dart';
import 'package:example/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductViewPage extends ConsumerStatefulWidget {
  const ProductViewPage({super.key});

  @override
  ConsumerState<ProductViewPage> createState() => _DataPageState();
}

class _DataPageState extends ConsumerState<ProductViewPage> {
  @override
  void initState() {
    super.initState();

    Future(_initialize);
  }

  _initialize() async {
    ref.read(productProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredProductsStateProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text("Produtos", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          FilterSortMenu<Product>(
            onUpdate:
                ref.read(filterCriteriaProvider.notifier).updateFilters,
            fields: ProductFilterExtension.filterableFields,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        onRefresh:
            () async => ref.read(productProvider.notifier).refresh(),
        child: ListView(
          children: [
            ...products.map(
              (product) => ListTile(
                title: Text(product.description),
                subtitle: Text('Preço: \$${product.price.toStringAsFixed(2)}'),
                trailing: Badge(
                  label: Text(
                    product.clients.length.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  textColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(selectedIndex: 1),
    );
  }
}
