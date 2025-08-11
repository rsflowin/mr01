import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernStatBar extends StatefulWidget {
  final String statName;
  final int currentValue;
  final int maxValue;
  final Color? color;
  final bool showLabel;
  final bool animated;

  const ModernStatBar({
    super.key,
    required this.statName,
    required this.currentValue,
    required this.maxValue,
    this.color,
    this.showLabel = true,
    this.animated = true,
  });

  @override
  State<ModernStatBar> createState() => _ModernStatBarState();
}

class _ModernStatBarState extends State<ModernStatBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    
    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.getStatColor(widget.statName);
    final percentage = widget.currentValue / widget.maxValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.statName.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${widget.currentValue}/${widget.maxValue}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.backgroundTertiary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppTheme.borderSecondary,
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final animatedPercentage = widget.animated 
                  ? _animation.value * percentage 
                  : percentage;
                
                return LinearProgressIndicator(
                  value: animatedPercentage,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatColorWithHealth(color, percentage),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatColorWithHealth(Color baseColor, double percentage) {
    if (percentage > 0.6) {
      return baseColor;
    } else if (percentage > 0.3) {
      return Color.lerp(AppTheme.warningColor, baseColor, percentage)!;
    } else {
      return AppTheme.dangerColor;
    }
  }
}

class ModernStatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  final Map<String, int> maxStats;
  final bool animated;

  const ModernStatsGrid({
    super.key,
    required this.stats,
    required this.maxStats,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassMorphism,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.entries.map((entry) {
            final delay = stats.keys.toList().indexOf(entry.key) * 200;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 600 + delay),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: ModernStatBar(
                        statName: entry.key,
                        currentValue: entry.value,
                        maxValue: maxStats[entry.key] ?? 100,
                        animated: animated,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}