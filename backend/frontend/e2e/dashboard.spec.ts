import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, completeOnboarding, navigateTo } from './helpers'

/**
 * Dashboard E2E Tests (Smoke Tests)
 */

test.describe('Dashboard', () => {
  
  test('should display dashboard after onboarding', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page)
    // Should be on root or dashboard
    const url = page.url()
    expect(url.endsWith('/') || url.includes('/dashboard')).toBeTruthy()
  })

  test('should show student on students page after onboarding', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page, {
      students: [{ name: 'Emma', gradeLevel: '5th Grade' }]
    })
    await navigateTo(page, '/students')
    await expect(page.getByText('Emma')).toBeVisible()
  })
})
