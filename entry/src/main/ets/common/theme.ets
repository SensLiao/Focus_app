
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
  // 主色调 - 皇家蓝（Royal Blue）- 基于 UI_DESIGN_SPECIFICATION.md
  static readonly COLOR_PRIMARY = '#2F54EB'  // 皇家蓝主色
  static readonly COLOR_PRIMARY_LIGHT = '#597EF7'
  static readonly COLOR_PRIMARY_DARK = '#1D39C4'
  
  // 功能色
  static readonly COLOR_SUCCESS = '#52C41A'  // 成功绿
  static readonly COLOR_SUCCESS_LIGHT = '#95DE64'
  static readonly COLOR_MINT = '#389E0D'  // 薄荷绿（播放按钮）
  static readonly COLOR_MINT_BG = '#E6FFEB'  // 薄荷绿背景
  static readonly COLOR_WARNING = '#FA8C16'  // 橙色（休息模式）
  static readonly COLOR_ERROR = '#F5222D'  // 错误红
  
  // 文本颜色
  static readonly COLOR_TEXT_PRIMARY = '#1F1F1F'  // 深黑
  static readonly COLOR_TEXT_SECONDARY = '#8C8C8C'  // 中灰
  static readonly COLOR_TEXT_TERTIARY = '#BFBFBF'  // 浅灰/禁用
  
  // 背景颜色
  static readonly COLOR_BACKGROUND = '#F5F7FA'  // 浅灰背景
  static readonly COLOR_CARD_BACKGROUND = '#FFFFFF'  // 纯白
  static readonly COLOR_BORDER = '#E8E8E8'  // 边框色

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
