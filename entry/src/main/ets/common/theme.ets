
/**
 * 主题配置 - 精致现代风格 (Inspired by Flocus)
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
  // 主色调 - 现代紫蓝色系 (类似Flocus风格)
  static readonly COLOR_PRIMARY = '#7C3AED'  // Violet-600 主色
  static readonly COLOR_PRIMARY_LIGHT = '#8B5CF6'  // Violet-500
  static readonly COLOR_PRIMARY_DARK = '#6D28D9'  // Violet-700
  static readonly COLOR_PRIMARY_BG = '#F5F3FF'  // Violet-50 背景
  static readonly COLOR_PRIMARY_GRADIENT_START = '#A78BFA'  // Violet-400
  static readonly COLOR_PRIMARY_GRADIENT_END = '#7C3AED'  // Violet-600
  
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
  
  // 柔和渐变背景色 (类似Flocus的云彩背景效果)
  static readonly COLOR_SOFT_PINK = '#FDF2F8'  // Pink-50
  static readonly COLOR_SOFT_PURPLE = '#FAF5FF'  // Purple-50
  static readonly COLOR_SOFT_BLUE = '#EFF6FF'  // Blue-50
  
  // 文本颜色
  static readonly COLOR_TEXT_PRIMARY = '#1F2937'  // Gray-800 深黑
  static readonly COLOR_TEXT_SECONDARY = '#6B7280'  // Gray-500 中灰
  static readonly COLOR_TEXT_TERTIARY = '#9CA3AF'  // Gray-400 浅灰/禁用
  static readonly COLOR_TEXT_LIGHT = '#D1D5DB'  // Gray-300
  static readonly COLOR_TEXT_ON_PRIMARY = '#FFFFFF'  // 主色上的文字
  
  // 背景颜色
  static readonly COLOR_BACKGROUND = '#FAFAFA'  // 更柔和的灰背景
  static readonly COLOR_CARD_BACKGROUND = '#FFFFFF'  // 纯白
  static readonly COLOR_BORDER = '#E5E7EB'  // Gray-200 边框色
  static readonly COLOR_DIVIDER = '#F3F4F6'  // Gray-100 分割线
  static readonly COLOR_OVERLAY = '#00000060'  // 遮罩层

  // 字体大小 - 增大整体字体
  static readonly FONT_SIZE_HERO = 72  // 超大计时器数字
  static readonly FONT_SIZE_DISPLAY = 56  // 大号显示
  static readonly FONT_SIZE_TITLE = 32  // 标题 (原28)
  static readonly FONT_SIZE_LARGE = 24  // 大号 (原20)
  static readonly FONT_SIZE_MEDIUM = 18  // 中号 (原16)
  static readonly FONT_SIZE_SMALL = 16  // 小号 (原14)
  static readonly FONT_SIZE_TINY = 14  // 超小 (原12)
  static readonly FONT_SIZE_CAPTION = 12  // 说明文字

  // 间距 - 稍微增大
  static readonly SPACE_TINY = 6
  static readonly SPACE_SMALL = 10
  static readonly SPACE_MEDIUM = 18
  static readonly SPACE_LARGE = 28
  static readonly SPACE_XLARGE = 36
  static readonly SPACE_XXLARGE = 48

  // 圆角 - 更圆润的设计
  static readonly BORDER_RADIUS_SMALL = 10
  static readonly BORDER_RADIUS_MEDIUM = 16
  static readonly BORDER_RADIUS_LARGE = 24
  static readonly BORDER_RADIUS_XLARGE = 32
  static readonly BORDER_RADIUS_FULL = 999

  // 阴影和深度 - 更柔和的阴影
  static readonly SHADOW_SMALL: ShadowOptions = {
    radius: 8,
    color: '#00000008',
    offsetX: 0,
    offsetY: 2
  }
  static readonly SHADOW_MEDIUM: ShadowOptions = {
    radius: 16,
    color: '#00000012',
    offsetX: 0,
    offsetY: 6
  }
  static readonly SHADOW_LARGE: ShadowOptions = {
    radius: 24,
    color: '#00000018',
    offsetX: 0,
    offsetY: 10
  }
  static readonly SHADOW_GLOW: ShadowOptions = {
    radius: 20,
    color: '#7C3AED30',
    offsetX: 0,
    offsetY: 4
  }

  // 透明度
  static readonly OPACITY_DISABLED = 0.4
  static readonly OPACITY_HOVER = 0.9
  static readonly OPACITY_PRESSED = 0.7
  static readonly OPACITY_OVERLAY = 0.6

  // 渐变色 - 类似Flocus的柔和渐变
  static readonly GRADIENT_PRIMARY: GradientColor[] = [
    { color: '#A78BFA', offset: 0 },
    { color: '#7C3AED', offset: 1 }
  ]
  static readonly GRADIENT_PURPLE: GradientColor[] = [
    { color: '#C4B5FD', offset: 0 },
    { color: '#8B5CF6', offset: 1 }
  ]
  static readonly GRADIENT_ORANGE: GradientColor[] = [
    { color: '#FED7AA', offset: 0 },
    { color: '#FB923C', offset: 1 }
  ]
  static readonly GRADIENT_SUNSET: GradientColor[] = [
    { color: '#FECACA', offset: 0 },
    { color: '#FCA5A5', offset: 0.5 },
    { color: '#DDD6FE', offset: 1 }
  ]
  static readonly GRADIENT_SOFT: GradientColor[] = [
    { color: '#F5F3FF', offset: 0 },
    { color: '#FDF2F8', offset: 0.5 },
    { color: '#EFF6FF', offset: 1 }
  ]

  // 动画时长
  static readonly ANIMATION_FAST = 200
  static readonly ANIMATION_NORMAL = 300
  static readonly ANIMATION_SLOW = 500
  static readonly ANIMATION_VERY_SLOW = 800
}
