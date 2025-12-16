/**
 * 主题配置 - 基于 Figma Design
 */

export class Theme {
  // 主色调 - 蓝色系（参考 Figma）
  static readonly COLOR_PRIMARY = '#2563EB'  // 蓝色主色
  static readonly COLOR_PRIMARY_LIGHT = '#3B82F6'
  static readonly COLOR_PRIMARY_DARK = '#1D4ED8'
  
  // 功能色
  static readonly COLOR_SUCCESS = '#10B981'
  static readonly COLOR_WARNING = '#F59E0B'
  static readonly COLOR_ERROR = '#EF4444'
  
  // 文本颜色
  static readonly COLOR_TEXT_PRIMARY = '#111827'
  static readonly COLOR_TEXT_SECONDARY = '#6B7280'
  static readonly COLOR_TEXT_TERTIARY = '#9CA3AF'
  
  // 背景颜色
  static readonly COLOR_BACKGROUND = '#F9FAFB'
  static readonly COLOR_CARD_BACKGROUND = '#FFFFFF'
  static readonly COLOR_BORDER = '#E5E7EB'

  // 字体
  static readonly FONT_SIZE_TITLE = 28
  static readonly FONT_SIZE_LARGE = 20
  static readonly FONT_SIZE_MEDIUM = 16
  static readonly FONT_SIZE_SMALL = 14
  static readonly FONT_SIZE_TINY = 12

  // 间距
  static readonly SPACE_TINY = 4
  static readonly SPACE_SMALL = 8
  static readonly SPACE_MEDIUM = 16
  static readonly SPACE_LARGE = 24
  static readonly SPACE_XLARGE = 32

  // 圆角
  static readonly BORDER_RADIUS_SMALL = 8
  static readonly BORDER_RADIUS_MEDIUM = 12
  static readonly BORDER_RADIUS_LARGE = 16
  static readonly BORDER_RADIUS_FULL = 999
}
