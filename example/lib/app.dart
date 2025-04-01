import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/products_view/presentation/pages/product_view.page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.dark(),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.black87,
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
              fontSize: 25,
            ),
            elevation: 3,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            scrolledUnderElevation: 1.0,
          ),
          useMaterial3: true,
        ),
        home: const ProductViewPage());
  }
}
