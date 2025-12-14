import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, navigateTo } from './helpers'

/**
 * Onboarding E2E Tests (Smoke Tests)
 */

test.describe('Onboarding', () => {
  
  test('should show onboarding page after registration', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await expect(page).toHaveURL('/onboarding')
  })

  test('should display welcome heading', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await expect(page.getByRole('heading', { name: /welcome/i })).toBeVisible()
  })

  test('should have Continue button on first step', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await expect(page.getByRole('button', { name: 'Continue' })).toBeVisible()
  })
})
