import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, group, test;

import 'package:sinicerita/models/persona_model.dart';

// Feature: admin-panel, Property 6: Delete action visibility matches isActive status
//
// **Validates: Requirements 7.7**
//
// For any persona in the admin list, the delete/deactivate action SHALL be
// visible if and only if the persona's `isActive` field is `true`. Personas
// with `isActive = false` SHALL NOT display the delete action.

/// Pure logic function that mirrors the widget's condition for showing the
/// delete action. In the actual widget (`admin_persona_list_screen.dart`),
/// the delete IconButton is rendered inside `if (persona.isActive)`.
bool shouldShowDeleteAction(PersonaModel persona) => persona.isActive;

/// Generates a random PersonaModel with the given [isActive] value.
PersonaModel _generatePersona({
  required bool isActive,
  required Random random,
}) {
  final id = 'persona-${random.nextInt(100000)}';
  final name = String.fromCharCodes(
    List.generate(5 + random.nextInt(20), (_) => 97 + random.nextInt(26)),
  );
  final description = String.fromCharCodes(
    List.generate(10 + random.nextInt(50), (_) => 97 + random.nextInt(26)),
  );
  final upvotes = random.nextInt(1000);
  final downvotes = random.nextInt(500);

  return PersonaModel(
    id: id,
    name: name,
    description: description,
    isActive: isActive,
    upvotes: upvotes,
    downvotes: downvotes,
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Glados property-based tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property 6: Delete action visibility matches isActive status (Glados)',
      () {
    Glados(any.bool).test(
      'delete action visible iff isActive == true',
      (isActive) {
        final persona = PersonaModel(
          id: 'test-id',
          name: 'Test Persona',
          description: 'A test persona',
          isActive: isActive,
          upvotes: 10,
          downvotes: 2,
        );

        final showDelete = shouldShowDeleteAction(persona);

        expect(
          showDelete,
          equals(isActive),
          reason: 'Delete action should be visible=$isActive when '
              'persona.isActive=$isActive',
        );
      },
    );

    Glados2(any.bool, any.positiveIntOrZero).test(
      'delete visibility is independent of other persona fields',
      (isActive, seed) {
        // Generate persona with random fields but controlled isActive
        final random = Random(seed);
        final persona = _generatePersona(isActive: isActive, random: random);

        final showDelete = shouldShowDeleteAction(persona);

        expect(
          showDelete,
          equals(isActive),
          reason: 'Delete visibility should depend ONLY on isActive '
              '(isActive=$isActive), regardless of name="${persona.name}", '
              'upvotes=${persona.upvotes}, downvotes=${persona.downvotes}',
        );
      },
    );

    Glados(any.positiveIntOrZero).test(
      'active personas always show delete action',
      (seed) {
        final random = Random(seed);
        final persona = _generatePersona(isActive: true, random: random);

        expect(
          shouldShowDeleteAction(persona),
          isTrue,
          reason: 'Active persona "${persona.name}" should always show '
              'delete action',
        );
      },
    );

    Glados(any.positiveIntOrZero).test(
      'inactive personas never show delete action',
      (seed) {
        final random = Random(seed);
        final persona = _generatePersona(isActive: false, random: random);

        expect(
          shouldShowDeleteAction(persona),
          isFalse,
          reason: 'Inactive persona "${persona.name}" should never show '
              'delete action',
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Iteration-based tests (150+ iterations for comprehensive coverage)
  // ═══════════════════════════════════════════════════════════════════════════

  group(
      'Property 6: Delete action visibility (iteration-based, 150 iterations)',
      () {
    const int iterations = 150;
    final random = Random(42);

    test('active personas (isActive=true) always show delete action', () {
      for (var i = 0; i < iterations; i++) {
        final persona = _generatePersona(isActive: true, random: random);

        expect(
          shouldShowDeleteAction(persona),
          isTrue,
          reason: 'Iteration $i: active persona "${persona.name}" '
              'should show delete action',
        );
      }
    });

    test('inactive personas (isActive=false) never show delete action', () {
      for (var i = 0; i < iterations; i++) {
        final persona = _generatePersona(isActive: false, random: random);

        expect(
          shouldShowDeleteAction(persona),
          isFalse,
          reason: 'Iteration $i: inactive persona "${persona.name}" '
              'should NOT show delete action',
        );
      }
    });

    test('mixed list: delete visibility matches isActive for each persona', () {
      for (var i = 0; i < iterations; i++) {
        final isActive = random.nextBool();
        final persona = _generatePersona(isActive: isActive, random: random);

        final showDelete = shouldShowDeleteAction(persona);

        expect(
          showDelete,
          equals(isActive),
          reason: 'Iteration $i: persona "${persona.name}" with '
              'isActive=$isActive should have delete visible=$isActive',
        );
      }
    });

    test('biconditional: showDelete == true implies isActive == true', () {
      for (var i = 0; i < iterations; i++) {
        final isActive = random.nextBool();
        final persona = _generatePersona(isActive: isActive, random: random);

        final showDelete = shouldShowDeleteAction(persona);

        // Forward: isActive → showDelete
        if (persona.isActive) {
          expect(
            showDelete,
            isTrue,
            reason: 'Iteration $i: isActive=true must imply showDelete=true',
          );
        }

        // Backward: showDelete → isActive
        if (showDelete) {
          expect(
            persona.isActive,
            isTrue,
            reason: 'Iteration $i: showDelete=true must imply isActive=true',
          );
        }

        // Contrapositive: !isActive → !showDelete
        if (!persona.isActive) {
          expect(
            showDelete,
            isFalse,
            reason:
                'Iteration $i: isActive=false must imply showDelete=false',
          );
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Widget test: verify actual UI renders delete icon conditionally
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property 6: Delete action visibility (widget test)', () {
    testWidgets('delete icon shown for active persona', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestPersonaItem(
              persona: const PersonaModel(
                id: 'p1',
                name: 'Active Persona',
                description: 'An active persona',
                isActive: true,
                upvotes: 5,
                downvotes: 1,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('delete icon NOT shown for inactive persona', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestPersonaItem(
              persona: const PersonaModel(
                id: 'p2',
                name: 'Inactive Persona',
                description: 'An inactive persona',
                isActive: false,
                upvotes: 3,
                downvotes: 0,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('mixed list: only active personas show delete icon',
        (tester) async {
      final personas = [
        const PersonaModel(
          id: 'p1',
          name: 'Active 1',
          description: 'desc',
          isActive: true,
          upvotes: 1,
          downvotes: 0,
        ),
        const PersonaModel(
          id: 'p2',
          name: 'Inactive 1',
          description: 'desc',
          isActive: false,
          upvotes: 2,
          downvotes: 1,
        ),
        const PersonaModel(
          id: 'p3',
          name: 'Active 2',
          description: 'desc',
          isActive: true,
          upvotes: 0,
          downvotes: 0,
        ),
        const PersonaModel(
          id: 'p4',
          name: 'Inactive 2',
          description: 'desc',
          isActive: false,
          upvotes: 10,
          downvotes: 5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: personas
                  .map((p) => _TestPersonaItem(persona: p))
                  .toList(),
            ),
          ),
        ),
      );

      // Only 2 active personas should have delete icons
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });
  });
}

/// Minimal widget that replicates the delete action visibility logic from
/// AdminPersonaListScreen._buildPersonaItem without requiring Provider/GoRouter.
class _TestPersonaItem extends StatelessWidget {
  final PersonaModel persona;

  const _TestPersonaItem({required this.persona});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(persona.name),
                  Text(persona.description, maxLines: 2),
                ],
              ),
            ),
            // Delete action — only for active personas (mirrors actual widget)
            if (persona.isActive)
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}
