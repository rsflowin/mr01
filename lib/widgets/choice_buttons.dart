import 'package:flutter/material.dart';
import '../models/event_model.dart';

/// Widget for displaying event choices as interactive buttons
///
/// Meets Requirements 4.2: Show all available choice options with their text
class ChoiceButtons extends StatefulWidget {
  /// The choices to display
  final List<Choice> choices;

  /// Callback when a choice is selected
  final void Function(int choiceIndex, Choice choice) onChoiceSelected;

  /// Optional function to determine if a choice is available
  final bool Function(Choice choice)? isChoiceAvailable;

  /// Optional custom styling for the widget
  final ChoiceButtonsStyle? style;

  /// Animation controller for entrance effects
  final AnimationController? animationController;

  /// Whether to show choice indices (for debugging/testing)
  final bool showChoiceIndices;

  const ChoiceButtons({
    super.key,
    required this.choices,
    required this.onChoiceSelected,
    this.isChoiceAvailable,
    this.style,
    this.animationController,
    this.showChoiceIndices = false,
  });

  @override
  State<ChoiceButtons> createState() => _ChoiceButtonsState();
}

class _ChoiceButtonsState extends State<ChoiceButtons>
    with TickerProviderStateMixin {
  List<AnimationController>? _buttonAnimationControllers;
  List<Animation<double>>? _buttonAnimations;
  int? _selectedChoiceIndex;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _buttonAnimationControllers?.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeAnimations() {
    if (widget.animationController == null) return;

    _buttonAnimationControllers = List.generate(
      widget.choices.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200 + (index * 100)),
        vsync: this,
      ),
    );

    _buttonAnimations = _buttonAnimationControllers!.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    // Start staggered animations
    for (int i = 0; i < _buttonAnimationControllers!.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _buttonAnimationControllers![i].forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? ChoiceButtonsStyle.defaultStyle();

    return Container(
      margin: style.containerMargin,
      padding: style.containerPadding,
      decoration: style.containerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional header
          if (style.showHeader) _buildHeader(style),

          // Choice buttons
          ...widget.choices.asMap().entries.map((entry) {
            final index = entry.key;
            final choice = entry.value;
            return _buildChoiceButton(index, choice, style);
          }).toList(),

          // Optional footer with choice count
          if (style.showChoiceCount) _buildFooter(style),
        ],
      ),
    );
  }

  Widget _buildHeader(ChoiceButtonsStyle style) {
    return Container(
      margin: EdgeInsets.only(bottom: style.spacingBetweenChoices),
      child: Text(
        style.headerText,
        style: style.headerTextStyle,
        textAlign: style.headerAlignment,
      ),
    );
  }

  Widget _buildChoiceButton(
    int index,
    Choice choice,
    ChoiceButtonsStyle style,
  ) {
    final isAvailable = widget.isChoiceAvailable?.call(choice) ?? true;
    final isSelected = _selectedChoiceIndex == index;
    final isProcessing = _isProcessing && isSelected;

    Widget button = Container(
      margin: EdgeInsets.only(
        bottom: index < widget.choices.length - 1
            ? style.spacingBetweenChoices
            : 0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: style.buttonBorderRadius,
          onTap: isAvailable && !_isProcessing
              ? () => _onChoicePressed(index, choice)
              : null,
          splashColor: style.splashColor,
          highlightColor: style.highlightColor,
          child: AnimatedContainer(
            duration: style.animationDuration,
            curve: style.animationCurve,
            padding: style.buttonPadding,
            decoration: _getButtonDecoration(
              style,
              isAvailable,
              isSelected,
              isProcessing,
            ),
            child: Row(
              children: [
                // Choice index (if enabled)
                if (widget.showChoiceIndices) _buildChoiceIndex(index, style),

                // Choice content
                Expanded(
                  child: _buildChoiceContent(choice, style, isAvailable),
                ),

                // Status indicator
                _buildStatusIndicator(style, isAvailable, isProcessing),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with animation if available
    if (_buttonAnimations != null && index < _buttonAnimations!.length) {
      return AnimatedBuilder(
        animation: _buttonAnimations![index],
        builder: (context, child) {
          return Transform.scale(
            scale: _buttonAnimations![index].value,
            child: Opacity(
              opacity: _buttonAnimations![index].value,
              child: child,
            ),
          );
        },
        child: button,
      );
    }

    return button;
  }

  Widget _buildChoiceIndex(int index, ChoiceButtonsStyle style) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: style.indexBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.indexBorderColor, width: 1),
      ),
      child: Center(child: Text('${index + 1}', style: style.indexTextStyle)),
    );
  }

  Widget _buildChoiceContent(
    Choice choice,
    ChoiceButtonsStyle style,
    bool isAvailable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Choice text
        Text(
          choice.text,
          style: isAvailable
              ? style.choiceTextStyle
              : style.disabledChoiceTextStyle,
        ),

        // Requirements hint (if choice is unavailable)
        if (!isAvailable && choice.requirements != null) ...[
          const SizedBox(height: 4),
          _buildRequirementsHint(choice, style),
        ],
      ],
    );
  }

  Widget _buildRequirementsHint(Choice choice, ChoiceButtonsStyle style) {
    final requirements = choice.requirements!;
    final hints = <String>[];

    // Item requirements
    if (requirements.containsKey('items')) {
      final items = requirements['items'] as List<String>;
      hints.add('Requires: ${items.join(', ')}');
    }

    // Stat requirements
    if (requirements.containsKey('stats')) {
      final stats = requirements['stats'] as Map<String, dynamic>;
      for (final entry in stats.entries) {
        final statName = entry.key;
        final condition = entry.value as Map<String, dynamic>;
        final operator = condition['operator'] as String;
        final value = condition['value'] as int;
        hints.add('$statName $operator $value');
      }
    }

    if (hints.isEmpty) return const SizedBox.shrink();

    return Text(hints.join(' • '), style: style.requirementsHintTextStyle);
  }

  Widget _buildStatusIndicator(
    ChoiceButtonsStyle style,
    bool isAvailable,
    bool isProcessing,
  ) {
    if (isProcessing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            style.processingIndicatorColor,
          ),
        ),
      );
    }

    if (!isAvailable) {
      return Icon(Icons.lock, size: 20, color: style.unavailableIndicatorColor);
    }

    return Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: style.availableIndicatorColor,
    );
  }

  Widget _buildFooter(ChoiceButtonsStyle style) {
    return Container(
      margin: EdgeInsets.only(top: style.spacingBetweenChoices),
      child: Text(
        '${widget.choices.length} choice${widget.choices.length == 1 ? '' : 's'} available',
        style: style.footerTextStyle,
        textAlign: style.footerAlignment,
      ),
    );
  }

  Decoration _getButtonDecoration(
    ChoiceButtonsStyle style,
    bool isAvailable,
    bool isSelected,
    bool isProcessing,
  ) {
    Color borderColor;
    Color backgroundColor;
    List<BoxShadow>? boxShadow;

    if (isProcessing) {
      borderColor = style.processingBorderColor;
      backgroundColor = style.processingBackgroundColor;
      boxShadow = style.processingBoxShadow;
    } else if (isSelected) {
      borderColor = style.selectedBorderColor;
      backgroundColor = style.selectedBackgroundColor;
      boxShadow = style.selectedBoxShadow;
    } else if (!isAvailable) {
      borderColor = style.disabledBorderColor;
      backgroundColor = style.disabledBackgroundColor;
      boxShadow = style.disabledBoxShadow;
    } else {
      borderColor = style.defaultBorderColor;
      backgroundColor = style.defaultBackgroundColor;
      boxShadow = style.defaultBoxShadow;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: style.buttonBorderRadius,
      border: Border.all(color: borderColor, width: style.buttonBorderWidth),
      boxShadow: boxShadow,
    );
  }

  void _onChoicePressed(int index, Choice choice) async {
    if (_isProcessing) return;

    setState(() {
      _selectedChoiceIndex = index;
      _isProcessing = true;
    });

    // Add a small delay to show the selection state
    await Future.delayed(const Duration(milliseconds: 200));

    // Call the callback
    widget.onChoiceSelected(index, choice);

    // Reset state after a delay (in case the widget doesn't get disposed)
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _selectedChoiceIndex = null;
            _isProcessing = false;
          });
        }
      });
    }
  }
}

/// Style configuration for ChoiceButtons widget
class ChoiceButtonsStyle {
  // Container styling
  final EdgeInsets containerMargin;
  final EdgeInsets containerPadding;
  final Decoration? containerDecoration;

  // Layout
  final double spacingBetweenChoices;
  final BorderRadius? buttonBorderRadius;
  final EdgeInsets buttonPadding;
  final double buttonBorderWidth;

  // Header and footer
  final bool showHeader;
  final String headerText;
  final TextStyle headerTextStyle;
  final TextAlign headerAlignment;
  final bool showChoiceCount;
  final TextStyle footerTextStyle;
  final TextAlign footerAlignment;

  // Text styling
  final TextStyle choiceTextStyle;
  final TextStyle disabledChoiceTextStyle;
  final TextStyle requirementsHintTextStyle;

  // Choice index styling
  final Color indexBackgroundColor;
  final Color indexBorderColor;
  final TextStyle indexTextStyle;

  // Button states
  final Color defaultBackgroundColor;
  final Color defaultBorderColor;
  final List<BoxShadow>? defaultBoxShadow;

  final Color selectedBackgroundColor;
  final Color selectedBorderColor;
  final List<BoxShadow>? selectedBoxShadow;

  final Color disabledBackgroundColor;
  final Color disabledBorderColor;
  final List<BoxShadow>? disabledBoxShadow;

  final Color processingBackgroundColor;
  final Color processingBorderColor;
  final List<BoxShadow>? processingBoxShadow;

  // Interaction styling
  final Color splashColor;
  final Color highlightColor;

  // Indicators
  final Color availableIndicatorColor;
  final Color unavailableIndicatorColor;
  final Color processingIndicatorColor;

  // Animation
  final Duration animationDuration;
  final Curve animationCurve;

  const ChoiceButtonsStyle({
    this.containerMargin = const EdgeInsets.all(16),
    this.containerPadding = const EdgeInsets.all(16),
    this.containerDecoration,
    this.spacingBetweenChoices = 12,
    this.buttonBorderRadius,
    this.buttonPadding = const EdgeInsets.all(16),
    this.buttonBorderWidth = 1,
    this.showHeader = false,
    this.headerText = 'Choose your action:',
    this.headerTextStyle = const TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    this.headerAlignment = TextAlign.center,
    this.showChoiceCount = false,
    this.footerTextStyle = const TextStyle(
      color: Color(0xFF888888),
      fontSize: 12,
    ),
    this.footerAlignment = TextAlign.center,
    this.choiceTextStyle = const TextStyle(
      color: Color(0xFFD4D4D4),
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    this.disabledChoiceTextStyle = const TextStyle(
      color: Color(0xFF666666),
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    this.requirementsHintTextStyle = const TextStyle(
      color: Color(0xFF999999),
      fontSize: 12,
      fontStyle: FontStyle.italic,
    ),
    this.indexBackgroundColor = const Color(0xFF444444),
    this.indexBorderColor = const Color(0xFF666666),
    this.indexTextStyle = const TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
    this.defaultBackgroundColor = const Color(0xFF2A2A2A),
    this.defaultBorderColor = const Color(0xFF8B0000),
    this.defaultBoxShadow,
    this.selectedBackgroundColor = const Color(0xFF3A2A2A),
    this.selectedBorderColor = const Color(0xFFAA0000),
    this.selectedBoxShadow,
    this.disabledBackgroundColor = const Color(0xFF1A1A1A),
    this.disabledBorderColor = const Color(0xFF444444),
    this.disabledBoxShadow,
    this.processingBackgroundColor = const Color(0xFF2A3A2A),
    this.processingBorderColor = const Color(0xFF00AA00),
    this.processingBoxShadow,
    this.splashColor = const Color(0xFF8B0000),
    this.highlightColor = const Color(0xFF8B0000),
    this.availableIndicatorColor = const Color(0xFF8B0000),
    this.unavailableIndicatorColor = const Color(0xFF666666),
    this.processingIndicatorColor = const Color(0xFF00AA00),
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
  });

  /// Default styling that matches the game's theme
  factory ChoiceButtonsStyle.defaultStyle() {
    return ChoiceButtonsStyle(
      containerDecoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF8B0000).withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      buttonBorderRadius: BorderRadius.circular(8),
      defaultBorderColor: const Color(0xFF8B0000).withOpacity(0.6),
      defaultBoxShadow: [
        BoxShadow(
          color: const Color(0xFF8B0000).withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      selectedBorderColor: const Color(0xFF8B0000),
      selectedBoxShadow: [
        BoxShadow(
          color: const Color(0xFF8B0000).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      splashColor: const Color(0xFF8B0000).withOpacity(0.3),
      highlightColor: const Color(0xFF8B0000).withOpacity(0.1),
    );
  }

  /// Compact styling for smaller displays
  factory ChoiceButtonsStyle.compact() {
    return ChoiceButtonsStyle(
      containerMargin: const EdgeInsets.all(8),
      containerPadding: const EdgeInsets.all(12),
      spacingBetweenChoices: 8,
      buttonPadding: const EdgeInsets.all(12),
      choiceTextStyle: const TextStyle(
        color: Color(0xFFD4D4D4),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      disabledChoiceTextStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      containerDecoration: BoxDecoration(color: const Color(0xFF1A1A1A)),
      buttonBorderRadius: BorderRadius.circular(6),
    );
  }

  /// Minimal styling for overlay displays
  factory ChoiceButtonsStyle.minimal() {
    return ChoiceButtonsStyle(
      containerMargin: EdgeInsets.symmetric(horizontal: 16),
      containerPadding: EdgeInsets.all(8),
      spacingBetweenChoices: 6,
      buttonPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      choiceTextStyle: TextStyle(
        color: Color(0xFFD4D4D4),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      disabledChoiceTextStyle: TextStyle(
        color: Color(0xFF666666),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      containerDecoration: BoxDecoration(color: Color(0xFF1A1A1A)),
      buttonBorderRadius: BorderRadius.circular(4),
      defaultBorderColor: Color(0xFF444444),
      selectedBorderColor: Color(0xFF666666),
    );
  }

  /// Copy this style with optional parameter overrides
  ChoiceButtonsStyle copyWith({
    EdgeInsets? containerMargin,
    EdgeInsets? containerPadding,
    Decoration? containerDecoration,
    double? spacingBetweenChoices,
    BorderRadius? buttonBorderRadius,
    EdgeInsets? buttonPadding,
    double? buttonBorderWidth,
    bool? showHeader,
    String? headerText,
    TextStyle? headerTextStyle,
    TextAlign? headerAlignment,
    bool? showChoiceCount,
    TextStyle? footerTextStyle,
    TextAlign? footerAlignment,
    TextStyle? choiceTextStyle,
    TextStyle? disabledChoiceTextStyle,
    TextStyle? requirementsHintTextStyle,
    Color? defaultBackgroundColor,
    Color? defaultBorderColor,
    List<BoxShadow>? defaultBoxShadow,
    Color? selectedBackgroundColor,
    Color? selectedBorderColor,
    List<BoxShadow>? selectedBoxShadow,
    Color? disabledBackgroundColor,
    Color? disabledBorderColor,
    List<BoxShadow>? disabledBoxShadow,
    Color? processingBackgroundColor,
    Color? processingBorderColor,
    List<BoxShadow>? processingBoxShadow,
    Color? splashColor,
    Color? highlightColor,
    Color? availableIndicatorColor,
    Color? unavailableIndicatorColor,
    Color? processingIndicatorColor,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return ChoiceButtonsStyle(
      containerMargin: containerMargin ?? this.containerMargin,
      containerPadding: containerPadding ?? this.containerPadding,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      spacingBetweenChoices:
          spacingBetweenChoices ?? this.spacingBetweenChoices,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonBorderWidth: buttonBorderWidth ?? this.buttonBorderWidth,
      showHeader: showHeader ?? this.showHeader,
      headerText: headerText ?? this.headerText,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      headerAlignment: headerAlignment ?? this.headerAlignment,
      showChoiceCount: showChoiceCount ?? this.showChoiceCount,
      footerTextStyle: footerTextStyle ?? this.footerTextStyle,
      footerAlignment: footerAlignment ?? this.footerAlignment,
      choiceTextStyle: choiceTextStyle ?? this.choiceTextStyle,
      disabledChoiceTextStyle:
          disabledChoiceTextStyle ?? this.disabledChoiceTextStyle,
      requirementsHintTextStyle:
          requirementsHintTextStyle ?? this.requirementsHintTextStyle,
      defaultBackgroundColor:
          defaultBackgroundColor ?? this.defaultBackgroundColor,
      defaultBorderColor: defaultBorderColor ?? this.defaultBorderColor,
      defaultBoxShadow: defaultBoxShadow ?? this.defaultBoxShadow,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      selectedBoxShadow: selectedBoxShadow ?? this.selectedBoxShadow,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledBoxShadow: disabledBoxShadow ?? this.disabledBoxShadow,
      processingBackgroundColor:
          processingBackgroundColor ?? this.processingBackgroundColor,
      processingBorderColor:
          processingBorderColor ?? this.processingBorderColor,
      processingBoxShadow: processingBoxShadow ?? this.processingBoxShadow,
      splashColor: splashColor ?? this.splashColor,
      highlightColor: highlightColor ?? this.highlightColor,
      availableIndicatorColor:
          availableIndicatorColor ?? this.availableIndicatorColor,
      unavailableIndicatorColor:
          unavailableIndicatorColor ?? this.unavailableIndicatorColor,
      processingIndicatorColor:
          processingIndicatorColor ?? this.processingIndicatorColor,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }
}
