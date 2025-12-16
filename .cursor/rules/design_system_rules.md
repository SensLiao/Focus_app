# HarmonyOS Focus App - Design System Rules

## Framework & Architecture

### Technology Stack
- **Framework**: HarmonyOS ArkTS (API Level 10+)
- **UI System**: ArkUI (Declarative)
- **Styling**: Inline TypeScript-based styling
- **State Management**: Custom Store pattern with @Observed/@State reactivity
- **Build System**: Hvigor

### File Structure
```
entry/src/main/
├── ets/
│   ├── common/
│   │   ├── theme.ets          # Design tokens
│   │   ├── constants.ets      # App constants
│   │   └── logger.ets         # Logging utility
│   ├── components/            # Reusable UI components
│   ├── pages/                 # Page-level components
│   ├── store/                 # State management
│   └── services/              # Business logic services
└── resources/
    └── base/element/
        ├── color.json         # Color resources
        ├── float.json         # Dimension resources
        └── string.json        # String resources
```

## Design Tokens

### Color System (theme.ets)
```typescript
export class Theme {
  // Primary Colors - Blue Palette
  static readonly COLOR_PRIMARY = '#2563EB'
  static readonly COLOR_PRIMARY_LIGHT = '#3B82F6'
  static readonly COLOR_PRIMARY_DARK = '#1D4ED8'
  
  // Semantic Colors
  static readonly COLOR_SUCCESS = '#10B981'
  static readonly COLOR_WARNING = '#F59E0B'
  static readonly COLOR_ERROR = '#EF4444'
  
  // Text Colors
  static readonly COLOR_TEXT_PRIMARY = '#111827'
  static readonly COLOR_TEXT_SECONDARY = '#6B7280'
  static readonly COLOR_TEXT_TERTIARY = '#9CA3AF'
  
  // Background Colors
  static readonly COLOR_BACKGROUND = '#F9FAFB'
  static readonly COLOR_CARD_BACKGROUND = '#FFFFFF'
  static readonly COLOR_BORDER = '#E5E7EB'
}
```

### Typography
```typescript
// Font Sizes
static readonly FONT_SIZE_TITLE = 28      // Page titles
static readonly FONT_SIZE_LARGE = 20      // Section headers
static readonly FONT_SIZE_MEDIUM = 16     // Body text
static readonly FONT_SIZE_SMALL = 14      // Secondary text
static readonly FONT_SIZE_TINY = 12       // Captions
```

### Spacing System
```typescript
// Spacing Scale (multiples of 4)
static readonly SPACE_TINY = 4      // Tight spacing
static readonly SPACE_SMALL = 8     // Compact spacing
static readonly SPACE_MEDIUM = 16   // Standard spacing
static readonly SPACE_LARGE = 24    // Loose spacing
static readonly SPACE_XLARGE = 32   // Extra loose spacing
```

### Border Radius
```typescript
static readonly BORDER_RADIUS_SMALL = 8
static readonly BORDER_RADIUS_MEDIUM = 12
static readonly BORDER_RADIUS_LARGE = 16
static readonly BORDER_RADIUS_FULL = 999   // Pill shape
```

## Component Patterns

### Component Structure
```typescript
@Component
export struct MyComponent {
  @State private localState: string = ''
  @Prop propFromParent: number
  onEvent?: (data: any) => void
  
  build() {
    Column() {
      // Component content
    }
    .width('100%')
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
  }
}
```

### Styling Approach
- **Inline Styling**: All styles defined using method chaining
- **Theme Constants**: Use `Theme.*` for all colors, spacing, typography
- **No CSS**: ArkUI uses TypeScript-based declarative styling
- **Responsive**: Use percentages, vp units, and flex layouts

### Example Component with Theme
```typescript
@Component
export struct StatCard {
  @Prop label: string
  @Prop value: string
  
  build() {
    Column() {
      Text(this.value)
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      
      Text(this.label)
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .margin({ top: Theme.SPACE_TINY })
    }
    .width('100%')
    .padding(Theme.SPACE_MEDIUM)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
    .border({
      width: 1,
      color: Theme.COLOR_BORDER
    })
  }
}
```

## State Management Pattern

### Store Pattern
```typescript
import { store } from '@kit.ArkUI'

@ObservedV2
export class FocusStore {
  @Trace currentSession: FocusSession | null = null
  @Trace isRunning: boolean = false
  
  startFocus(taskId: number, timeLimit: number) {
    // Store action implementation
  }
}

export const focusStore = new FocusStore()
store.subscribe(focusStore)
```

### Component State Binding
```typescript
@Component
export struct FocusPage {
  @StorageLink('focusStore') focusStore: FocusStore
  
  build() {
    Text(this.focusStore.isRunning ? '进行中' : '未开始')
  }
}
```

## Layout Patterns

### Page Layout
```typescript
@Entry
@Component
struct MyPage {
  build() {
    Column() {
      // Header
      Row() { /* ... */ }
        .width('100%')
        .height(56)
      
      // Content
      Column() { /* ... */ }
        .layoutWeight(1)  // Flex grow
        .padding(Theme.SPACE_MEDIUM)
      
      // Footer/Bottom Nav
      Row() { /* ... */ }
        .width('100%')
        .height(60)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }
}
```

### List Patterns
```typescript
List() {
  ForEach(this.tasks, (task: Task) => {
    ListItem() {
      TaskItem({ task: task })
    }
  })
}
.width('100%')
.layoutWeight(1)
.divider({
  strokeWidth: 1,
  color: Theme.COLOR_BORDER
})
```

## Asset Management

### Images
- **Location**: `entry/src/main/resources/base/media/`
- **Usage**: `$r('app.media.icon_name')`
- **Format**: PNG, SVG support limited

### Icons
- **System Icons**: Use built-in `SymbolGlyphModifier`
- **Custom Icons**: Store in media folder
- **Naming**: `icon_feature_variant.png`

## Responsive Design

### Viewport Units
- **vp**: Virtual pixels (density-independent)
- **fp**: Font pixels (accessibility scaling)
- **%**: Relative to parent

### Breakpoints (if needed)
```typescript
const isTablet = display.getDefaultDisplaySync().width > 600
```

## Code Generation Guidelines

### When Converting Figma to ArkTS:

1. **Colors**: Map Figma colors to `Theme.COLOR_*` constants
2. **Typography**: Use `Theme.FONT_SIZE_*` for font sizes
3. **Spacing**: Use `Theme.SPACE_*` for margins/padding
4. **Borders**: Use `Theme.BORDER_RADIUS_*` for border radius
5. **Layout**: 
   - Use `Column()` for vertical stacks
   - Use `Row()` for horizontal stacks
   - Use `.layoutWeight()` for flex grow
6. **State**: Use `@State` for local state, `@Prop` for props
7. **Lists**: Use `List()` + `ForEach()` for repeated items
8. **Navigation**: Use `router.pushUrl()` for page transitions

### Example Conversion Pattern:
```
Figma Frame (Auto Layout Vertical)
  → Column() { ... }

Figma Text (color: #111827, size: 16, weight: 600)
  → Text('...')
      .fontSize(Theme.FONT_SIZE_MEDIUM)
      .fontColor(Theme.COLOR_TEXT_PRIMARY)
      .fontWeight(FontWeight.Bold)

Figma Rectangle (fill: #FFFFFF, radius: 12, padding: 16)
  → Column() { ... }
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
      .padding(Theme.SPACE_MEDIUM)
```

## Best Practices

1. **Always use Theme constants** - Never hardcode colors/spacing
2. **Component isolation** - Each component in its own file
3. **Props over state** - Pass data down, emit events up
4. **Type safety** - Use TypeScript types for all data models
5. **Performance** - Use `@Reusable` for list items
6. **Accessibility** - Add `.accessibilityText()` for screen readers
7. **Error handling** - Use `Result<T>` pattern for operations
8. **Async operations** - Properly handle promises with try/catch

## Testing Considerations

- Unit tests: `entry/src/test/`
- Component tests: Mock Store instances
- Integration tests: `entry/src/ohosTest/`
- Use `@ohos/hypium` framework

## Common Pitfalls to Avoid

1. ❌ Don't use CSS or HTML - ArkUI is TypeScript-based
2. ❌ Don't mutate Store state directly - use Store actions
3. ❌ Don't forget `.width('100%')` for full-width components
4. ❌ Don't use pixel values - use vp/fp units
5. ❌ Don't nest too many Columns/Rows - impacts performance
6. ✅ Do use Theme constants for consistency
7. ✅ Do follow the 4-layer architecture (UI → Store → Service → Data)
8. ✅ Do test on real HarmonyOS devices for accurate preview
