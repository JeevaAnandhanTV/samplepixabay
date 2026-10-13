import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_image_gallery/core/errors/app_exception.dart';
import 'package:infinite_image_gallery/features/favorites/favorites_controller.dart';
import 'package:infinite_image_gallery/features/favorites/favorites_repository.dart';
import 'package:infinite_image_gallery/features/favorites/favorites_screen.dart';
import 'package:infinite_image_gallery/features/gallery/presentation/widgets/error_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ErrorView shows message and triggers retry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorView(
          error: const AppException(AppErrorType.network, 'No internet connection.'),
          onRetry: () => retried++,
        ),
      ),
    ));

    expect(find.text('No internet connection.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('FavoritesScreen shows empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FavoritesController(FavoritesRepository(prefs)),
        child: const MaterialApp(home: FavoritesScreen()),
      ),
    );

    expect(find.text('No favorites yet'), findsOneWidget);
  });
}
