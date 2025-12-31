/**
 * Onboarding flow configuration for the in-app guide.
 */

export type OnboardingRoute = 'HOME' | 'TIMER' | 'HISTORY' | 'REST_MODE'
export type AdvanceRule = 'TAP_ANYWHERE_EXCEPT_SKIP' | 'TAP_TARGET_ONLY'

export interface OnboardingRect {
  x: number
  y: number
  width: number
  height: number
}

export class OnboardingTargets {
  home_list_area?: OnboardingRect
  home_demo_task_row?: OnboardingRect
  home_history_icon?: OnboardingRect
  history_list_area?: OnboardingRect
  timer_start_focus_button?: OnboardingRect
  timer_display_area?: OnboardingRect
  timer_rest_button?: OnboardingRect
  timer_end_rest_button?: OnboardingRect
  timer_pause_button?: OnboardingRect
  timer_complete_button?: OnboardingRect
}

export interface OnboardingStep {
  id: string
  route: OnboardingRoute
  targetId?: string
  body?: string
  rule?: AdvanceRule
  isSetup?: boolean
}

export const DEBUG_ALWAYS_SHOW_ONBOARDING: boolean = true

export const DEMO_TASK_TITLE: string = '数学'
export const DEMO_TASK_DESCRIPTION: string = '完成微积分作业'

export const ONBOARDING_STEPS: OnboardingStep[] = [
  {
    id: 'setup_demo_task',
    route: 'HOME',
    isSetup: true
  },
  {
    id: 's1_home_list_intro',
    route: 'HOME',
    targetId: 'home_list_area',
    body: '你可以在待办事项里创建并追踪任务。',
    rule: 'TAP_ANYWHERE_EXCEPT_SKIP'
  },
  {
    id: 's2_select_demo_task',
    route: 'HOME',
    targetId: 'home_demo_task_row',
    body: '选一个任务试试（点这条任务就行）。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 's3_start_focus',
    route: 'TIMER',
    targetId: 'timer_start_focus_button',
    body: '点“开始专注”，系统会记录你的专注时间，也会记录休息时间。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 's4_timer_display',
    route: 'TIMER',
    targetId: 'timer_display_area',
    body: '这里会显示：这次专注过了多久，以及这个任务累计的总专注时间。',
    rule: 'TAP_ANYWHERE_EXCEPT_SKIP'
  },
  {
    id: 's5a_rest_button',
    route: 'TIMER',
    targetId: 'timer_rest_button',
    body: '点“休息”会暂停专注计时，并记录你的休息时长。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 's5b_end_rest',
    route: 'REST_MODE',
    targetId: 'timer_end_rest_button',
    body: '记得结束休息，别放松太久哦。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 's6a_pause',
    route: 'TIMER',
    targetId: 'timer_pause_button',
    body: '如果这任务一口气做不完，可以先暂停，之后再继续。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 's6b_resume_focus',
    route: 'TIMER',
    targetId: 'timer_start_focus_button',
    body: '我们继续这个任务，点“开始专注”。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 's7_complete_task',
    route: 'TIMER',
    targetId: 'timer_complete_button',
    body: '点“完成”会结束这次专注，并把任务标记为已完成。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 's8_history_entry',
    route: 'HOME',
    targetId: 'home_history_icon',
    body: '已完成的任务可以在“历史任务”里查看。',
    rule: 'TAP_TARGET_ONLY'
  },
  {
    id: 'end_history_page',
    route: 'HISTORY',
    targetId: 'history_list_area',
    body: '这里就是你的历史任务列表。教程结束啦！',
    rule: 'TAP_ANYWHERE_EXCEPT_SKIP'
  }
]

export function shouldShowOnboarding(hasSeen: boolean, disabled: boolean): boolean {
  if (disabled) {
    return false
  }
  return DEBUG_ALWAYS_SHOW_ONBOARDING || !hasSeen
}

export function getOnboardingStep(stepId: string): OnboardingStep | undefined {
  return ONBOARDING_STEPS.find((step) => step.id === stepId)
}

export function getFirstOnboardingStepId(): string {
  return ONBOARDING_STEPS[0].id
}

export function getOnboardingTarget(targets: OnboardingTargets, targetId: string): OnboardingRect | undefined {
  switch (targetId) {
    case 'home_list_area':
      return targets.home_list_area
    case 'home_demo_task_row':
      return targets.home_demo_task_row
    case 'home_history_icon':
      return targets.home_history_icon
    case 'history_list_area':
      return targets.history_list_area
    case 'timer_start_focus_button':
      return targets.timer_start_focus_button
    case 'timer_display_area':
      return targets.timer_display_area
    case 'timer_rest_button':
      return targets.timer_rest_button
    case 'timer_end_rest_button':
      return targets.timer_end_rest_button
    case 'timer_pause_button':
      return targets.timer_pause_button
    case 'timer_complete_button':
      return targets.timer_complete_button
    default:
      return undefined
  }
}

export function updateOnboardingTargets(
  current: OnboardingTargets,
  targetId: string,
  rect: OnboardingRect
): OnboardingTargets {
  const next = new OnboardingTargets()
  next.home_list_area = current.home_list_area
  next.home_demo_task_row = current.home_demo_task_row
  next.home_history_icon = current.home_history_icon
  next.timer_start_focus_button = current.timer_start_focus_button
  next.timer_display_area = current.timer_display_area
  next.timer_rest_button = current.timer_rest_button
  next.timer_end_rest_button = current.timer_end_rest_button
  next.timer_pause_button = current.timer_pause_button
  next.timer_complete_button = current.timer_complete_button

  switch (targetId) {
    case 'home_list_area':
      next.home_list_area = rect
      break
    case 'home_demo_task_row':
      next.home_demo_task_row = rect
      break
    case 'home_history_icon':
      next.home_history_icon = rect
      break
    case 'history_list_area':
      next.history_list_area = rect
      break
    case 'timer_start_focus_button':
      next.timer_start_focus_button = rect
      break
    case 'timer_display_area':
      next.timer_display_area = rect
      break
    case 'timer_rest_button':
      next.timer_rest_button = rect
      break
    case 'timer_end_rest_button':
      next.timer_end_rest_button = rect
      break
    case 'timer_pause_button':
      next.timer_pause_button = rect
      break
    case 'timer_complete_button':
      next.timer_complete_button = rect
      break
    default:
      break
  }

  return next
}
