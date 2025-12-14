import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, completeOnboarding, navigateTo } from './helpers'

/**
 * Students & Subjects E2E Tests (Smoke Tests)
 */

test.describe('Students', () => {
  
  test('should navigate to students page', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page)
    await navigateTo(page, '/students')
    await expect(page).toHaveURL('/students')
  })

  test('should show student from onboarding', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page, {
      students: [{ name: 'Emma', gradeLevel: '5th Grade' }]
    })
    await navigateTo(page, '/students')
    await expect(page.getByText('Emma')).toBeVisible()
  })
})

test.describe('Subjects', () => {
  
  test('should navigate to subjects page', async ({ page }) => {
    const user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page)
    await navigateTo(page, '/subjects')
    await expect(page).toHaveURL('/subjects')
  })
})
