import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'geometric_renderer.dart';

/// MoleculeRenderer: Chemistry visualization for molecular structures
///
/// Supports:
/// - Individual atoms with element-specific colors and sizing
/// - Chemical bonds (single, double, triple)
/// - Complete molecules with proper geometry
/// - Lewis structures (electron pairs)
/// - Common molecules: H₂O, CO₂, NH₃, CH₄, and custom molecules
///
/// Element colors follow standard chemistry conventions (JMOL colors)
///
/// Performance: <100ms for typical molecules
///
/// Example:
/// ```
/// // Draw water molecule
/// MoleculeRenderer.drawMolecule(
///   Molecule.water(),
///   origin: Point(100, 100),
/// )
/// ```
class MoleculeRenderer {
  static const double atomRadius = 15.0;
  static const double atomLabelFontSize = 12.0;
  static const double bondLineWidth = 2.0;
  static const double doubleBondSpacing = 4.0;
  static const double electronPairRadius = 3.0;

  MoleculeRenderer._(); // Prevent instantiation

  /// Draw a single atom
  ///
  /// Parameters:
  /// - atom: The atom to draw
  /// - position: Center position of the atom
  /// - showElectrons: Whether to show valence electrons as dots
  static Widget drawAtom(
    Atom atom,
    Point position, {
    bool showElectrons = false,
    double scale = 1.0,
  }) {
    return _MoleculePainter(
      shape: _SingleAtomShape(
        atom: atom,
        position: position,
        showElectrons: showElectrons,
        scale: scale,
      ),
    );
  }

  /// Draw a bond between two atoms
  ///
  /// Parameters:
  /// - from: Starting atom position
  /// - to: Ending atom position
  /// - bondType: Type of bond (single, double, triple)
  /// - color: Bond color (default black)
  static Widget drawBond(
    Point from,
    Point to,
    BondType bondType, {
    Color color = Colors.black,
  }) {
    return _MoleculePainter(
      shape: _BondShape(from: from, to: to, bondType: bondType, color: color),
    );
  }

  /// Draw a complete molecule
  ///
  /// Handles positioning and rendering of all atoms and bonds
  static Widget drawMolecule(
    Molecule molecule, {
    Point origin = const Point(200, 200),
    double scale = 1.0,
    bool showElectrons = false,
  }) {
    return _MoleculePainter(
      shape: _MoleculeShape(
        molecule: molecule,
        origin: origin,
        scale: scale,
        showElectrons: showElectrons,
      ),
    );
  }
}

// ============================================================================
// Enums and Data Classes
// ============================================================================

/// Bond type enumeration
enum BondType { single, double, triple }

/// Represents a chemical atom
class Atom {
  final String symbol; // e.g., 'H', 'C', 'N', 'O', 'S', 'P'
  final int atomicNumber;
  final int valenceElectrons;
  final Color color;
  final double radius;

  const Atom({
    required this.symbol,
    required this.atomicNumber,
    required this.valenceElectrons,
    required this.color,
    this.radius = MoleculeRenderer.atomRadius,
  });

  /// Get standard atom by symbol
  factory Atom.fromSymbol(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'H':
        return hydrogenAtom;
      case 'C':
        return carbonAtom;
      case 'N':
        return nitrogenAtom;
      case 'O':
        return oxygenAtom;
      case 'S':
        return sulfurAtom;
      case 'P':
        return phosphorusAtom;
      default:
        throw ArgumentError('Unknown atom symbol: $symbol');
    }
  }

  @override
  String toString() => symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Atom &&
          symbol == other.symbol &&
          atomicNumber == other.atomicNumber;

  @override
  int get hashCode => Object.hash(symbol, atomicNumber);
}

/// Standard atoms with chemistry colors
const Atom hydrogenAtom = Atom(
  symbol: 'H',
  atomicNumber: 1,
  valenceElectrons: 1,
  color: Color(0xFFFFFFFF), // White
);

const Atom carbonAtom = Atom(
  symbol: 'C',
  atomicNumber: 6,
  valenceElectrons: 4,
  color: Color(0xFF909090), // Gray
);

const Atom nitrogenAtom = Atom(
  symbol: 'N',
  atomicNumber: 7,
  valenceElectrons: 5,
  color: Color(0xFF3050F8), // Blue
);

const Atom oxygenAtom = Atom(
  symbol: 'O',
  atomicNumber: 8,
  valenceElectrons: 6,
  color: Color(0xFFFF0D0D), // Red
);

const Atom sulfurAtom = Atom(
  symbol: 'S',
  atomicNumber: 16,
  valenceElectrons: 6,
  color: Color(0xFFFFFF30), // Yellow
);

const Atom phosphorusAtom = Atom(
  symbol: 'P',
  atomicNumber: 15,
  valenceElectrons: 5,
  color: Color(0xFFFFA500), // Orange
);

/// Represents a chemical bond between atoms
class Bond {
  final int atomIndex1; // Index in molecule atoms list
  final int atomIndex2;
  final BondType type;

  const Bond({
    required this.atomIndex1,
    required this.atomIndex2,
    this.type = BondType.single,
  });

  @override
  String toString() => 'Bond($atomIndex1-$atomIndex2, $type)';
}

/// Represents a complete molecule with atoms and bonds
class Molecule {
  final String name;
  final List<Atom> atoms;
  final List<Bond> bonds;
  final List<Point> positions; // Positions of atoms
  final String? formula;

  Molecule({
    required this.name,
    required this.atoms,
    required this.bonds,
    required this.positions,
    this.formula,
  }) : assert(
         atoms.length == positions.length,
         'atoms and positions must have same length',
       );

  /// Water molecule (H₂O) - bent structure
  factory Molecule.water() {
    return Molecule(
      name: 'Water',
      formula: 'H₂O',
      atoms: [oxygenAtom, hydrogenAtom, hydrogenAtom],
      bonds: [
        Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.single),
        Bond(atomIndex1: 0, atomIndex2: 2, type: BondType.single),
      ],
      positions: [
        const Point(0, 0), // O at center
        const Point(-30, 25), // H left
        const Point(30, 25), // H right
      ],
    );
  }

  /// Carbon dioxide molecule (CO₂) - linear structure
  factory Molecule.carbonDioxide() {
    return Molecule(
      name: 'Carbon Dioxide',
      formula: 'CO₂',
      atoms: [oxygenAtom, carbonAtom, oxygenAtom],
      bonds: [
        Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.double),
        Bond(atomIndex1: 1, atomIndex2: 2, type: BondType.double),
      ],
      positions: [
        const Point(-50, 0), // O left
        const Point(0, 0), // C center
        const Point(50, 0), // O right
      ],
    );
  }

  /// Ammonia molecule (NH₃) - pyramidal structure
  factory Molecule.ammonia() {
    return Molecule(
      name: 'Ammonia',
      formula: 'NH₃',
      atoms: [nitrogenAtom, hydrogenAtom, hydrogenAtom, hydrogenAtom],
      bonds: [
        Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.single),
        Bond(atomIndex1: 0, atomIndex2: 2, type: BondType.single),
        Bond(atomIndex1: 0, atomIndex2: 3, type: BondType.single),
      ],
      positions: [
        const Point(0, -20), // N at top
        const Point(-35, 15), // H bottom-left
        const Point(35, 15), // H bottom-right
        const Point(0, 40), // H bottom
      ],
    );
  }

  /// Methane molecule (CH₄) - tetrahedral structure
  factory Molecule.methane() {
    return Molecule(
      name: 'Methane',
      formula: 'CH₄',
      atoms: [
        carbonAtom,
        hydrogenAtom,
        hydrogenAtom,
        hydrogenAtom,
        hydrogenAtom,
      ],
      bonds: [
        Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.single),
        Bond(atomIndex1: 0, atomIndex2: 2, type: BondType.single),
        Bond(atomIndex1: 0, atomIndex2: 3, type: BondType.single),
        Bond(atomIndex1: 0, atomIndex2: 4, type: BondType.single),
      ],
      positions: [
        const Point(0, 0), // C center
        const Point(0, -40), // H top
        const Point(35, 20), // H right
        const Point(-35, 20), // H left
        const Point(0, 50), // H bottom
      ],
    );
  }

  /// Hydrogen molecule (H₂)
  factory Molecule.hydrogen() {
    return Molecule(
      name: 'Hydrogen',
      formula: 'H₂',
      atoms: [hydrogenAtom, hydrogenAtom],
      bonds: [Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.single)],
      positions: [const Point(-25, 0), const Point(25, 0)],
    );
  }

  /// Oxygen molecule (O₂)
  factory Molecule.oxygen() {
    return Molecule(
      name: 'Oxygen',
      formula: 'O₂',
      atoms: [oxygenAtom, oxygenAtom],
      bonds: [Bond(atomIndex1: 0, atomIndex2: 1, type: BondType.double)],
      positions: [const Point(-30, 0), const Point(30, 0)],
    );
  }

  @override
  String toString() => '$name ($formula)';
}

// ============================================================================
// Internal shape classes (used by painter)
// ============================================================================

abstract class _MoleculeShapeBase {
  void paint(Canvas canvas, Size size);

  Rect getBounds();
}

/// Single atom visualization
class _SingleAtomShape extends _MoleculeShapeBase {
  final Atom atom;
  final Point position;
  final bool showElectrons;
  final double scale;

  _SingleAtomShape({
    required this.atom,
    required this.position,
    required this.showElectrons,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaledRadius = atom.radius * scale;

    // Draw atom circle
    final atomPaint = Paint()
      ..color = atom.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(position.x, position.y), scaledRadius, atomPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(position.x, position.y),
      scaledRadius,
      borderPaint,
    );

    // Draw symbol
    final textPainter = TextPainter(
      text: TextSpan(
        text: atom.symbol,
        style: const TextStyle(
          fontSize: MoleculeRenderer.atomLabelFontSize,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.x - textPainter.width / 2,
        position.y - textPainter.height / 2,
      ),
    );

    // Draw electron dots if requested
    if (showElectrons) {
      _drawValenceElectrons(canvas, scaledRadius);
    }
  }

  void _drawValenceElectrons(Canvas canvas, double radius) {
    final electronPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final count = atom.valenceElectrons;
    final angleStep = (2 * math.pi) / count;

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep;
      final x = position.x + (radius + 8) * math.cos(angle);
      final y = position.y + (radius + 8) * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        MoleculeRenderer.electronPairRadius,
        electronPaint,
      );
    }
  }

  @override
  Rect getBounds() {
    final scaledRadius = atom.radius * scale;
    return Rect.fromCircle(
      center: Offset(position.x, position.y),
      radius: scaledRadius + 20,
    );
  }
}

/// Bond visualization
class _BondShape extends _MoleculeShapeBase {
  final Point from;
  final Point to;
  final BondType bondType;
  final Color color;

  _BondShape({
    required this.from,
    required this.to,
    required this.bondType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = MoleculeRenderer.bondLineWidth
      ..strokeCap = StrokeCap.round;

    switch (bondType) {
      case BondType.single:
        _drawSingleBond(canvas, paint);
      case BondType.double:
        _drawDoubleBond(canvas, paint);
      case BondType.triple:
        _drawTripleBond(canvas, paint);
    }
  }

  void _drawSingleBond(Canvas canvas, Paint paint) {
    canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), paint);
  }

  void _drawDoubleBond(Canvas canvas, Paint paint) {
    // Calculate perpendicular offset
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length == 0) return;

    // Perpendicular vector
    final px = -dy / length;
    final py = dx / length;

    final spacing = MoleculeRenderer.doubleBondSpacing;

    // First bond
    canvas.drawLine(
      Offset(from.x + px * spacing, from.y + py * spacing),
      Offset(to.x + px * spacing, to.y + py * spacing),
      paint,
    );

    // Second bond
    canvas.drawLine(
      Offset(from.x - px * spacing, from.y - py * spacing),
      Offset(to.x - px * spacing, to.y - py * spacing),
      paint,
    );
  }

  void _drawTripleBond(Canvas canvas, Paint paint) {
    // Calculate perpendicular offset
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length == 0) return;

    // Perpendicular vector
    final px = -dy / length;
    final py = dx / length;

    final spacing = MoleculeRenderer.doubleBondSpacing;

    // Center bond
    canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), paint);

    // First offset bond
    canvas.drawLine(
      Offset(from.x + px * spacing, from.y + py * spacing),
      Offset(to.x + px * spacing, to.y + py * spacing),
      paint,
    );

    // Second offset bond
    canvas.drawLine(
      Offset(from.x - px * spacing, from.y - py * spacing),
      Offset(to.x - px * spacing, to.y - py * spacing),
      paint,
    );
  }

  @override
  Rect getBounds() {
    return Rect.fromPoints(
      Offset(from.x, from.y),
      Offset(to.x, to.y),
    ).inflate(20);
  }
}

/// Complete molecule visualization
class _MoleculeShape extends _MoleculeShapeBase {
  final Molecule molecule;
  final Point origin;
  final double scale;
  final bool showElectrons;

  _MoleculeShape({
    required this.molecule,
    required this.origin,
    required this.scale,
    required this.showElectrons,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw bonds first (so atoms appear on top)
    for (final bond in molecule.bonds) {
      final fromPos = molecule.positions[bond.atomIndex1];
      final toPos = molecule.positions[bond.atomIndex2];

      final scaledFrom = Point(
        origin.x + fromPos.x * scale,
        origin.y + fromPos.y * scale,
      );
      final scaledTo = Point(
        origin.x + toPos.x * scale,
        origin.y + toPos.y * scale,
      );

      _drawBond(canvas, scaledFrom, scaledTo, bond.type);
    }

    // Draw atoms
    for (int i = 0; i < molecule.atoms.length; i++) {
      final atom = molecule.atoms[i];
      final pos = molecule.positions[i];

      final scaledPos = Point(
        origin.x + pos.x * scale,
        origin.y + pos.y * scale,
      );

      _drawAtom(canvas, atom, scaledPos, showElectrons: showElectrons);
    }
  }

  void _drawBond(Canvas canvas, Point from, Point to, BondType type) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = MoleculeRenderer.bondLineWidth
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case BondType.single:
        canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), paint);
      case BondType.double:
        final dx = to.x - from.x;
        final dy = to.y - from.y;
        final length = math.sqrt(dx * dx + dy * dy);

        if (length > 0) {
          final px = -dy / length;
          final py = dx / length;
          final spacing = MoleculeRenderer.doubleBondSpacing;

          canvas.drawLine(
            Offset(from.x + px * spacing, from.y + py * spacing),
            Offset(to.x + px * spacing, to.y + py * spacing),
            paint,
          );

          canvas.drawLine(
            Offset(from.x - px * spacing, from.y - py * spacing),
            Offset(to.x - px * spacing, to.y - py * spacing),
            paint,
          );
        }
      case BondType.triple:
        final dx = to.x - from.x;
        final dy = to.y - from.y;
        final length = math.sqrt(dx * dx + dy * dy);

        if (length > 0) {
          final px = -dy / length;
          final py = dx / length;
          final spacing = MoleculeRenderer.doubleBondSpacing;

          canvas.drawLine(Offset(from.x, from.y), Offset(to.x, to.y), paint);

          canvas.drawLine(
            Offset(from.x + px * spacing, from.y + py * spacing),
            Offset(to.x + px * spacing, to.y + py * spacing),
            paint,
          );

          canvas.drawLine(
            Offset(from.x - px * spacing, from.y - py * spacing),
            Offset(to.x - px * spacing, to.y - py * spacing),
            paint,
          );
        }
    }
  }

  void _drawAtom(
    Canvas canvas,
    Atom atom,
    Point position, {
    required bool showElectrons,
  }) {
    final scaledRadius = atom.radius * scale;

    // Draw atom circle
    final atomPaint = Paint()
      ..color = atom.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(position.x, position.y), scaledRadius, atomPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(position.x, position.y),
      scaledRadius,
      borderPaint,
    );

    // Draw symbol
    final textPainter = TextPainter(
      text: TextSpan(
        text: atom.symbol,
        style: const TextStyle(
          fontSize: MoleculeRenderer.atomLabelFontSize,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.x - textPainter.width / 2,
        position.y - textPainter.height / 2,
      ),
    );

    if (showElectrons && atom.valenceElectrons > 0) {
      final electronPaint = Paint()..color = Colors.black;
      final electronDistance = scaledRadius + 8 * scale;
      for (var index = 0; index < atom.valenceElectrons; index++) {
        final angle = 2 * math.pi * index / atom.valenceElectrons;
        canvas.drawCircle(
          Offset(
            position.x + electronDistance * math.cos(angle),
            position.y + electronDistance * math.sin(angle),
          ),
          MoleculeRenderer.electronPairRadius * scale,
          electronPaint,
        );
      }
    }
  }

  @override
  Rect getBounds() {
    if (molecule.positions.isEmpty) {
      return Rect.fromLTWH(origin.x, origin.y, 100, 100);
    }

    double minX = origin.x;
    double maxX = origin.x;
    double minY = origin.y;
    double maxY = origin.y;

    for (final pos in molecule.positions) {
      final scaledX = origin.x + pos.x * scale;
      final scaledY = origin.y + pos.y * scale;

      minX = math.min(minX, scaledX);
      maxX = math.max(maxX, scaledX);
      minY = math.min(minY, scaledY);
      maxY = math.max(maxY, scaledY);
    }

    // Add padding for atom radius and label
    final padding = 50.0;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }
}

/// Main painter widget
class _MoleculePainter extends StatelessWidget {
  final _MoleculeShapeBase shape;

  const _MoleculePainter({required this.shape});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MoleculeCanvasPainter(shape),
      size: Size.infinite,
    );
  }
}

/// Canvas painter for molecules
class _MoleculeCanvasPainter extends CustomPainter {
  final _MoleculeShapeBase shape;

  _MoleculeCanvasPainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    shape.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _MoleculeCanvasPainter oldDelegate) {
    return oldDelegate.shape != shape;
  }
}
