import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernGameHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ModernGameHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderSecondary.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ModernActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isDestructive;
  final bool isLoading;
  final bool isExpanded;

  const ModernActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.isDestructive = false,
    this.isLoading = false,
    this.isExpanded = false,
  });

  @override
  State<ModernActionButton> createState() => _ModernActionButtonState();
}

class _ModernActionButtonState extends State<ModernActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive 
      ? AppTheme.dangerColor 
      : widget.color ?? AppTheme.accentPrimary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 - (_controller.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.isExpanded ? double.infinity : null,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.onPressed == null
                  ? [
                      AppTheme.backgroundTertiary.withOpacity(0.5),
                      AppTheme.backgroundTertiary.withOpacity(0.3),
                    ]
                  : [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.onPressed == null 
                  ? AppTheme.borderSecondary.withOpacity(0.5)
                  : color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: widget.onPressed == null ? null : [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.isLoading ? null : widget.onPressed,
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                  _controller.forward();
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 18,
                              color: widget.onPressed == null 
                                ? AppTheme.textTertiary 
                                : color,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: widget.onPressed == null 
                                ? AppTheme.textTertiary 
                                : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ModernInfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const ModernInfoCard({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: AppTheme.glassMorphism,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: color ?? AppTheme.accentPrimary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onTap != null) ...[
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<ModernNavItem> items;

  const ModernNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderSecondary.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? AppTheme.accentPrimary.withOpacity(0.2)
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: isSelected 
                          ? AppTheme.accentPrimary 
                          : AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected 
                          ? AppTheme.textPrimary 
                          : AppTheme.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ModernNavItem {
  final IconData icon;
  final String label;

  const ModernNavItem({
    required this.icon,
    required this.label,
  });
}

class ModernLoadingIndicator extends StatefulWidget {
  final String? message;
  final Color? color;

  const ModernLoadingIndicator({
    super.key,
    this.message,
    this.color,
  });

  @override
  State<ModernLoadingIndicator> createState() => _ModernLoadingIndicatorState();
}

class _ModernLoadingIndicatorState extends State<ModernLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_animation.value * 0.4),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.mysteriousGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.color ?? AppTheme.accentPrimary).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}