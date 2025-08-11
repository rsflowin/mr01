import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/locale_service.dart';
import '../widgets/modern_game_ui.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocaleService _localeService = LocaleService.instance;
  
  // Settings state
  bool _soundEnabled = true;
  bool _musicEnabled = AudioService.instance.bgmEnabled.value;
  bool _vibrationEnabled = true;
  bool _animationsEnabled = true;
  double _masterVolume = 0.8;
  double _sfxVolume = 0.7;
  double _musicVolume = 0.6;

  @override
  Widget build(BuildContext context) {
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
                title: _textByLocale(en: 'Settings', ko: '설정'),
                subtitle: _textByLocale(
                  en: 'Customize your experience',
                  ko: '게임 환경을 설정하세요',
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              
              // Settings content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language Settings
                      _buildSectionHeader(
                        context,
                        _textByLocale(en: 'Language', ko: '언어'),
                        Icons.language,
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageSelector(),
                      const SizedBox(height: 32),
                      
                      // Audio Settings (BGM only)
                      _buildSectionHeader(
                        context,
                        _textByLocale(en: 'Audio', ko: '오디오'),
                        Icons.volume_up,
                      ),
                      const SizedBox(height: 12),
                      _buildBgmToggle(),
                      const SizedBox(height: 32),
                      
                      // Gameplay Settings
                      _buildSectionHeader(
                        context,
                        _textByLocale(en: 'Gameplay', ko: '게임플레이'),
                        Icons.gamepad,
                      ),
                      const SizedBox(height: 12),
                      _buildGameplaySettings(),
                      const SizedBox(height: 32),
                      
                      // Accessibility Settings
                      _buildSectionHeader(
                        context,
                        _textByLocale(en: 'Accessibility', ko: '접근성'),
                        Icons.accessibility,
                      ),
                      const SizedBox(height: 12),
                      _buildAccessibilitySettings(),
                      const SizedBox(height: 32),
                      
                      // About Section
                      _buildSectionHeader(
                        context,
                        _textByLocale(en: 'About', ko: '정보'),
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildAboutSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.mysteriousGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
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

  Widget _buildLanguageSelector() {
    return Container(
      decoration: AppTheme.glassMorphism,
      child: Column(
        children: [
          _buildLanguageOption(
            'English',
            'EN',
            (_localeService.localeNotifier.value?.languageCode ??
                    Localizations.localeOf(context).languageCode) !=
                'ko',
            () => _localeService.setLocale(const Locale('en')),
          ),
          const Divider(color: AppTheme.borderSecondary, height: 1),
          _buildLanguageOption(
            '한국어',
            'KO',
            (_localeService.localeNotifier.value?.languageCode ??
                    Localizations.localeOf(context).languageCode) ==
                'ko',
            () => _localeService.setLocale(const Locale('ko')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String language,
    String code,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.accentPrimary : AppTheme.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      code,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBgmToggle() {
    return Container(
      decoration: AppTheme.glassMorphism,
      padding: const EdgeInsets.all(16),
      child: _buildSwitchSetting(
        _textByLocale(en: 'Background Music (BGM)', ko: '배경 음악 (BGM)'),
        _textByLocale(en: 'Turn background music on or off', ko: '배경 음악을 켜거나 끄세요'),
        _musicEnabled,
        (value) {
          setState(() => _musicEnabled = value);
          AudioService.instance.setBgmEnabled(value);
        },
      ),
    );
  }

  Widget _buildGameplaySettings() {
    return Container(
      decoration: AppTheme.glassMorphism,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSwitchSetting(
            _textByLocale(en: 'Haptic Feedback', ko: '햅틱 피드백'),
            _textByLocale(en: 'Feel vibrations during gameplay', ko: '게임 중 진동 사용'),
            _vibrationEnabled,
            (value) => setState(() => _vibrationEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildSwitchSetting(
            _textByLocale(en: 'Animations', ko: '애니메이션'),
            _textByLocale(en: 'Enable smooth transitions', ko: '부드러운 전환 효과 사용'),
            _animationsEnabled,
            (value) => setState(() => _animationsEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySettings() {
    return Container(
      decoration: AppTheme.glassMorphism,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ModernInfoCard(
            title: _textByLocale(en: 'High Contrast Mode', ko: '고대비 모드'),
            content: _textByLocale(
              en: 'Coming Soon - Enhanced visibility for better accessibility',
              ko: '곧 제공 - 접근성 향상을 위한 고대비 모드',
            ),
            icon: Icons.contrast,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 8),
          ModernInfoCard(
            title: _textByLocale(en: 'Large Text', ko: '큰 글씨'),
            content: _textByLocale(
              en: 'Coming Soon - Increased text size for better readability',
              ko: '곧 제공 - 가독성 향상을 위한 큰 글씨',
            ),
            icon: Icons.text_increase,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: AppTheme.glassMorphism,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ModernInfoCard(
            title: _textByLocale(en: 'Game Version', ko: '게임 버전'),
            content: 'v1.0.0 Beta',
            icon: Icons.info,
          ),
          const SizedBox(height: 8),
          ModernInfoCard(
            title: _textByLocale(en: 'Developer', ko: '개발자'),
            content: 'Maze Reigns Team',
            icon: Icons.code,
          ),
          const SizedBox(height: 8),
          ModernInfoCard(
            title: _textByLocale(en: 'Feedback', ko: '피드백'),
            content: _textByLocale(
              en: 'Send us your thoughts and suggestions',
              ko: '의견과 제안을 보내주세요',
            ),
            icon: Icons.feedback,
            onTap: () {
              // TODO: Implement feedback functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentPrimary,
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    Function(double) onChanged, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled ? AppTheme.textSecondary : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: enabled ? AppTheme.accentPrimary : AppTheme.textTertiary,
            inactiveTrackColor: AppTheme.backgroundTertiary,
            thumbColor: enabled ? AppTheme.accentPrimary : AppTheme.textTertiary,
          ),
          child: Slider(
            value: value,
            onChanged: enabled ? onChanged : null,
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
        ),
      ],
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