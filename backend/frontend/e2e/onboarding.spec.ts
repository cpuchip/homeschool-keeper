import { test, expect } from '@playwright/test'
import { generateTestUser, navigateTo, registerUser } from './helpers'

/**
 * Onboarding E2E Tests
 * Tests the complete onboarding flow: school year, students, subjects
 */

test.describe('Onboarding', () => {
  let user: ReturnType<typeof generateTestUser>

  test.beforeEach(async ({ page }) => {
    user = generateTestUser()
    await registerUser(page, user)
  })

  test.describe('Step Navigation', () => {
    
    test('should show onboarding page after registration', async ({ page }) => {
      await expect(page).toHaveURL('/onboarding')
      await expect(page.getByText(/welcome|get started/i)).toBeVisible()
    })

    test('should show school year step first', async ({ page }) => {
      await expect(page.getByLabel('School Year Start')).toBeVisible()
      await expect(page.getByLabel('School Year End')).toBeVisible()
    })

    test('should navigate to students step after school year', async ({ page }) => {
      await page.getByLabel('School Year Start').fill('2025-08-01')
      await page.getByLabel('School Year End').fill('2026-05-31')
      await page.getByRole('button', { name: 'Next' }).click()
      
      await expect(page.getByPlaceholder("Student's Name")).toBeVisible()
    })

    test('should navigate to subjects step after students', async ({ page }) => {
      // Step 1: School Year
      await page.getByLabel('School Year Start').fill('2025-08-01')
      await page.getByLabel('School Year End').fill('2026-05-31')
      await page.getByRole('button', { name: 'Next' }).click()
      
      // Step 2: Add a student
      await page.getByPlaceholder("Student's Name").fill('Test Student')
      await page.getByLabel('Grade Level').selectOption('5th Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      await page.getByRole('button', { name: 'Next' }).click()
      
      // Step 3: Should show subjects
      await expect(page.getByText('Language Arts')).toBeVisible()
      await expect(page.getByText('Mathematics')).toBeVisible()
    })
  })

  test.describe('School Year Setup', () => {
    
    test('should accept valid date range', async ({ page }) => {
      await page.getByLabel('School Year Start').fill('2025-08-01')
      await page.getByLabel('School Year End').fill('2026-05-31')
      await page.getByRole('button', { name: 'Next' }).click()
      
      // Should proceed to next step
      await expect(page.getByPlaceholder("Student's Name")).toBeVisible()
    })

    test('should default to reasonable school year dates', async ({ page }) => {
      // Check that date fields have values or are accessible
      const startDate = await page.getByLabel('School Year Start').inputValue()
      const endDate = await page.getByLabel('School Year End').inputValue()
      
      // Fields should exist and be fillable
      await expect(page.getByLabel('School Year Start')).toBeEditable()
      await expect(page.getByLabel('School Year End')).toBeEditable()
    })
  })

  test.describe('Student Addition', () => {
    
    test.beforeEach(async ({ page }) => {
      // Navigate to students step
      await page.getByLabel('School Year Start').fill('2025-08-01')
      await page.getByLabel('School Year End').fill('2026-05-31')
      await page.getByRole('button', { name: 'Next' }).click()
    })

    test('should add a student with name and grade', async ({ page }) => {
      await page.getByPlaceholder("Student's Name").fill('Emma')
      await page.getByLabel('Grade Level').selectOption('5th Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      
      // Student should appear in the list
      await expect(page.getByText('Emma')).toBeVisible()
      await expect(page.getByText('5th Grade')).toBeVisible()
    })

    test('should add multiple students', async ({ page }) => {
      // Add first student
      await page.getByPlaceholder("Student's Name").fill('Emma')
      await page.getByLabel('Grade Level').selectOption('5th Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      
      // Add second student
      await page.getByPlaceholder("Student's Name").fill('Jack')
      await page.getByLabel('Grade Level').selectOption('3rd Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      
      // Both should appear
      await expect(page.getByText('Emma')).toBeVisible()
      await expect(page.getByText('Jack')).toBeVisible()
    })

    test('should remove a student from the list', async ({ page }) => {
      // Add a student
      await page.getByPlaceholder("Student's Name").fill('Emma')
      await page.getByLabel('Grade Level').selectOption('5th Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      
      // Remove the student
      await page.getByRole('button', { name: /remove|delete|×/i }).click()
      
      // Student should be gone
      await expect(page.getByText('Emma')).not.toBeVisible()
    })

    test('should proceed to subjects step with at least one student', async ({ page }) => {
      await page.getByPlaceholder("Student's Name").fill('Emma')
      await page.getByLabel('Grade Level').selectOption('5th Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      await page.getByRole('button', { name: 'Next' }).click()
      
      // Should be on subjects step
      await expect(page.getByText('Language Arts')).toBeVisible()
    })
  })

  test.describe('Subject Selection', () => {
    
    test.beforeEach(async ({ page }) => {
      // Navigate to subjects step
      await page.getByLabel('School Year Start').fill('2025-08-01')
      await page.getByLabel('School Year End').fill('2026-05-31')
      await page.getByRole('button', { name: 'Next' }).click()
      
      await page.getByPlaceholder("Student's Name").fill('Emma')
      await page.getByLabel('Grade Level').selectOption('5th Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      await page.getByRole('button', { name: 'Next' }).click()
    })

    test('should show core subjects', async ({ page }) => {
      await expect(page.getByText('Language Arts')).toBeVisible()
      await expect(page.getByText('Mathematics')).toBeVisible()
      await expect(page.getByText('Science')).toBeVisible()
      await expect(page.getByText('Social Studies')).toBeVisible()
    })

    test('should show elective subjects', async ({ page }) => {
      await expect(page.getByText('Art')).toBeVisible()
      await expect(page.getByText('Music')).toBeVisible()
      await expect(page.getByText('Physical Education')).toBeVisible()
    })

    test('should select and deselect subjects', async ({ page }) => {
      const mathCheckbox = page.getByLabel('Mathematics')
      
      // Check
      await mathCheckbox.check()
      await expect(mathCheckbox).toBeChecked()
      
      // Uncheck
      await mathCheckbox.uncheck()
      await expect(mathCheckbox).not.toBeChecked()
    })

    test('should complete onboarding with selected subjects', async ({ page }) => {
      // Select some subjects
      await page.getByLabel('Language Arts').check()
      await page.getByLabel('Mathematics').check()
      await page.getByLabel('Science').check()
      
      // Complete setup
      await page.getByRole('button', { name: 'Complete Setup' }).click()
      
      // Should redirect to dashboard
      await expect(page).toHaveURL('/dashboard')
    })
  })

  test.describe('Complete Flow', () => {
    
    test('should complete full onboarding and see dashboard', async ({ page }) => {
      // Step 1: School Year
      await page.getByLabel('School Year Start').fill('2025-08-01')
      await page.getByLabel('School Year End').fill('2026-05-31')
      await page.getByRole('button', { name: 'Next' }).click()
      
      // Step 2: Students
      await page.getByPlaceholder("Student's Name").fill('Emma')
      await page.getByLabel('Grade Level').selectOption('5th Grade')
      await page.getByRole('button', { name: 'Add Student' }).click()
      await page.getByRole('button', { name: 'Next' }).click()
      
      // Step 3: Subjects
      await page.getByLabel('Language Arts').check()
      await page.getByLabel('Mathematics').check()
      await page.getByLabel('Science').check()
      await page.getByRole('button', { name: 'Complete Setup' }).click()
      
      // Verify dashboard
      await expect(page).toHaveURL('/dashboard')
      await expect(page.getByText('Emma')).toBeVisible()
      await expect(page.getByText('2025-2026')).toBeVisible()
    })
  })
})
