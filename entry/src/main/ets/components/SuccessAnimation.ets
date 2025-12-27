/**
 * 成功动画组件 - 任务创建成功、完成专注时展示
 */
import { Theme } from '../common/theme'

// 粒子接口
interface Particle {
  x: number
  y: number
  vx: number
  vy: number
  size: number
  color: string
  alpha: number
  rotation: number
}

@Component
export struct SuccessAnimation {
  @Link visible: boolean
  @Prop type: 'create' | 'complete' = 'create'
  @Prop message: string = ''
  @State animScale: number = 0
  @State animOpacity: number = 0
  @State iconScale: number = 0
  @State particles: Particle[] = []
  @State ringScale: number = 0
  @State ringOpacity: number = 0
  @State secondRingScale: number = 0
  @State secondRingOpacity: number = 0
  @State showConfetti: boolean = false
  private animationTimer: number = -1
  private closeTimer: number = -1
  private particleTimer: number = -1

  aboutToAppear() {
    if (this.visible) {
      this.startAnimation()
    }
  }

  aboutToDisappear() {
    this.clearTimers()
  }

  private clearTimers() {
    if (this.animationTimer !== -1) {
      clearTimeout(this.animationTimer)
      this.animationTimer = -1
    }
    if (this.closeTimer !== -1) {
      clearTimeout(this.closeTimer)
      this.closeTimer = -1
    }
    if (this.particleTimer !== -1) {
      clearInterval(this.particleTimer)
      this.particleTimer = -1
    }
  }

  private startAnimation() {
    this.clearTimers()
    this.animScale = 0
    this.animOpacity = 0
    this.iconScale = 0
    this.ringScale = 0
    this.ringOpacity = 0
    this.secondRingScale = 0
    this.secondRingOpacity = 0
    this.showConfetti = false

    // 生成粒子
    this.generateParticles()

    // 主体淡入放大
    this.animationTimer = setTimeout(() => {
      this.animOpacity = 1
      this.animScale = 1
      
      // 图标弹跳
      setTimeout(() => {
        this.iconScale = 1.2
        setTimeout(() => {
          this.iconScale = 1
        }, 150)
      }, 200)

      // 波纹效果
      setTimeout(() => {
        this.ringScale = 1.5
        this.ringOpacity = 0.6
        setTimeout(() => {
          this.ringOpacity = 0
        }, 400)
      }, 100)

      // 第二波纹
      setTimeout(() => {
        this.secondRingScale = 1.8
        this.secondRingOpacity = 0.4
        setTimeout(() => {
          this.secondRingOpacity = 0
        }, 500)
      }, 300)

      // 显示彩屑
      if (this.type === 'complete') {
        setTimeout(() => {
          this.showConfetti = true
        }, 200)
      }
    }, 50)

    // 自动关闭
    this.closeTimer = setTimeout(() => {
      this.closeAnimation()
    }, 2500)
  }

  private closeAnimation() {
    this.animOpacity = 0
    this.animScale = 0.8
    setTimeout(() => {
      this.visible = false
      this.showConfetti = false
    }, 300)
  }

  private generateParticles() {
    const colors = ['#7C3AED', '#8B5CF6', '#A78BFA', '#C4B5FD', '#F59E0B', '#10B981', '#EC4899']
    const newParticles: Particle[] = []
    const count = this.type === 'complete' ? 20 : 12
    
    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + Math.random() * 0.5
      const speed = 3 + Math.random() * 4
      newParticles.push({
        x: 0,
        y: 0,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        size: 6 + Math.random() * 8,
        color: colors[Math.floor(Math.random() * colors.length)],
        alpha: 1,
        rotation: Math.random() * 360
      })
    }
    this.particles = newParticles

    // 更新粒子位置
    let frame = 0
    this.particleTimer = setInterval(() => {
      frame++
      if (frame > 40) {
        if (this.particleTimer !== -1) {
          clearInterval(this.particleTimer)
          this.particleTimer = -1
        }
        return
      }

      const updated = this.particles.map(p => {
        return {
          x: p.x + p.vx,
          y: p.y + p.vy,
          vx: p.vx * 0.96,
          vy: p.vy * 0.96 + 0.3,
          size: p.size,
          color: p.color,
          alpha: Math.max(0, p.alpha - 0.025),
          rotation: p.rotation + 10
        } as Particle
      })
      this.particles = updated
    }, 30)
  }

  build() {
    if (this.visible) {
      Stack() {
        // 半透明遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Theme.COLOR_OVERLAY)
          .opacity(this.animOpacity * 0.8)
          .onClick(() => {
            this.closeAnimation()
          })

        // 主容器
        Column({ space: 20 }) {
          // 动画圆环和图标
          Stack() {
            // 第一波纹
            Circle()
              .width(140)
              .height(140)
              .fill(Color.Transparent)
              .stroke(Theme.COLOR_TEXT_PRIMARY)
              .strokeWidth(3)
              .scale({ x: this.ringScale, y: this.ringScale })
              .opacity(this.ringOpacity)
              .animation({
                duration: Theme.ANIMATION_SLOW,
                curve: Curve.EaseOut
              })

            // 第二波纹
            Circle()
              .width(140)
              .height(140)
              .fill(Color.Transparent)
              .stroke(Theme.COLOR_TEXT_SECONDARY)
              .strokeWidth(2)
              .scale({ x: this.secondRingScale, y: this.secondRingScale })
              .opacity(this.secondRingOpacity)
              .animation({
                duration: Theme.ANIMATION_SLOW,
                curve: Curve.EaseOut
              })

            // 主圆形背景
            Circle()
              .width(120)
              .height(120)
              .fill(Theme.COLOR_CARD_BACKGROUND)

            // 图标
            Text(this.type === 'complete' ? '🎉' : '✓')
              .fontSize(this.type === 'complete' ? 56 : 48)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .scale({ x: this.iconScale, y: this.iconScale })
              .animation({
                duration: 200,
                curve: Curve.FastOutSlowIn
              })

            // 粒子效果
            ForEach(this.particles, (particle: Particle, index: number) => {
              if (particle.alpha > 0) {
                if (this.type === 'complete') {
                  // 完成时用方块和圆形混合
                  if (index % 2 === 0) {
                    Circle()
                      .width(particle.size)
                      .height(particle.size)
                      .fill(particle.color)
                      .position({
                        x: 60 + particle.x - particle.size / 2,
                        y: 60 + particle.y - particle.size / 2
                      })
                      .opacity(particle.alpha)
                  } else {
                    Column()
                      .width(particle.size)
                      .height(particle.size)
                      .backgroundColor(particle.color)
                      .borderRadius(2)
                      .position({
                        x: 60 + particle.x - particle.size / 2,
                        y: 60 + particle.y - particle.size / 2
                      })
                      .rotate({ angle: particle.rotation })
                      .opacity(particle.alpha)
                  }
                } else {
                  // 创建时用圆形
                  Circle()
                    .width(particle.size)
                    .height(particle.size)
                    .fill(particle.color)
                    .position({
                      x: 60 + particle.x - particle.size / 2,
                      y: 60 + particle.y - particle.size / 2
                    })
                    .opacity(particle.alpha)
                }
              }
            })
          }
          .width(140)
          .height(140)

          // 文字信息
          Column({ space: 8 }) {
            Text(this.type === 'complete' ? '专注完成！' : '创建成功！')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)

            if (this.message) {
              Text(this.message)
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
            }
          }
        }
        .padding(Theme.SPACE_XLARGE)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_XLARGE)
        .shadow(Theme.SHADOW_LARGE)
        .scale({ x: this.animScale, y: this.animScale })
        .opacity(this.animOpacity)
        .animation({
          duration: Theme.ANIMATION_NORMAL,
          curve: Curve.FastOutSlowIn
        })
      }
      .width('100%')
      .height('100%')
    }
  }
}

// 简易Toast动画
@Component
export struct AnimatedToast {
  @Link visible: boolean
  @Prop message: string = ''
  @Prop icon: string = '✓'
  @Prop duration: number = 2000
  @State translateY: number = 100
  @State toastOpacity: number = 0
  private closeTimer: number = -1

  aboutToAppear() {
    if (this.visible) {
      this.show()
    }
  }

  aboutToDisappear() {
    if (this.closeTimer !== -1) {
      clearTimeout(this.closeTimer)
      this.closeTimer = -1
    }
  }

  private show() {
    this.translateY = 100
    this.toastOpacity = 0
    
    setTimeout(() => {
      this.translateY = 0
      this.toastOpacity = 1
    }, 50)

    this.closeTimer = setTimeout(() => {
      this.hide()
    }, this.duration)
  }

  private hide() {
    this.translateY = 100
    this.toastOpacity = 0
    setTimeout(() => {
      this.visible = false
    }, 300)
  }

  build() {
    if (this.visible) {
      Row({ space: 12 }) {
        Text(this.icon)
          .fontSize(22)

        Text(this.message)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 20, right: 24, top: 14, bottom: 14 })
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .borderRadius(Theme.BORDER_RADIUS_FULL)
      .shadow(Theme.SHADOW_MEDIUM)
      .translate({ y: this.translateY })
      .opacity(this.toastOpacity)
      .animation({
        duration: 300,
        curve: Curve.FastOutSlowIn
      })
      .position({ x: '50%', y: '85%' })
      .markAnchor({ x: '50%', y: '50%' })
    }
  }
}
