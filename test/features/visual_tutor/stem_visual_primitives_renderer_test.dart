import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/semantic_board_layout.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_element_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const primitives = <VisualTutorBoardActionEntity>[
    VisualTutorBoardActionEntity(
      id: 'forces',
      type: 'draw_free_body_diagram',
      sequenceIndex: 0,
      layoutZone: 'visual',
      layoutFlow: 'diagram',
      metadata: {
        'object_label': 'Block',
        'forces': [
          {'direction': 'up', 'label': 'N', 'magnitude': 1.2},
          {'direction': 'down', 'label': 'W', 'magnitude': 1.2},
        ],
        'alt': 'Free-body diagram of a block with normal and weight forces',
      },
    ),
    VisualTutorBoardActionEntity(
      id: 'water',
      type: 'draw_molecule',
      sequenceIndex: 1,
      layoutZone: 'visual',
      layoutFlow: 'diagram',
      metadata: {
        'atoms': [
          {'symbol': 'O', 'x': .5, 'y': .4},
          {'symbol': 'H', 'x': .25, 'y': .75},
          {'symbol': 'H', 'x': .75, 'y': .75},
        ],
        'bonds': [
          {'from': 0, 'to': 1, 'order': 1},
          {'from': 0, 'to': 2, 'order': 1},
        ],
        'alt':
            'Water molecule with one oxygen atom bonded to two hydrogen atoms',
      },
    ),
    VisualTutorBoardActionEntity(
      id: 'wave',
      type: 'draw_wave',
      sequenceIndex: 2,
      layoutZone: 'visual',
      layoutFlow: 'diagram',
      metadata: {
        'cycles': 2,
        'amplitude_label': 'Amplitude',
        'wavelength_label': 'Wavelength',
        'alt': 'Transverse wave showing amplitude and wavelength',
      },
    ),
  ];

  Widget primitiveCanvas({
    required VisualTutorBoardActionEntity action,
    required Animation<double> progress,
    Key? repaintBoundaryKey,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: RepaintBoundary(
          key: repaintBoundaryKey,
          child: SizedBox(
            width: 360,
            height: 260,
            child: Stack(
              children: [
                BoardElementRenderer(action: action, progress: progress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  test('semantic STEM visuals receive safe responsive diagram boxes', () {
    final phone = SemanticBoardLayout.resolve(
      actions: primitives,
      textDirection: TextDirection.ltr,
      viewport: const Size(360, 640),
    );
    final tablet = SemanticBoardLayout.resolve(
      actions: primitives,
      textDirection: TextDirection.ltr,
      viewport: const Size(900, 640),
    );

    for (final action in phone) {
      expect(action.x, greaterThanOrEqualTo(0), reason: action.id);
      expect(action.width, lessThanOrEqualTo(320), reason: action.id);
      expect(action.height, greaterThan(100), reason: action.id);
    }
    // A tablet visual zone is placed in the secondary teaching area.
    expect(tablet.first.x, greaterThan(tablet.first.width!));
  });

  testWidgets('renders STEM primitives with deterministic keys and labels', (
    tester,
  ) async {
    final resolved = SemanticBoardLayout.resolve(
      actions: primitives,
      textDirection: TextDirection.ltr,
      viewport: const Size(360, 640),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: Stack(
              children: [
                for (final action in resolved)
                  BoardElementRenderer(action: action),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('teaching-board-fbd-forces')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Free-body diagram of a block with normal and weight forces',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('teaching-board-molecule-water')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Water molecule with one oxygen atom bonded to two hydrogen atoms',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('teaching-board-wave-wave')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Transverse wave showing amplitude and wavelength'),
      findsOneWidget,
    );
  });

  testWidgets('renders bounded atom, particle, circuit, and reaction visuals', (
    tester,
  ) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'atom',
        type: 'draw_atom_model',
        x: 0,
        y: 0,
        width: 160,
        height: 120,
        metadata: {
          'atom_model': {
            'symbol': 'Na',
            'protons': 11,
            'neutrons': 12,
            'electrons_per_shell': [2, 8, 1],
          },
        },
      ),
      VisualTutorBoardActionEntity(
        id: 'particles',
        type: 'draw_particle_diagram',
        x: 180,
        y: 0,
        width: 160,
        height: 120,
        metadata: {
          'particle_diagram': {
            'state': 'gas',
            'particle_count': 8,
            'particle_label': 'oxygen',
          },
        },
      ),
      VisualTutorBoardActionEntity(
        id: 'circuit',
        type: 'draw_circuit_diagram',
        x: 0,
        y: 130,
        width: 160,
        height: 120,
        metadata: {
          'circuit_diagram': {
            'components': [
              {'kind': 'cell'},
              {'kind': 'lamp'},
            ],
          },
        },
      ),
      VisualTutorBoardActionEntity(
        id: 'reaction',
        type: 'show_reaction_layout',
        x: 180,
        y: 130,
        width: 160,
        height: 120,
        metadata: {
          'reaction_layout': {
            'reactants': ['H2', 'O2'],
            'products': ['H2O'],
            'coefficients': [2, 1, 2],
          },
        },
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 260,
            child: Stack(
              children: [
                for (final action in actions)
                  BoardElementRenderer(action: action),
              ],
            ),
          ),
        ),
      ),
    );
    for (final action in actions) {
      expect(
        find.byKey(Key('teaching-board-${action.type}-${action.id}')),
        findsOneWidget,
      );
    }
    expect(find.bySemanticsLabel('Series circuit diagram'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Chemical reaction balancing layout'),
      findsOneWidget,
    );
  });

  testWidgets('STEM diagrams bind progressive reveal to playback progress', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 400),
      value: 0,
    );
    addTearDown(controller.dispose);

    for (final action in primitives) {
      await tester.pumpWidget(
        primitiveCanvas(
          action: action.copyWith(x: 20, y: 20, width: 300, height: 200),
          progress: controller,
        ),
      );
      final reveal = find.byType(Align);
      expect(tester.widget<Align>(reveal).widthFactor, .001);
      controller.value = .5;
      await tester.pump();
      expect(tester.widget<Align>(reveal).widthFactor, .5);
      controller.value = 1;
      await tester.pump();
      expect(tester.widget<Align>(reveal).widthFactor, 1);
      controller.value = 0;
      await tester.pump();
    }
  });
}
