import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Reproduit exactement le pattern Row(stretch)+Expanded utilisé dans
// StudentHomeScreen (stats + accès rapides), placé dans un ListView comme
// dans l'écran réel, pour vérifier que le fix (IntrinsicHeight) empêche
// l'exception "BoxConstraints forces an infinite height".
Widget _card(Widget child) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: child,
    );

Widget _statCard(String label) => _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined, size: 20),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );

void main() {
  testWidgets('Row+stretch inside ListView wrapped in IntrinsicHeight does not throw', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _statCard('Candidatures')),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('En attente')),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Acceptées')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Row+stretch WITHOUT IntrinsicHeight throws infinite height (regression proof)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _statCard('Candidatures')),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('En attente')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNotNull);
  });
}
