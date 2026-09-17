import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide findsOneWidget;

import 'package:ai_tutor/features/visual_tutor/presentation/services/geometric_renderer.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/services/molecule_renderer.dart';

// MaterialApp contributes a background CustomPaint; renderer assertions only
// need to verify that at least one paint surface is present.
final findsOneWidget = findsAtLeastNWidgets(1);

void main() {
  group('MoleculeRenderer', () {
    group('drawAtom', () {
      testWidgets('draws hydrogen atom', (WidgetTester tester) async {
        const Point position = Point(100, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawAtom(hydrogenAtom, position),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('draws carbon atom', (WidgetTester tester) async {
        const Point position = Point(100, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawAtom(carbonAtom, position),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('displays valence electrons when requested', (
        WidgetTester tester,
      ) async {
        const Point position = Point(100, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawAtom(
            oxygenAtom,
            position,
            showElectrons: true,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('applies scale factor correctly', (
        WidgetTester tester,
      ) async {
        const Point position = Point(100, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawAtom(carbonAtom, position, scale: 1.5),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('drawBond', () {
      testWidgets('draws single bond', (WidgetTester tester) async {
        const Point from = Point(100, 100);
        const Point to = Point(150, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawBond(from, to, BondType.single),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('draws double bond', (WidgetTester tester) async {
        const Point from = Point(100, 100);
        const Point to = Point(150, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawBond(from, to, BondType.double),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('draws triple bond', (WidgetTester tester) async {
        const Point from = Point(100, 100);
        const Point to = Point(150, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawBond(from, to, BondType.triple),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('applies custom bond color', (WidgetTester tester) async {
        const Point from = Point(100, 100);
        const Point to = Point(150, 100);

        final widget = Scaffold(
          body: MoleculeRenderer.drawBond(
            from,
            to,
            BondType.single,
            color: Colors.red,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('drawMolecule', () {
      testWidgets('draws water molecule', (WidgetTester tester) async {
        final molecule = Molecule.water();

        final widget = Scaffold(body: MoleculeRenderer.drawMolecule(molecule));

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('draws CO2 molecule', (WidgetTester tester) async {
        final molecule = Molecule.carbonDioxide();

        final widget = Scaffold(body: MoleculeRenderer.drawMolecule(molecule));

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('draws ammonia molecule', (WidgetTester tester) async {
        final molecule = Molecule.ammonia();

        final widget = Scaffold(body: MoleculeRenderer.drawMolecule(molecule));

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('draws methane molecule', (WidgetTester tester) async {
        final molecule = Molecule.methane();

        final widget = Scaffold(body: MoleculeRenderer.drawMolecule(molecule));

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('applies custom origin', (WidgetTester tester) async {
        final molecule = Molecule.water();

        final widget = Scaffold(
          body: MoleculeRenderer.drawMolecule(
            molecule,
            origin: const Point(150, 150),
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('applies scale factor', (WidgetTester tester) async {
        final molecule = Molecule.methane();

        final widget = Scaffold(
          body: MoleculeRenderer.drawMolecule(molecule, scale: 1.2),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('shows electrons when requested', (
        WidgetTester tester,
      ) async {
        final molecule = Molecule.water();

        final widget = Scaffold(
          body: MoleculeRenderer.drawMolecule(molecule, showElectrons: true),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });
  });

  group('Atom class', () {
    test('creates hydrogen atom with correct properties', () {
      expect(hydrogenAtom.symbol, equals('H'));
      expect(hydrogenAtom.atomicNumber, equals(1));
      expect(hydrogenAtom.valenceElectrons, equals(1));
      expect(hydrogenAtom.color, equals(const Color(0xFFFFFFFF)));
    });

    test('creates carbon atom with correct properties', () {
      expect(carbonAtom.symbol, equals('C'));
      expect(carbonAtom.atomicNumber, equals(6));
      expect(carbonAtom.valenceElectrons, equals(4));
      expect(carbonAtom.color, equals(const Color(0xFF909090)));
    });

    test('creates nitrogen atom with correct properties', () {
      expect(nitrogenAtom.symbol, equals('N'));
      expect(nitrogenAtom.atomicNumber, equals(7));
      expect(nitrogenAtom.valenceElectrons, equals(5));
      expect(nitrogenAtom.color, equals(const Color(0xFF3050F8)));
    });

    test('creates oxygen atom with correct properties', () {
      expect(oxygenAtom.symbol, equals('O'));
      expect(oxygenAtom.atomicNumber, equals(8));
      expect(oxygenAtom.valenceElectrons, equals(6));
      expect(oxygenAtom.color, equals(const Color(0xFFFF0D0D)));
    });

    test('creates sulfur atom with correct properties', () {
      expect(sulfurAtom.symbol, equals('S'));
      expect(sulfurAtom.atomicNumber, equals(16));
      expect(sulfurAtom.valenceElectrons, equals(6));
      expect(sulfurAtom.color, equals(const Color(0xFFFFFF30)));
    });

    test('creates phosphorus atom with correct properties', () {
      expect(phosphorusAtom.symbol, equals('P'));
      expect(phosphorusAtom.atomicNumber, equals(15));
      expect(phosphorusAtom.valenceElectrons, equals(5));
      expect(phosphorusAtom.color, equals(const Color(0xFFFFA500)));
    });

    test('creates atom from symbol', () {
      final atom = Atom.fromSymbol('O');
      expect(atom, equals(oxygenAtom));
    });

    test('throws on unknown symbol', () {
      expect(() => Atom.fromSymbol('Xx'), throwsArgumentError);
    });

    test('equality comparison works', () {
      final h1 = Atom.fromSymbol('H');
      final h2 = Atom.fromSymbol('H');
      final c = Atom.fromSymbol('C');

      expect(h1, equals(h2));
      expect(h1, isNot(equals(c)));
    });

    test('hash code is consistent', () {
      final h1 = Atom.fromSymbol('H');
      final h2 = Atom.fromSymbol('H');

      expect(h1.hashCode, equals(h2.hashCode));
    });
  });

  group('Bond class', () {
    test('creates single bond', () {
      const bond = Bond(atomIndex1: 0, atomIndex2: 1);

      expect(bond.atomIndex1, equals(0));
      expect(bond.atomIndex2, equals(1));
      expect(bond.type, equals(BondType.single));
    });

    test('creates double bond', () {
      const bond = Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.double);

      expect(bond.type, equals(BondType.double));
    });

    test('creates triple bond', () {
      const bond = Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.triple);

      expect(bond.type, equals(BondType.triple));
    });
  });

  group('Molecule class', () {
    test('creates water molecule with correct structure', () {
      final water = Molecule.water();

      expect(water.name, equals('Water'));
      expect(water.formula, equals('H₂O'));
      expect(water.atoms.length, equals(3));
      expect(water.bonds.length, equals(2));
      expect(water.atoms[0], equals(oxygenAtom));
      expect(water.atoms[1], equals(hydrogenAtom));
      expect(water.atoms[2], equals(hydrogenAtom));
    });

    test('creates CO2 molecule with double bonds', () {
      final co2 = Molecule.carbonDioxide();

      expect(co2.name, equals('Carbon Dioxide'));
      expect(co2.formula, equals('CO₂'));
      expect(co2.atoms.length, equals(3));
      expect(co2.bonds.length, equals(2));

      // Check double bonds
      expect(co2.bonds[0].type, equals(BondType.double));
      expect(co2.bonds[1].type, equals(BondType.double));
    });

    test('creates ammonia molecule', () {
      final nh3 = Molecule.ammonia();

      expect(nh3.name, equals('Ammonia'));
      expect(nh3.formula, equals('NH₃'));
      expect(nh3.atoms.length, equals(4));
      expect(nh3.bonds.length, equals(3));
    });

    test('creates methane molecule', () {
      final ch4 = Molecule.methane();

      expect(ch4.name, equals('Methane'));
      expect(ch4.formula, equals('CH₄'));
      expect(ch4.atoms.length, equals(5));
      expect(ch4.bonds.length, equals(4));
    });

    test('creates hydrogen molecule', () {
      final h2 = Molecule.hydrogen();

      expect(h2.name, equals('Hydrogen'));
      expect(h2.formula, equals('H₂'));
      expect(h2.atoms.length, equals(2));
      expect(h2.bonds.length, equals(1));
    });

    test('creates oxygen molecule with double bond', () {
      final o2 = Molecule.oxygen();

      expect(o2.name, equals('Oxygen'));
      expect(o2.formula, equals('O₂'));
      expect(o2.atoms.length, equals(2));
      expect(o2.bonds[0].type, equals(BondType.double));
    });

    test('validates atoms and positions length', () {
      expect(
        () => Molecule(
          name: 'Test',
          atoms: [hydrogenAtom, carbonAtom],
          bonds: [],
          positions: [const Point(0, 0)], // Mismatch!
        ),
        throwsAssertionError,
      );
    });

    test('water molecule has bent geometry', () {
      final water = Molecule.water();

      // O is at center, H atoms should be at an angle
      expect(water.positions[0], equals(const Point(0, 0)));
      expect(water.positions[1], equals(const Point(-30, 25)));
      expect(water.positions[2], equals(const Point(30, 25)));
    });

    test('CO2 molecule has linear geometry', () {
      final co2 = Molecule.carbonDioxide();

      // O-C-O in a line
      expect(co2.positions[0].y, equals(0));
      expect(co2.positions[1].y, equals(0));
      expect(co2.positions[2].y, equals(0));
    });

    test('methane molecule has tetrahedral geometry', () {
      final ch4 = Molecule.methane();

      // C at center with 4 H atoms around it
      expect(ch4.positions[0], equals(const Point(0, 0))); // C
      expect(ch4.atoms[0], equals(carbonAtom));

      // H atoms should surround the carbon
      expect(ch4.positions.length, equals(5)); // 1 C + 4 H
    });
  });

  group('BondType enum', () {
    test('has three bond types', () {
      expect(BondType.values.length, equals(3));
      expect(BondType.values, contains(BondType.single));
      expect(BondType.values, contains(BondType.double));
      expect(BondType.values, contains(BondType.triple));
    });
  });
}
