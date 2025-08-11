import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/game_state.dart';
import '../services/inventory_manager.dart';
import '../widgets/modern_game_ui.dart';
import '../services/locale_service.dart';

class InventoryScreen extends StatefulWidget {
  final List<InventoryItem> items;
  final Function(InventoryItem)? onItemTap;
  final Function(InventoryItem)? onItemUse;

  const InventoryScreen({
    super.key,
    required this.items,
    this.onItemTap,
    this.onItemUse,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  
  InventoryItem? selectedItem;
  final InventoryManager _inventoryManager = InventoryManager();
  final LocaleService _localeService = LocaleService.instance;

  @override
  void initState() {
    super.initState();
    // Best-effort load of item database for descriptions/effects
    _inventoryManager.loadItemDatabase();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = widget.items.where((inv) {
      final def = _inventoryManager.getItem(inv.id);
      return (def?.itemType.toUpperCase() ?? 'ACTIVE') == 'ACTIVE';
    }).toList();
    final passiveItems = widget.items.where((inv) {
      final def = _inventoryManager.getItem(inv.id);
      return (def?.itemType.toUpperCase() ?? 'ACTIVE') == 'PASSIVE';
    }).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.8,
            colors: [
              AppTheme.backgroundSecondary,
              AppTheme.backgroundPrimary,
              const Color(0xFF000000),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              ModernGameHeader(
                title: _textByLocale(en: 'Inventory', ko: '인벤토리'),
                subtitle: _textByLocale(
                  en: '${widget.items.length}/10 items',
                  ko: '${widget.items.length}/10 아이템',
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),

              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                      child: Opacity(
                        opacity: _slideAnimation.value,
                        child: widget.items.isEmpty
                            ? _buildEmptyInventory()
                            : _buildInventoryContent(activeItems, passiveItems),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: AppTheme.borderSecondary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _textByLocale(en: 'Empty Inventory', ko: '빈 인벤토리'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _textByLocale(
                en: 'Explore the maze to find items that will help you survive',
                ko: '미로를 탐험하여 생존에 도움이 되는 아이템을 찾으세요',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryContent(List<InventoryItem> activeItems, List<InventoryItem> passiveItems) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Items Section
          if (activeItems.isNotEmpty) ...[
            _buildSectionHeader(
              _textByLocale(en: 'Consumables', ko: '소모품'),
              Icons.local_pharmacy,
              AppTheme.successColor,
            ),
            const SizedBox(height: 12),
            _buildItemGrid(activeItems),
            const SizedBox(height: 24),
          ],

          // Passive Items Section
          if (passiveItems.isNotEmpty) ...[
            _buildSectionHeader(
              _textByLocale(en: 'Equipment', ko: '장비'),
              Icons.shield,
              AppTheme.accentSecondary,
            ),
            const SizedBox(height: 12),
            _buildItemGrid(passiveItems),
            const SizedBox(height: 24),
          ],

          // Item Details Panel
          if (selectedItem != null) ...[
            _buildItemDetails(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildItemGrid(List<InventoryItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(items[index]);
      },
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    final isSelected = selectedItem?.id == item.id;
    final def = _inventoryManager.getItem(item.id);
    final isActive = (def?.itemType.toUpperCase() ?? 'ACTIVE') == 'ACTIVE';
    final typeColor = isActive ? AppTheme.successColor : AppTheme.accentSecondary;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (widget.items.indexOf(item) * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedItem = selectedItem?.id == item.id ? null : item;
              });
              if (widget.onItemTap != null) widget.onItemTap!(item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          typeColor.withOpacity(0.3),
                          typeColor.withOpacity(0.1),
                        ]
                      : [
                          AppTheme.backgroundSecondary.withOpacity(0.8),
                          AppTheme.backgroundTertiary.withOpacity(0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? typeColor.withOpacity(0.6)
                      : AppTheme.borderSecondary.withOpacity(0.5),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: typeColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: typeColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isActive
                            ? _textByLocale(en: 'USE', ko: '사용')
                            : _textByLocale(en: 'EQUIP', ko: '장착'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Item Name
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Quantity (for active items)
                    if (isActive) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'x${item.quantity}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemDetails() {
    if (selectedItem == null) return const SizedBox.shrink();

    final item = selectedItem!;
    final def = _inventoryManager.getItem(item.id);
    final isActive = (def?.itemType.toUpperCase() ?? 'ACTIVE') == 'ACTIVE';
    final typeColor = isActive ? AppTheme.successColor : AppTheme.accentSecondary;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    typeColor.withOpacity(0.1),
                    AppTheme.backgroundSecondary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: typeColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isActive && item.quantity > 0)
                        ModernActionButton(
                          label: _textByLocale(en: 'Use', ko: '사용'),
                          icon: Icons.play_arrow,
                          color: typeColor,
                          onPressed: () => widget.onItemUse?.call(item),
                        ),
                      const SizedBox(width: 8),
                      ModernActionButton(
                        label: _textByLocale(en: 'Discard', ko: '버리기'),
                        icon: Icons.delete_outline,
                        color: AppTheme.dangerColor,
                        onPressed: () {
                          // Let parent handle discard via onItemTap for now, or just close
                          widget.onItemTap?.call(item);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    def?.description ?? item.description ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Effects
                  if (def != null && def.effects.hasEffects) ...[
                    Text(
                      _textByLocale(en: 'Effects', ko: '효과'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEffectsChips(def.effects),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEffectsChips(ItemEffects effects) {
    final chips = <Widget>[];
    if (effects.statChanges != null) {
      effects.statChanges!.forEach((stat, change) {
        final isPositive = change > 0;
        chips.add(_effectChip(
          text: '${stat.toUpperCase()} ${isPositive ? '+' : ''}$change',
          color: isPositive ? AppTheme.successColor : AppTheme.dangerColor,
          icon: isPositive ? Icons.trending_up : Icons.trending_down,
        ));
      });
    }
    if (effects.applyStatus != null && effects.applyStatus!.isNotEmpty) {
      for (final s in effects.applyStatus!) {
        chips.add(_effectChip(text: s.toUpperCase(), color: AppTheme.accentSecondary, icon: Icons.auto_awesome));
      }
    }
    if (effects.removeStatus != null && effects.removeStatus!.isNotEmpty) {
      for (final s in effects.removeStatus!) {
        chips.add(_effectChip(text: 'REMOVE ${s.toUpperCase()}', color: AppTheme.textSecondary, icon: Icons.cleaning_services));
      }
    }
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _effectChip({required String text, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _textByLocale({required String en, required String ko}) {
    final locale = _localeService.localeNotifier.value;
    final code = locale?.languageCode;
    if (code == 'ko') return ko;
    if (code == 'en') return en;
    // Fallback to device locale if set to system
    final platformCode = Localizations.localeOf(context).languageCode;
    return platformCode == 'ko' ? ko : en;
  }
}