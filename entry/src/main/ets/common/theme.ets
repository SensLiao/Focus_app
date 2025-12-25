
/**
 * 主题配置 - 基于 Figma Design
 */

interface ShadowOptions {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

interface GradientColor {
  color: string;
  offset: number;
}

export class Theme {
  // 主色调 - 现代蓝色系 (基于 Sample_Frontend)
  static readonly COLOR_PRIMARY = '#2563EB'  // Blue-600 主色
  static readonly COLOR_PRIMARY_LIGHT = '#3B82F6'  // Blue-500
  static readonly COLOR_PRIMARY_DARK = '#1D4ED8'  // Blue-700
  static readonly COLOR_PRIMARY_BG = '#EFF6FF'  // Blue-50 背景
  
  // 功能色
  static readonly COLOR_SUCCESS = '#10B981'  // Emerald-500 成功绿
  static readonly COLOR_SUCCESS_LIGHT = '#34D399'  // Emerald-400
  static readonly COLOR_SUCCESS_BG = '#ECFDF5'  // Emerald-50 背景
  static readonly COLOR_MINT = '#059669'  // Emerald-600（播放按钮）
  static readonly COLOR_MINT_BG = '#D1FAE5'  // Emerald-100 背景
  static readonly COLOR_WARNING = '#F97316'  // Orange-500（休息模式）
  static readonly COLOR_WARNING_BG = '#FFF7ED'  // Orange-50 背景
  static readonly COLOR_ERROR = '#EF4444'  // Red-500 错误红
  static readonly COLOR_ERROR_BG = '#FEF2F2'  // Red-50 背景
  static readonly COLOR_PURPLE = '#8B5CF6'  // Purple-500
  static readonly COLOR_PURPLE_BG = '#F3E8FF'  // Purple-100 背景
  
  // 文本颜色
  static readonly COLOR_TEXT_PRIMARY = '#111827'  // Gray-900 深黑
  static readonly COLOR_TEXT_SECONDARY = '#6B7280'  // Gray-500 中灰
  static readonly COLOR_TEXT_TERTIARY = '#9CA3AF'  // Gray-400 浅灰/禁用
  static readonly COLOR_TEXT_LIGHT = '#D1D5DB'  // Gray-300
  
  // 背景颜色
  static readonly COLOR_BACKGROUND = '#F9FAFB'  // Gray-50 浅灰背景
  static readonly COLOR_CARD_BACKGROUND = '#FFFFFF'  // 纯白
  static readonly COLOR_BORDER = '#E5E7EB'  // Gray-200 边框色
  static readonly COLOR_DIVIDER = '#F3F4F6'  // Gray-100 分割线

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
  // 阴影和深度
  static readonly SHADOW_SMALL: ShadowOptions = {
    radius: 4,
    color: '#00000010',
    offsetX: 0,
    offsetY: 2
  }
  static readonly SHADOW_MEDIUM: ShadowOptions = {
    radius: 8,
    color: '#00000015',
    offsetX: 0,
    offsetY: 4
  }
  static readonly SHADOW_LARGE: ShadowOptions = {
    radius: 16,
    color: '#00000020',
    offsetX: 0,
    offsetY: 8
  }

  // 透明度
  static readonly OPACITY_DISABLED = 0.4
  static readonly OPACITY_HOVER = 0.8
  static readonly OPACITY_PRESSED = 0.6
  // 渐变色
  static readonly GRADIENT_PRIMARY: GradientColor[] = [
    { color: '#597EF7', offset: 0 },
    { color: '#2F54EB', offset: 1 }
  ]
  static readonly GRADIENT_PURPLE: GradientColor[] = [
    { color: '#B37FEB', offset: 0 },
    { color: '#531DAB', offset: 1 }
  ]
  static readonly GRADIENT_ORANGE: GradientColor[] = [
    { color: '#FFD591', offset: 0 },
    { color: '#FA8C16', offset: 1 }
  ]
}
