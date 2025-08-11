# Image Specifications for Korean Maze Game

## 📐 Image Dimensions & Format

### Event Images
- **Size**: 512×320 pixels (1.6:1 ratio)
- **High-DPI**: 1024×640 pixels (for @2x devices)  
- **Format**: PNG with transparency support
- **File Size**: < 200KB per image
- **Color Space**: sRGB

### UI Icons
- **Size**: 64×64 pixels (base size)
- **High-DPI**: 128×128 pixels (@2x)
- **Format**: PNG with transparency
- **File Size**: < 50KB per icon

## 📁 Folder Structure

```
assets/images/
├── events/
│   ├── characters/     # Character encounter images
│   ├── monsters/       # Monster encounter images  
│   ├── traps/         # Trap event images
│   └── items/         # Item discovery images
├── rooms/
│   └── general/       # Room/environment images
└── ui/
    └── icons/         # Game UI icons
```

## 🎨 Design Guidelines

### Event Images (512×320)
- **Style**: Dark, atmospheric, Korean horror aesthetic
- **Mood**: Mysterious, tense, immersive
- **Content**: Should clearly represent the event type
- **Text**: No text in images (text handled by UI)

### Example Image Names
```
events/characters/
├── mysterious_figure.png
├── lost_student.png
├── maintenance_worker.png
└── security_guard.png

events/monsters/
├── shadow_creature.png
├── spectral_entity.png
└── unknown_presence.png

events/traps/
├── pitfall_trap.png
├── poison_dart_trap.png
└── electrical_hazard.png

events/items/
├── first_aid_kit.png
├── flashlight.png
├── rope.png
└── energy_drink.png

rooms/general/
├── empty_room.png
├── corridor.png
├── stairwell.png
└── exit_door.png

ui/icons/
├── hp_icon.png
├── san_icon.png
├── fitness_icon.png
└── hunger_icon.png
```

## 📱 Mobile Optimization

### Performance Requirements
- **Loading Time**: < 1 second per image
- **Memory Usage**: < 2MB total for active images
- **Compression**: Use PNG optimization tools
- **Caching**: Images cached after first load

### Responsive Considerations  
- **Portrait Mode**: Primary target orientation
- **Screen Sizes**: 
  - Small: 320×568 (iPhone SE)
  - Medium: 375×667 (iPhone 8)
  - Large: 414×896 (iPhone 11)

## 🔧 Technical Notes

### Flutter Implementation
- Images loaded via `Image.asset()`
- Error handling for missing images
- Automatic @2x resolution support
- AssetBundle preloading for performance

### File Naming Convention
- Use snake_case (e.g., `shadow_creature.png`)
- Descriptive names matching event IDs
- No spaces or special characters
- Include @2x suffix for high-resolution variants

### Color Profile
- **sRGB** color space for consistent display
- **Dark theme** compatible colors
- **High contrast** for mobile visibility
- **Korean aesthetic** elements where appropriate