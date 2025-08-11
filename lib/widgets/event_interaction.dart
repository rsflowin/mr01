import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_processor.dart';
import 'event_display.dart';
import 'choice_buttons.dart';

/// A complete event interaction widget that combines event display and choice handling
///
/// This widget integrates EventDisplay and ChoiceButtons with EventProcessor
/// to provide a complete event interaction experience.
class EventInteraction extends StatefulWidget {
  /// The event processor for handling choice validation and effects
  final EventProcessor eventProcessor;

  /// The event to display and interact with
  final Event event;

  /// Current player state for choice validation
  final Map<String, dynamic> playerState;

  /// Callback when a choice is selected and processed
  final void Function(Map<String, dynamic> result) onChoiceProcessed;

  /// Optional custom styling
  final EventInteractionStyle? style;

  /// Whether to enable animations
  final bool enableAnimations;

  const EventInteraction({
    super.key,
    required this.eventProcessor,
    required this.event,
    required this.playerState,
    required this.onChoiceProcessed,
    this.style,
    this.enableAnimations = true,
  });

  @override
  State<EventInteraction> createState() => _EventInteractionState();
}

class _EventInteractionState extends State<EventInteraction>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _choiceAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isProcessingChoice = false;
  String? _processingMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.enableAnimations) {
      _mainAnimationController.forward();

      // Delay choice animations slightly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _choiceAnimationController.forward();
        }
      });
    } else {
      _mainAnimationController.value = 1.0;
      _choiceAnimationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _choiceAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _choiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? EventInteractionStyle.defaultStyle();

    return AnimatedBuilder(
      animation: _mainAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: style.containerDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Event display section
                  Expanded(
                    flex: style.eventDisplayFlex,
                    child: _buildEventDisplaySection(style),
                  ),

                  // Processing overlay (if active)
                  if (_isProcessingChoice) _buildProcessingOverlay(style),

                  // Choice buttons section
                  if (!_isProcessingChoice) _buildChoiceButtonsSection(style),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventDisplaySection(EventInteractionStyle style) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: EventDisplay(
        event: widget.event,
        style: style.eventDisplayStyle,
        animationController: widget.enableAnimations
            ? _mainAnimationController
            : null,
      ),
    );
  }

  Widget _buildChoiceButtonsSection(EventInteractionStyle style) {
    return ChoiceButtons(
      choices: widget.event.choices,
      onChoiceSelected: _handleChoiceSelection,
      isChoiceAvailable: _isChoiceAvailable,
      style: style.choiceButtonsStyle,
      animationController: widget.enableAnimations
          ? _choiceAnimationController
          : null,
    );
  }

  Widget _buildProcessingOverlay(EventInteractionStyle style) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: style.processingOverlayDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Processing indicator
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              style.processingIndicatorColor,
            ),
          ),

          const SizedBox(height: 16),

          // Processing message
          Text(
            _processingMessage ?? 'Processing your choice...',
            style: style.processingMessageStyle,
            textAlign: TextAlign.center,
          ),

          // Optional animation or flavor text
          if (style.showProcessingAnimation) ...[
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 2000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                final dots = '.' * ((value * 3).round() + 1);
                return Text(
                  'Calculating effects$dots',
                  style: style.processingSubtextStyle,
                );
              },
              onEnd: () {
                // Restart the animation
                if (mounted && _isProcessingChoice) {
                  setState(() {});
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  bool _isChoiceAvailable(Choice choice) {
    return widget.eventProcessor.validateChoiceRequirements(
      choice,
      widget.playerState,
    );
  }

  void _handleChoiceSelection(int choiceIndex, Choice choice) async {
    if (_isProcessingChoice) return;

    setState(() {
      _isProcessingChoice = true;
      _processingMessage = _getProcessingMessage(choice);
    });

    try {
      // Simulate some processing time for better UX
      await Future.delayed(const Duration(milliseconds: 800));

      // Process the choice using EventProcessor
      final result = widget.eventProcessor.processChoiceSelection(
        widget.event,
        choiceIndex,
        widget.playerState,
        // Note: In real usage, this would come from the room state
        // For now, we create a placeholder room event data
        _createPlaceholderRoomEventData(),
      );

      // Add some additional UI-specific data to the result
      final enhancedResult = {
        ...result,
        'choiceIndex': choiceIndex,
        'choiceText': choice.text,
        'eventId': widget.event.id,
        'eventName': widget.event.name,
      };

      // Call the callback with the result
      widget.onChoiceProcessed(enhancedResult);
    } catch (e) {
      // Handle errors gracefully
      final errorResult = {
        'error': true,
        'errorMessage': e.toString(),
        'choiceIndex': choiceIndex,
        'eventId': widget.event.id,
      };

      widget.onChoiceProcessed(errorResult);
    }
  }

  // Helper method to create placeholder room event data
  // In real usage, this would be provided by the calling context
  dynamic _createPlaceholderRoomEventData() {
    // This is a simplified placeholder - in practice this would come from
    // the game state management system
    return null; // EventProcessor handles null room data gracefully
  }

  String _getProcessingMessage(Choice choice) {
    // Generate contextual processing messages based on choice content
    final text = choice.text.toLowerCase();

    if (text.contains('attack') || text.contains('fight')) {
      return 'Preparing for combat...';
    } else if (text.contains('run') || text.contains('flee')) {
      return 'Making your escape...';
    } else if (text.contains('search') || text.contains('investigate')) {
      return 'Searching carefully...';
    } else if (text.contains('use') || text.contains('item')) {
      return 'Using item...';
    } else if (text.contains('talk') || text.contains('speak')) {
      return 'Engaging in conversation...';
    } else if (text.contains('rest') || text.contains('sleep')) {
      return 'Taking a moment to rest...';
    } else {
      return 'Processing your choice...';
    }
  }
}

/// Style configuration for EventInteraction widget
class EventInteractionStyle {
  final Decoration? containerDecoration;
  final int eventDisplayFlex;
  final EventDisplayStyle? eventDisplayStyle;
  final ChoiceButtonsStyle? choiceButtonsStyle;

  // Processing overlay styling
  final Decoration? processingOverlayDecoration;
  final Color processingIndicatorColor;
  final TextStyle processingMessageStyle;
  final TextStyle processingSubtextStyle;
  final bool showProcessingAnimation;

  const EventInteractionStyle({
    this.containerDecoration,
    this.eventDisplayFlex = 3,
    this.eventDisplayStyle,
    this.choiceButtonsStyle,
    this.processingOverlayDecoration,
    this.processingIndicatorColor = const Color(0xFF8B0000),
    this.processingMessageStyle = const TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    this.processingSubtextStyle = const TextStyle(
      color: Color(0xFF999999),
      fontSize: 12,
    ),
    this.showProcessingAnimation = true,
  });

  /// Default styling that matches the game's theme
  factory EventInteractionStyle.defaultStyle() {
    return EventInteractionStyle(
      containerDecoration: const BoxDecoration(color: Color(0xFF0A0A0A)),
      eventDisplayStyle: EventDisplayStyle.defaultStyle(),
      choiceButtonsStyle: ChoiceButtonsStyle.defaultStyle(),
      processingOverlayDecoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }

  /// Compact styling for smaller displays
  factory EventInteractionStyle.compact() {
    return EventInteractionStyle(
      eventDisplayFlex: 2,
      eventDisplayStyle: EventDisplayStyle.compact(),
      choiceButtonsStyle: ChoiceButtonsStyle.compact(),
      processingMessageStyle: const TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      processingSubtextStyle: const TextStyle(
        color: Color(0xFF999999),
        fontSize: 11,
      ),
    );
  }

  /// Copy this style with optional parameter overrides
  EventInteractionStyle copyWith({
    Decoration? containerDecoration,
    int? eventDisplayFlex,
    EventDisplayStyle? eventDisplayStyle,
    ChoiceButtonsStyle? choiceButtonsStyle,
    Decoration? processingOverlayDecoration,
    Color? processingIndicatorColor,
    TextStyle? processingMessageStyle,
    TextStyle? processingSubtextStyle,
    bool? showProcessingAnimation,
  }) {
    return EventInteractionStyle(
      containerDecoration: containerDecoration ?? this.containerDecoration,
      eventDisplayFlex: eventDisplayFlex ?? this.eventDisplayFlex,
      eventDisplayStyle: eventDisplayStyle ?? this.eventDisplayStyle,
      choiceButtonsStyle: choiceButtonsStyle ?? this.choiceButtonsStyle,
      processingOverlayDecoration:
          processingOverlayDecoration ?? this.processingOverlayDecoration,
      processingIndicatorColor:
          processingIndicatorColor ?? this.processingIndicatorColor,
      processingMessageStyle:
          processingMessageStyle ?? this.processingMessageStyle,
      processingSubtextStyle:
          processingSubtextStyle ?? this.processingSubtextStyle,
      showProcessingAnimation:
          showProcessingAnimation ?? this.showProcessingAnimation,
    );
  }
}

/// A simplified widget that displays event data from EventProcessor.displayEvent()
///
/// This is useful when you have already processed event data and just want to display it
class ProcessedEventDisplay extends StatelessWidget {
  /// The processed event data from EventProcessor.displayEvent()
  final Map<String, dynamic> eventData;

  /// Callback when a choice is selected (receives choice index)
  final void Function(int choiceIndex) onChoiceSelected;

  /// Optional function to determine if a choice is available
  final bool Function(Map<String, dynamic> choice)? isChoiceAvailable;

  /// Optional custom styling
  final ProcessedEventDisplayStyle? style;

  const ProcessedEventDisplay({
    super.key,
    required this.eventData,
    required this.onChoiceSelected,
    this.isChoiceAvailable,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? ProcessedEventDisplayStyle.defaultStyle();

    return Container(
      decoration: style.containerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Event content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: style.contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event name
                  Text(
                    eventData['name'] ?? 'Unknown Event',
                    style: style.nameTextStyle,
                  ),

                  SizedBox(height: style.spacingBetweenElements),

                  // Event description
                  Text(
                    eventData['description'] ?? 'No description available.',
                    style: style.descriptionTextStyle,
                  ),

                  // Event category (if available)
                  if (eventData['category'] != null) ...[
                    SizedBox(height: style.spacingBetweenElements),
                    _buildCategoryChip(eventData['category'], style),
                  ],
                ],
              ),
            ),
          ),

          // Choice buttons
          if (eventData['choices'] != null) _buildProcessedChoiceButtons(style),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, ProcessedEventDisplayStyle style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: style.categoryChipBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: style.categoryChipBorderColor, width: 1),
        ),
        child: Text(category.toUpperCase(), style: style.categoryChipTextStyle),
      ),
    );
  }

  Widget _buildProcessedChoiceButtons(ProcessedEventDisplayStyle style) {
    final choices = eventData['choices'] as List<dynamic>;

    return Container(
      padding: style.choicesPadding,
      decoration: style.choicesDecoration,
      child: Column(
        children: choices.asMap().entries.map((entry) {
          final index = entry.key;
          final choice = entry.value as Map<String, dynamic>;
          final isAvailable =
              isChoiceAvailable?.call(choice) ?? choice['isAvailable'] ?? true;

          return Container(
            margin: EdgeInsets.only(
              bottom: index < choices.length - 1
                  ? style.spacingBetweenChoices
                  : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: style.choiceButtonBorderRadius,
                onTap: isAvailable ? () => onChoiceSelected(index) : null,
                child: Container(
                  padding: style.choiceButtonPadding,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? style.choiceButtonBackgroundColor
                        : style.disabledChoiceButtonBackgroundColor,
                    borderRadius: style.choiceButtonBorderRadius,
                    border: Border.all(
                      color: isAvailable
                          ? style.choiceButtonBorderColor
                          : style.disabledChoiceButtonBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          choice['text'] ?? 'Unknown choice',
                          style: isAvailable
                              ? style.choiceTextStyle
                              : style.disabledChoiceTextStyle,
                        ),
                      ),
                      Icon(
                        isAvailable ? Icons.arrow_forward_ios : Icons.lock,
                        size: 16,
                        color: isAvailable
                            ? style.choiceIconColor
                            : style.disabledChoiceIconColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Style configuration for ProcessedEventDisplay widget
class ProcessedEventDisplayStyle {
  final Decoration? containerDecoration;
  final EdgeInsets contentPadding;
  final double spacingBetweenElements;
  final double spacingBetweenChoices;

  // Text styling
  final TextStyle nameTextStyle;
  final TextStyle descriptionTextStyle;

  // Category chip styling
  final Color categoryChipBackgroundColor;
  final Color categoryChipBorderColor;
  final TextStyle categoryChipTextStyle;

  // Choices section styling
  final EdgeInsets choicesPadding;
  final Decoration? choicesDecoration;
  final BorderRadius choiceButtonBorderRadius;
  final EdgeInsets choiceButtonPadding;
  final Color choiceButtonBackgroundColor;
  final Color choiceButtonBorderColor;
  final Color disabledChoiceButtonBackgroundColor;
  final Color disabledChoiceButtonBorderColor;
  final TextStyle choiceTextStyle;
  final TextStyle disabledChoiceTextStyle;
  final Color choiceIconColor;
  final Color disabledChoiceIconColor;

  const ProcessedEventDisplayStyle({
    this.containerDecoration,
    this.contentPadding = const EdgeInsets.all(20),
    this.spacingBetweenElements = 16,
    this.spacingBetweenChoices = 12,
    this.nameTextStyle = const TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    this.descriptionTextStyle = const TextStyle(
      color: Color(0xFFD4D4D4),
      fontSize: 16,
      height: 1.5,
    ),
    this.categoryChipBackgroundColor = const Color(0xFF444444),
    this.categoryChipBorderColor = const Color(0xFF666666),
    this.categoryChipTextStyle = const TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
    this.choicesPadding = const EdgeInsets.all(16),
    this.choicesDecoration,
    this.choiceButtonBorderRadius = const BorderRadius.all(Radius.circular(8)),
    this.choiceButtonPadding = const EdgeInsets.all(16),
    this.choiceButtonBackgroundColor = const Color(0xFF2A2A2A),
    this.choiceButtonBorderColor = const Color(0xFF8B0000),
    this.disabledChoiceButtonBackgroundColor = const Color(0xFF1A1A1A),
    this.disabledChoiceButtonBorderColor = const Color(0xFF444444),
    this.choiceTextStyle = const TextStyle(
      color: Color(0xFFD4D4D4),
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    this.disabledChoiceTextStyle = const TextStyle(
      color: Color(0xFF666666),
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    this.choiceIconColor = const Color(0xFF8B0000),
    this.disabledChoiceIconColor = const Color(0xFF666666),
  });

  /// Default styling that matches the game's theme
  factory ProcessedEventDisplayStyle.defaultStyle() {
    return ProcessedEventDisplayStyle(
      containerDecoration: const BoxDecoration(color: Color(0xFF0A0A0A)),
      choicesDecoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF8B0000).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}
