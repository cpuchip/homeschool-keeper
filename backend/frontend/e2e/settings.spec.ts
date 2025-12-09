import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, completeOnboarding, navigateTo } from './helpers'

/**
 * Settings E2E Tests (Smoke Tests)
 */

test.describe('Settings', () => {
  
  test('should navigate to settings page', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page)
    await navigateTo(page, '/settings')
    await expect(page).toHaveURL('/settings')
  })
})
