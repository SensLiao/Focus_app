/**
 * Full-screen onboarding overlay with optional target highlight.
 */

import { Theme } from '../common/theme'
import { AdvanceRule, OnboardingRect } from '../onboarding/OnboardingFlow'

export interface OnboardingOverlayProps {
  visible: boolean
  body: string
  rule: AdvanceRule
  target?: OnboardingRect
  showSkip?: boolean
}

@Component
export struct OnboardingOverlay {
  @Prop visible: boolean = false
  @Prop body: string = ''
  @Prop rule: AdvanceRule = 'TAP_ANYWHERE_EXCEPT_SKIP'
  @Prop target?: OnboardingRect
  @Prop showSkip: boolean = true
  @StorageLink('onboardingAdvanceTick') onboardingAdvanceTick: number = 0
  @StorageLink('onboardingSkipTick') onboardingSkipTick: number = 0

  @State overlayWidth: number = 0
  @State overlayHeight: number = 0
  @State skipRect: OnboardingRect = { x: 0, y: 0, width: 0, height: 0 }
  @State hasSkipRect: boolean = false

  private readonly dimColor: string = '#c99b9bb3'
  private readonly highlightPadding: number = 6
  private readonly highlightBorderWidth: number = 2
  private readonly bubbleWidthMax: number = 300
  private readonly bubbleMinMargin: number = 16
  private readonly bubbleHeightGuess: number = 120

  private clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max)
  }

  private parseLength(value: Length | undefined): number {
    if (value === undefined) {
      return 0
    }
    if (typeof value === 'number') {
      return value
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value)
      return Number.isNaN(parsed) ? 0 : parsed
    }
    return 0
  }

  private expandRect(rect: OnboardingRect, padding: number): OnboardingRect {
    const x = rect.x - padding
    const y = rect.y - padding
    const width = rect.width + padding * 2
    const height = rect.height + padding * 2
    return { x, y, width, height }
  }

  private isInside(pointX: number, pointY: number, rect?: OnboardingRect): boolean {
    if (!rect) {
      return false
    }
    return pointX >= rect.x
      && pointX <= rect.x + rect.width
      && pointY >= rect.y
      && pointY <= rect.y + rect.height
  }

  private getBubbleRect(target?: OnboardingRect): OnboardingRect {
    const safeWidth = this.overlayWidth > 0 ? this.overlayWidth : 360
    const safeHeight = this.overlayHeight > 0 ? this.overlayHeight : 640
    const width = Math.min(safeWidth - this.bubbleMinMargin * 2, this.bubbleWidthMax)
    const height = this.bubbleHeightGuess
    if (!target) {
      const x = this.clamp((safeWidth - width) / 2, this.bubbleMinMargin, safeWidth - width - this.bubbleMinMargin)
      const y = this.clamp((safeHeight - height) / 2, this.bubbleMinMargin, safeHeight - height - this.bubbleMinMargin)
      return { x, y, width, height }
    }

    const centerX = target.x + target.width / 2
    const x = this.clamp(centerX - width / 2, this.bubbleMinMargin, safeWidth - width - this.bubbleMinMargin)
    const belowY = target.y + target.height + this.bubbleMinMargin
    const canPlaceBelow = belowY + height <= safeHeight - this.bubbleMinMargin
    const y = canPlaceBelow
      ? belowY
      : this.clamp((safeHeight - height) / 2, this.bubbleMinMargin, safeHeight - height - this.bubbleMinMargin)
    return { x, y, width, height }
  }

  private getHighlightRect(): OnboardingRect | undefined {
    if (!this.target) {
      return undefined
    }
    if (this.overlayWidth <= 0 || this.overlayHeight <= 0) {
      return undefined
    }
    return this.expandRect(this.target, this.highlightPadding)
  }

  private hasHighlight(): boolean {
    return this.getHighlightRect() !== undefined
  }

  private getHighlightX(): number {
    return this.getHighlightRect()?.x ?? 0
  }

  private getHighlightY(): number {
    return this.getHighlightRect()?.y ?? 0
  }

  private getHighlightWidth(): number {
    return this.getHighlightRect()?.width ?? 0
  }

  private getHighlightHeight(): number {
    return this.getHighlightRect()?.height ?? 0
  }

  private getBubbleWidth(): number {
    return this.getBubbleRect(this.getHighlightRect()).width
  }

  private getBubbleHeight(): number {
    return this.getBubbleRect(this.getHighlightRect()).height
  }

  private getBubbleX(): number {
    return this.getBubbleRect(this.getHighlightRect()).x
  }

  private getBubbleY(): number {
    return this.getBubbleRect(this.getHighlightRect()).y
  }

  private handleTouch(event: TouchEvent) {
    if (event.type !== TouchType.Down) {
      return
    }
    const touch = event.touches[0]
    const pointX = touch.x
    const pointY = touch.y
    if (this.hasSkipRect && this.isInside(pointX, pointY, this.skipRect)) {
      return
    }
    if (this.rule === 'TAP_TARGET_ONLY') {
      if (this.isInside(pointX, pointY, this.target)) {
        this.onboardingAdvanceTick = this.onboardingAdvanceTick + 1
      }
      return
    }
    this.onboardingAdvanceTick = this.onboardingAdvanceTick + 1
  }

  build() {
    Stack() {
      if (this.visible) {
        if (this.hasHighlight()) {
          Column()
            .width('100%')
            .height(this.getHighlightY())
            .backgroundColor(this.dimColor)
            .position({ x: 0, y: 0 })

          Column()
            .width(this.getHighlightX())
            .height(this.getHighlightHeight())
            .backgroundColor(this.dimColor)
            .position({ x: 0, y: this.getHighlightY() })

          Column()
            .width(Math.max(0, this.overlayWidth - (this.getHighlightX() + this.getHighlightWidth())))
            .height(this.getHighlightHeight())
            .backgroundColor(this.dimColor)
            .position({ x: this.getHighlightX() + this.getHighlightWidth(), y: this.getHighlightY() })

          Column()
            .width('100%')
            .height(Math.max(0, this.overlayHeight - (this.getHighlightY() + this.getHighlightHeight())))
            .backgroundColor(this.dimColor)
            .position({ x: 0, y: this.getHighlightY() + this.getHighlightHeight() })

          Column()
            .width(this.getHighlightWidth())
            .height(this.getHighlightHeight())
            .border({
              width: this.highlightBorderWidth,
              color: Theme.COLOR_PRIMARY
            })
            .borderRadius(0)
            .position({ x: this.getHighlightX(), y: this.getHighlightY() })
        } else {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.dimColor)
        }

        Column() {
          Text(this.body)
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
            .textAlign(TextAlign.Center)
            .lineHeight(22)
        }
        .width(this.getBubbleWidth())
        .padding(16)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
        .shadow(Theme.SHADOW_MEDIUM)
        .position({ x: this.getBubbleX(), y: this.getBubbleY() })

        if (this.showSkip) {
          Button('跳过')
            .height(36)
            .fontSize(Theme.FONT_SIZE_SMALL)
            .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
            .border({ width: 1, color: Theme.COLOR_BORDER })
            .borderRadius(Theme.BORDER_RADIUS_FULL)
            .padding({ left: 14, right: 14 })
            .position({ x: Math.max(this.bubbleMinMargin, this.overlayWidth - 70), y: 32 })
            .onClick(() => {
              this.onboardingSkipTick = this.onboardingSkipTick + 1
            })
            .onAreaChange((oldArea, newArea) => {
              this.skipRect = {
                x: this.parseLength(newArea.position.x),
                y: this.parseLength(newArea.position.y),
                width: this.parseLength(newArea.width),
                height: this.parseLength(newArea.height)
              }
              this.hasSkipRect = true
            })
        }
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((oldArea, newArea) => {
      this.overlayWidth = this.parseLength(newArea.width)
      this.overlayHeight = this.parseLength(newArea.height)
    })
    .onTouch((event: TouchEvent) => {
      this.handleTouch(event)
    })
  }
}
