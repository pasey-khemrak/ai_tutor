import 'package:flutter/material.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../visual_tutor_design.dart';
import 'board_element_renderer.dart';

/// RichMediaCanvas: Main widget that coordinates all visual media rendering
///
/// Handles:
/// - Responsive layout (adapts to any screen size)
/// - Dynamic positioning (% of board, not pixels)
/// - Sequential action rendering (with animation)
/// - ScrollView for large boards
/// - Gesture support (pan, zoom, tap)
///
/// Solves Phase 0.1 issues:
/// ✅ Responsive positioning (fixes off-screen content)
/// ✅ Dynamic layout (adapts to screen size)
/// ✅ Sequential rendering (step-by-step animation)
/// ✅ Performance optimization (RepaintBoundary)
class RichMediaCanvas extends StatefulWidget {
  const RichMediaCanvas({
    super.key,
    this.board,
    this.actions = const [],
    this.variant,
    this.finalAnswerLocked = true,
    this.compact = false,
    this.activeActionId,
    this.activeProgress = const AlwaysStoppedAnimation(1),
    this.reducedMotion = false,
    this.transitionsEnabled = true,
    this.selectedActionId,
    this.onStudentInteraction,
    this.minHeight = 400,
    this.maxHeight = 800,
    this.mediaChildren = const [],
  });

  /// Board entity containing metadata and configuration
  final VisualTutorBoardEntity? board;

  /// All board actions to render
  final List<VisualTutorBoardActionEntity> actions;

  /// Board variant (e.g., 'check_work', 'final_answer')
  final String? variant;

  /// Whether final answer is locked (student must work it out)
  final bool finalAnswerLocked;

  /// Compact mode (smaller spacing, no scrolling)
  final bool compact;

  /// Currently active action ID (for playback/timeline)
  final String? activeActionId;

  /// Progress animation for active action (0-1)
  final Animation<double> activeProgress;

  /// Reduced motion for accessibility
  final bool reducedMotion;

  /// Whether transitions are enabled
  final bool transitionsEnabled;

  /// Selected action ID (for highlighting)
  final String? selectedActionId;

  /// Callback for student interaction
  final ValueChanged<BoardStudentInteraction>? onStudentInteraction;

  /// Minimum height of canvas
  final double minHeight;

  /// Maximum height of canvas
  final double maxHeight;

  /// Subject-specific graph, geometry, vector, or molecule widgets displayed
  /// beneath board annotations and above the board-paper background.
  final List<Widget> mediaChildren;

  /// Max actions to render (guards against malformed data)
  static const int maxRenderedActions = 128;

  @override
  State<RichMediaCanvas> createState() => _RichMediaCanvasState();
}

class BoardStudentInteraction {
  const BoardStudentInteraction({
    required this.kind,
    required this.actionId,
    this.value,
  });

  final String kind;
  final String actionId;
  final String? value;
}

class _RichMediaCanvasState extends State<RichMediaCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  /// Track rendered actions to prevent overdraw
  final Set<String> _renderedActionIds = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Pre-calculate which actions will be rendered
    _updateRenderedActions();
  }

  @override
  void didUpdateWidget(covariant RichMediaCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateRenderedActions();
  }

  /// Update the set of actions to render
  void _updateRenderedActions() {
    _renderedActionIds.clear();

    // Only render up to max to prevent performance issues
    final actionCount = widget.actions.length.clamp(
      0,
      RichMediaCanvas.maxRenderedActions,
    );
    for (int i = 0; i < actionCount; i++) {
      final action = widget.actions[i];
      if (!action.hidden) {
        _renderedActionIds.add(action.id);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildResponsiveBoard(constraints),
    );
  }

  /// Build responsive board that adapts to available space
  Widget _buildResponsiveBoard(BoxConstraints constraints) {
    // Calculate actual dimensions
    final boardWidth = constraints.maxWidth;
    final boardHeight = (constraints.maxHeight)
        .clamp(widget.minHeight, widget.maxHeight)
        .toDouble();

    // Estimate content height based on actions
    final estimatedHeight = _estimateContentHeight(boardWidth, boardHeight);
    final needsScroll = estimatedHeight > boardHeight;

    return InteractiveViewer(
      minScale: 0.75,
      maxScale: 3,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          width: boardWidth,
          child: BoardPaperScaffold(
            showLines: true,
            compact: widget.compact,
            child: _buildBoardContent(boardWidth, boardHeight, needsScroll),
          ),
        ),
      ),
    );
  }

  /// Build the actual board content
  Widget _buildBoardContent(
    double boardWidth,
    double boardHeight,
    bool needsScroll,
  ) {
    // Use Stack with Positioned for absolute positioning
    return Stack(
      clipBehavior: Clip.none, // Allow elements to extend beyond bounds
      children: [
        // Render all visible actions
        for (final action in widget.actions.take(
          RichMediaCanvas.maxRenderedActions,
        ))
          if (!action.hidden && _renderedActionIds.contains(action.id))
            _buildPositionedAction(action, boardWidth, boardHeight),

        for (final media in widget.mediaChildren) RepaintBoundary(child: media),

        // Optional: resize handle or scroll indicator if content overflows
        if (needsScroll && !widget.compact)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Container(
              color: VisualTutorColors.boardPaperDot,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }

  /// Build a single action as Positioned widget
  Widget _buildPositionedAction(
    VisualTutorBoardActionEntity action,
    double boardWidth,
    double boardHeight,
  ) {
    // Calculate responsive position (% of board, not pixels)
    final x = _calculatePosition(action.x, boardWidth);
    final y = _calculatePosition(action.y, boardHeight);
    final width = _calculateDimension(action.width, boardWidth);
    final height = _calculateDimension(action.height, boardHeight);

    // Determine if action is selected
    final isSelected = widget.selectedActionId == action.id;
    final isActive = widget.activeActionId == action.id;

    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: _buildActionWithAnimation(
        action,
        isSelected,
        isActive,
        width,
        height,
      ),
    );
  }

  /// Build action with animation wrapper
  Widget _buildActionWithAnimation(
    VisualTutorBoardActionEntity action,
    bool isSelected,
    bool isActive,
    double width,
    double height,
  ) {
    // Wrap with animation if this is the active action
    if (isActive && !widget.reducedMotion) {
      return AnimatedBuilder(
        animation: widget.activeProgress,
        builder: (context, child) => _buildActionContent(
          action,
          isSelected,
          width,
          height,
          widget.activeProgress.value,
        ),
      );
    }

    return _buildActionContent(
      action,
      isSelected,
      width,
      height,
      1.0, // Always fully visible if not active
    );
  }

  /// Build the actual action content
  Widget _buildActionContent(
    VisualTutorBoardActionEntity action,
    bool isSelected,
    double width,
    double height,
    double animationProgress,
  ) {
    // Use RepaintBoundary to optimize re-paints
    return RepaintBoundary(
      child: Stack(
        children: [
          // Selection highlight (if selected)
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: VisualTutorColors.cyan, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

          // Main action renderer
          BoardElementRenderer(
            action: action,
            scale: 1.0,
            faded: false,
            progress: AlwaysStoppedAnimation(animationProgress),
            reducedMotion: widget.reducedMotion,
          ),
        ],
      ),
    );
  }

  /// Calculate responsive X/Y position
  ///
  /// If action.x is >= 0 and <= 100, treat as percentage of dimension
  /// Otherwise, treat as absolute pixels (legacy support)
  double _calculatePosition(double? position, double dimensionSize) {
    if (position == null) return 0;

    // If position is in range [0, 100], treat as percentage
    if (position >= 0 && position <= 100) {
      return (position / 100) * dimensionSize;
    }

    // Otherwise, assume pixels (legacy)
    // But clamp to avoid off-screen positioning
    return position.clamp(0, dimensionSize);
  }

  /// Calculate responsive width/height
  double _calculateDimension(double? dimension, double availableSize) {
    if (dimension == null) {
      return availableSize * 0.8; // Default: 80% of available
    }

    // If dimension is in range [0, 100], treat as percentage
    if (dimension >= 0 && dimension <= 100) {
      return (dimension / 100) * availableSize;
    }

    // Otherwise, assume pixels (legacy)
    // But clamp to available size
    return dimension.clamp(0, availableSize);
  }

  /// Estimate content height based on actions
  ///
  /// Simple heuristic: find max (y + height) of all actions
  double _estimateContentHeight(double boardWidth, double boardHeight) {
    double maxBottom = boardHeight;

    for (final action in widget.actions) {
      final y = _calculatePosition(action.y, boardHeight);
      final height = _calculateDimension(action.height, boardHeight);
      final bottom = y + height;

      if (bottom > maxBottom) {
        maxBottom = bottom;
      }
    }

    // Add padding at bottom
    return maxBottom + 40;
  }
}

/// Extension on VisualTutorBoardActionEntity for easier access
extension RichMediaCanvasExtension on VisualTutorBoardActionEntity {
  /// Check if action is a shape type (needs special rendering)
  bool get isShapeType {
    return const [
      'circle',
      'cross_out',
      'draw_line',
      'draw_rectangle',
      'draw_arrow',
      'draw_axes',
    ].contains(type);
  }

  /// Check if action is a text/annotation type
  bool get isTextType {
    return const [
      'write_text',
      'write_equation',
      'write_expression',
      'highlight',
      'draw_point',
    ].contains(type);
  }

  /// Check if action is a table/data type
  bool get isDataType {
    return const ['show_table', 'show_list'].contains(type);
  }
}
