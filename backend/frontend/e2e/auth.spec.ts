import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, navigateTo, completeOnboarding } from './helpers'

/**
 * Authentication E2E Tests (Smoke Tests)
 */

test.describe('Authentication', () => {
  
  test('should show registration form', async ({ page }) => {
    await navigateTo(page, '/register')
    await expect(page).toHaveURL('/register')
    await expect(page.locator('#email')).toBeVisible()
    await expect(page.locator('#password')).toBeVisible()
  })

  test('should show login form', async ({ page }) => {
    await navigateTo(page, '/login')
    await expect(page).toHaveURL('/login')
    await expect(page.locator('#email')).toBeVisible()
    await expect(page.locator('#password')).toBeVisible()
  })

  test('should register new user and redirect to onboarding', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await expect(page).toHaveURL('/onboarding')
  })

  test('should complete full onboarding flow', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page)
    // After onboarding, should be on dashboard (or root)
    const url = page.url()
    expect(url.endsWith('/') || url.includes('/dashboard')).toBeTruthy()
  })
})
