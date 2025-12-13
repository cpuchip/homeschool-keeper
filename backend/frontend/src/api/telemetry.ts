import client from './client'

const INSTALL_ID_KEY = 'telemetry_install_id'
const ENABLED_KEY = 'telemetry_enabled'
const FIRST_LAUNCH_KEY = 'telemetry_first_launch'
const PENDING_EVENTS_KEY = 'telemetry_pending_events'

// Telemetry event names
export const TelemetryEvents = {
  // Tier 1 - Essential
  APP_INSTALL: 'app_install',
  SESSION_START: 'session_start',
  SESSION_END: 'session_end',

  // Tier 2 - Usage
  SCREEN_VIEW: 'screen_view',
  ONBOARDING_STARTED: 'onboarding_started',
  ONBOARDING_COMPLETED: 'onboarding_completed',
  ACCOUNT_CREATED: 'account_created',
  SYNC_ENABLED: 'sync_enabled',
  LOG_CREATED: 'log_created',
  LOG_EDITED: 'log_edited',
  STUDENT_ADDED: 'student_added',
  SUBJECT_ADDED: 'subject_added',
  WORK_SAMPLE_ADDED: 'work_sample_added',
  EXPORT_GENERATED: 'export_generated',
  TELEMETRY_OPT_OUT: 'telemetry_opt_out',
  TELEMETRY_OPT_IN: 'telemetry_opt_in',
}

class TelemetryService {
  private installId: string | null = null
  private enabled = true
  private initialized = false
  private pendingEvents: Array<Record<string, unknown>> = []
  private flushTimer: ReturnType<typeof setInterval> | null = null
  private appVersion = '1.0.0' // Will be updated from package.json or build

  async init(): Promise<void> {
    if (this.initialized) return

    // Get or create install ID
    this.installId = localStorage.getItem(INSTALL_ID_KEY)
    if (!this.installId) {
      this.installId = this.generateUUID()
      localStorage.setItem(INSTALL_ID_KEY, this.installId)
    }

    // Check if enabled (default true)
    const enabledStr = localStorage.getItem(ENABLED_KEY)
    this.enabled = enabledStr === null ? true : enabledStr === 'true'

    // Load pending events
    this.loadPendingEvents()

    this.initialized = true

    // Track first launch if needed
    const isFirstLaunch = localStorage.getItem(FIRST_LAUNCH_KEY) === null
    if (isFirstLaunch) {
      localStorage.setItem(FIRST_LAUNCH_KEY, 'false')
      this.trackEvent(TelemetryEvents.APP_INSTALL)
    }

    // Start flush timer (every 30 seconds)
    this.flushTimer = setInterval(() => this.flush(), 30000)

    // Track session start
    this.trackEvent(TelemetryEvents.SESSION_START)

    // Track session end on page unload
    window.addEventListener('beforeunload', () => {
      this.trackEvent(TelemetryEvents.SESSION_END)
      this.flushSync()
    })
  }

  private generateUUID(): string {
    // Simple UUID v4 generation
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0
      const v = c === 'x' ? r : (r & 0x3) | 0x8
      return v.toString(16)
    })
  }

  get isEnabled(): boolean {
    return this.enabled
  }

  get getInstallId(): string | null {
    return this.installId
  }

  setEnabled(enabled: boolean): void {
    this.enabled = enabled
    localStorage.setItem(ENABLED_KEY, String(enabled))

    // Track opt-in/opt-out (this one still goes through)
    if (enabled) {
      this.trackEventInternal(TelemetryEvents.TELEMETRY_OPT_IN)
    } else {
      this.trackEventInternal(TelemetryEvents.TELEMETRY_OPT_OUT)
    }
    this.flush()
  }

  trackEvent(event: string, data?: Record<string, unknown>): void {
    if (!this.enabled || !this.initialized) return
    this.trackEventInternal(event, data)
  }

  private trackEventInternal(event: string, data?: Record<string, unknown>): void {
    const eventData: Record<string, unknown> = {
      installId: this.installId,
      appVersion: this.appVersion,
      platform: 'web',
      event,
      timestamp: new Date().toISOString(),
    }

    if (data && Object.keys(data).length > 0) {
      eventData.data = data
    }

    this.pendingEvents.push(eventData)

    // If we have 10+ events, flush immediately
    if (this.pendingEvents.length >= 10) {
      this.flush()
    }
  }

  trackScreen(screenName: string): void {
    this.trackEvent(TelemetryEvents.SCREEN_VIEW, { screen: screenName })
  }

  async flush(): Promise<void> {
    if (this.pendingEvents.length === 0) return

    const events = [...this.pendingEvents]
    this.pendingEvents = []

    try {
      await client.post('/api/v1/telemetry/batch', { events })
      this.clearPendingEvents()
    } catch (e) {
      // Failed - save for later
      this.pendingEvents = [...events, ...this.pendingEvents]
      this.savePendingEvents()
      console.debug('Telemetry flush failed:', e)
    }
  }

  // Synchronous flush for beforeunload
  private flushSync(): void {
    if (this.pendingEvents.length === 0) return

    try {
      const xhr = new XMLHttpRequest()
      xhr.open('POST', '/api/v1/telemetry/batch', false) // false = synchronous
      xhr.setRequestHeader('Content-Type', 'application/json')
      xhr.send(JSON.stringify({ events: this.pendingEvents }))
      this.pendingEvents = []
    } catch (e) {
      // Save for next session
      this.savePendingEvents()
    }
  }

  private savePendingEvents(): void {
    try {
      const eventsToSave = this.pendingEvents.slice(0, 100)
      localStorage.setItem(PENDING_EVENTS_KEY, JSON.stringify(eventsToSave))
    } catch (e) {
      // Ignore storage errors
    }
  }

  private loadPendingEvents(): void {
    try {
      const saved = localStorage.getItem(PENDING_EVENTS_KEY)
      if (saved) {
        this.pendingEvents = JSON.parse(saved)
        localStorage.removeItem(PENDING_EVENTS_KEY)
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  private clearPendingEvents(): void {
    try {
      localStorage.removeItem(PENDING_EVENTS_KEY)
    } catch (e) {
      // Ignore errors
    }
  }

  dispose(): void {
    if (this.flushTimer) {
      clearInterval(this.flushTimer)
    }
    this.flush()
  }
}

// Singleton instance
export const telemetry = new TelemetryService()

// Initialize on import
telemetry.init()
