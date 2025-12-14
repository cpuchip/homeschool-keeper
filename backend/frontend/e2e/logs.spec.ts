import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, completeOnboarding, navigateTo } from './helpers'

/**
 * Log Entries E2E Tests (Smoke Tests)
 */

test.describe('Log Entries', () => {
  
  test('should navigate to quick log page', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page)
    await navigateTo(page, '/quick-log')
    await expect(page).toHaveURL('/quick-log')
  })

  test('should navigate to logs list page', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page)
    await navigateTo(page, '/logs')
    await expect(page).toHaveURL('/logs')
  })
})
