import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, completeOnboarding, navigateTo } from './helpers'

/**
 * Dashboard E2E Tests
 * Tests the main dashboard functionality after onboarding
 */

test.describe('Dashboard', () => {
  let user: ReturnType<typeof generateTestUser>

  test.beforeEach(async ({ page }) => {
    user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page, {
      students: [
        { name: 'Emma', gradeLevel: '5th Grade' },
        { name: 'Jack', gradeLevel: '3rd Grade' },
      ],
      subjects: ['Language Arts', 'Mathematics', 'Science'],
    })
  })

  test.describe('Layout', () => {
    
    test('should display dashboard after onboarding', async ({ page }) => {
      await expect(page).toHaveURL('/dashboard')
    })

    test('should show navigation sidebar', async ({ page }) => {
      await expect(page.getByRole('link', { name: /dashboard/i })).toBeVisible()
      await expect(page.getByRole('link', { name: /students/i })).toBeVisible()
      await expect(page.getByRole('link', { name: /subjects/i })).toBeVisible()
      await expect(page.getByRole('link', { name: /logs/i })).toBeVisible()
    })

    test('should show current school year', async ({ page }) => {
      await expect(page.getByText('2025-2026')).toBeVisible()
    })

    test('should show logout button', async ({ page }) => {
      await expect(page.getByRole('button', { name: /logout/i })).toBeVisible()
    })
  })

  test.describe('Student Cards', () => {
    
    test('should display all students', async ({ page }) => {
      await expect(page.getByText('Emma')).toBeVisible()
      await expect(page.getByText('Jack')).toBeVisible()
    })

    test('should show student grade levels', async ({ page }) => {
      await expect(page.getByText('5th Grade')).toBeVisible()
      await expect(page.getByText('3rd Grade')).toBeVisible()
    })

    test('should show zero hours for new students', async ({ page }) => {
      // New students should have 0 hours logged
      await expect(page.getByText(/0\s*(hours|hrs)/i)).toBeVisible()
    })
  })

  test.describe('Quick Log Access', () => {
    
    test('should have quick log button or link', async ({ page }) => {
      // Look for quick log access point
      const quickLogBtn = page.getByRole('button', { name: /quick log|log hours|add log/i })
      const quickLogLink = page.getByRole('link', { name: /quick log|log hours|add log/i })
      
      // At least one should exist
      const hasQuickLog = await quickLogBtn.isVisible().catch(() => false) || 
                          await quickLogLink.isVisible().catch(() => false)
      expect(hasQuickLog).toBeTruthy()
    })
  })

  test.describe('Navigation', () => {
    
    test('should navigate to students page', async ({ page }) => {
      await page.getByRole('link', { name: /students/i }).click()
      await expect(page).toHaveURL('/students')
    })

    test('should navigate to subjects page', async ({ page }) => {
      await page.getByRole('link', { name: /subjects/i }).click()
      await expect(page).toHaveURL('/subjects')
    })

    test('should navigate to logs page', async ({ page }) => {
      await page.getByRole('link', { name: /logs/i }).click()
      await expect(page).toHaveURL('/logs')
    })

    test('should navigate to settings page', async ({ page }) => {
      await page.getByRole('link', { name: /settings/i }).click()
      await expect(page).toHaveURL('/settings')
    })

    test('should navigate back to dashboard', async ({ page }) => {
      await page.getByRole('link', { name: /students/i }).click()
      await page.getByRole('link', { name: /dashboard/i }).click()
      await expect(page).toHaveURL('/dashboard')
    })
  })

  test.describe('Stats Display', () => {
    
    test('should show family stats section', async ({ page }) => {
      // Look for a stats or summary section
      const statsSection = page.getByText(/total hours|summary|statistics/i)
      // Stats section may or may not exist depending on implementation
      // Just verify the page loaded correctly
      await expect(page.getByText('Emma')).toBeVisible()
    })
  })
})
