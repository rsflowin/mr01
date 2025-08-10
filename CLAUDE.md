# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Korean text-based maze escape game built with Flutter. Players navigate through 8x8 maze grids while managing four core stats (HP, SAN, FITNESS, HUNGER) through event-based choices. The game features Reigns-style decision making with stat consequences, status effects, inventory management, and multiple endings based on performance.

**Game Flow**: Start → Navigate maze → Room events → Make choices → Stat changes → Victory/defeat conditions → Multiple endings

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app with hot reload
- `flutter build apk` - Build Android APK
- `flutter build ipa` - Build iOS IPA (macOS required)
- `flutter build web` - Build for web
- `flutter test` - Run widget tests
- `flutter analyze` - Run static code analysis using analysis_options.yaml
- `flutter pub get` - Install/update dependencies
- `flutter clean` - Clean build cache

### Platform-Specific
- `flutter run -d chrome` - Run in Chrome browser
- `flutter run -d android` - Run on Android device/emulator
- `flutter run -d ios` - Run on iOS simulator/device

## Code Architecture

### Current State
The project is in early development with:
- **Main App**: `lib/main.dart` contains default Flutter counter template (needs complete rewrite)
- **Game Data**: Comprehensive JSON data files in `data/` directory with final format
- **Images**: Not yet available (referenced in JSON but files don't exist)

### Planned Architecture (from design document)
```
/lib
  /models
    - maze_model.dart     # 8x8 maze with door system
    - event_model.dart    # Event choices and stat effects
    - player_model.dart   # HP/SAN/FITNESS/HUNGER stats
  /screens
    - game_screen.dart    # Main gameplay interface
    - result_screen.dart  # Multiple ending screens
  /services
    - data_loader.dart    # JSON file loading
    - event_processor.dart # Event logic and stat changes
  /widgets
    - maze_view.dart      # 8x8 grid visualization
    - stat_bar.dart       # HP/SAN/FITNESS/HUNGER display
    - choice_buttons.dart # Reigns-style choice interface
```

## Data Structure and Management

### Data Files Location: `data/`
All game content is stored as JSON files in final format:

#### Maze Data
- **Files**: `maze_1.json` through `maze_8.json` (8 pre-built mazes)
- **Structure**: 8x8 grid with room coordinates, door connections (north/east/south/west), start/exit markers
- **Format**: Each room has x,y coordinates and door booleans determining movement possibilities

#### Event Data (Split into Multiple Files)
- **Monster Events**: `event_monsters.json` 
- **Trap Events**: `event_traps.json`
- **Item Events**: `event_items.json`
- **Environmental Events**: `event_environmental.json`
- **Character Events**: `event_character_1.json` through `event_character_18.json` (18 files)

#### Other Data
- **Items**: `items.json` - Two types (ACTIVE: consumable, PASSIVE: equipment)
- **Status Effects**: `status_effects.json` - BUFF/DEBUFF with durations

### Event Structure
Each event contains:
- **Metadata**: id, category, subcategory, threatLevel, persistence, weight
- **Content**: name, description, image reference (Korean text)
- **Choices**: Up to 3 options with requirements, stat effects, success/failure conditions
- **Effects**: Direct stat changes (HP, SAN, FITNESS, HUNGER) and status effect applications

### Player Stats System
- **HP (체력)**: 0-100, death at 0 (bad ending 1)
- **SAN (정신력)**: 0-100, mental breakdown at 0 (bad ending 2) 
- **FITNESS (운동능력)**: 0-100, affects combat and physical challenges
- **HUNGER (허기)**: 0-100, affects all other stats when critically low

## Korean Language Content
- All game text, descriptions, and choices are in Korean
- Event names and descriptions use Korean terminology
- UI elements will need Korean text support
- Status effects and items have Korean names

## Data Loading Strategy
- **Multiple JSON Files**: Event data is split across many files for size management
- **Runtime Merging**: Application must load and combine all event_*.json files
- **Image References**: JSON contains image filenames but actual image files not yet available
- **Validation**: Implement JSON schema validation for data integrity

## Game Features to Implement
1. **8x8 Maze Navigation**: Door-based movement system
2. **Event Processing**: Weighted random event selection with success/failure mechanics
3. **Stat Management**: Real-time stat tracking with bounds checking
4. **Status Effects**: Temporary modifiers with duration tracking
5. **Inventory System**: 5-slot item management (ACTIVE/PASSIVE types)
6. **Save/Load System**: Auto-save on room entry and event completion
7. **Multiple Endings**: Stat-based ending conditions
8. **Korean UI**: Full Korean language support

## Implementation Notes
- **Data Size**: Event data spread across 20+ JSON files requires efficient loading
- **Missing Assets**: Image files referenced in JSON don't exist yet
- **Reigns-Style UI**: Card-based choice interface with stat feedback
- **Mobile-First**: Touch-friendly navigation and choice selection
- **Fast Gameplay**: 5-10 minute play sessions with high replayability