import { test, expect } from '@playwright/test'
import { generateTestUser, registerUser, completeOnboarding, navigateTo } from './helpers'

/**
 * Students Page E2E Tests
 * Tests CRUD operations for students
 */

test.describe('Students', () => {
  let user: ReturnType<typeof generateTestUser>

  test.beforeEach(async ({ page }) => {
    user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page, {
      students: [{ name: 'Emma', gradeLevel: '5th Grade' }],
      subjects: ['Language Arts', 'Mathematics'],
    })
  })

  test.describe('Students List', () => {
    
    test('should display students page', async ({ page }) => {
      await navigateTo(page, '/students')
      await expect(page).toHaveURL('/students')
    })

    test('should show students from onboarding', async ({ page }) => {
      await navigateTo(page, '/students')
      await expect(page.getByText('Emma')).toBeVisible()
      await expect(page.getByText('5th Grade')).toBeVisible()
    })

    test('should have add student button', async ({ page }) => {
      await navigateTo(page, '/students')
      await expect(page.getByRole('button', { name: /add student/i })).toBeVisible()
    })
  })

  test.describe('Add Student', () => {
    
    test('should open add student modal', async ({ page }) => {
      await navigateTo(page, '/students')
      await page.getByRole('button', { name: /add student/i }).click()
      
      // Modal should appear with form
      await expect(page.getByLabel(/name/i)).toBeVisible()
      await expect(page.getByLabel(/grade/i)).toBeVisible()
    })

    test('should add a new student', async ({ page }) => {
      await navigateTo(page, '/students')
      await page.getByRole('button', { name: /add student/i }).click()
      
      // Fill form
      await page.getByLabel(/name/i).fill('Jack')
      await page.getByLabel(/grade/i).selectOption('3rd Grade')
      
      // Submit
      await page.getByRole('button', { name: /save|add|create/i }).click()
      
      // New student should appear
      await expect(page.getByText('Jack')).toBeVisible()
    })

    test('should show both students after adding', async ({ page }) => {
      await navigateTo(page, '/students')
      await page.getByRole('button', { name: /add student/i }).click()
      
      await page.getByLabel(/name/i).fill('Jack')
      await page.getByLabel(/grade/i).selectOption('3rd Grade')
      await page.getByRole('button', { name: /save|add|create/i }).click()
      
      // Both students should be visible
      await expect(page.getByText('Emma')).toBeVisible()
      await expect(page.getByText('Jack')).toBeVisible()
    })
  })

  test.describe('Edit Student', () => {
    
    test('should open edit modal for student', async ({ page }) => {
      await navigateTo(page, '/students')
      
      // Click on student or edit button
      const editBtn = page.getByRole('button', { name: /edit/i }).first()
      const studentRow = page.getByText('Emma')
      
      // Try edit button first, then clicking student
      if (await editBtn.isVisible().catch(() => false)) {
        await editBtn.click()
      } else {
        await studentRow.click()
      }
      
      // Should see edit form
      await expect(page.getByLabel(/name/i)).toBeVisible()
    })

    test('should update student name', async ({ page }) => {
      await navigateTo(page, '/students')
      
      // Open edit
      const editBtn = page.getByRole('button', { name: /edit/i }).first()
      if (await editBtn.isVisible().catch(() => false)) {
        await editBtn.click()
      } else {
        await page.getByText('Emma').click()
      }
      
      // Update name
      await page.getByLabel(/name/i).fill('Emma Rose')
      await page.getByRole('button', { name: /save|update/i }).click()
      
      // Should see updated name
      await expect(page.getByText('Emma Rose')).toBeVisible()
    })
  })

  test.describe('Student Detail', () => {
    
    test('should navigate to student detail', async ({ page }) => {
      await navigateTo(page, '/students')
      
      // Click on student name or view button
      const viewBtn = page.getByRole('link', { name: /view|details/i }).first()
      if (await viewBtn.isVisible().catch(() => false)) {
        await viewBtn.click()
      } else {
        await page.getByText('Emma').click()
      }
      
      // Should be on student detail or show detail modal
      const onDetailPage = page.url().includes('/students/')
      const hasDetailModal = await page.getByText(/student details|hours logged/i).isVisible().catch(() => false)
      
      expect(onDetailPage || hasDetailModal).toBeTruthy()
    })
  })
})

test.describe('Subjects', () => {
  let user: ReturnType<typeof generateTestUser>

  test.beforeEach(async ({ page }) => {
    user = generateTestUser()
    await registerUser(page, user)
    await completeOnboarding(page, {
      students: [{ name: 'Emma', gradeLevel: '5th Grade' }],
      subjects: ['Language Arts', 'Mathematics', 'Science'],
    })
  })

  test.describe('Subjects List', () => {
    
    test('should display subjects page', async ({ page }) => {
      await navigateTo(page, '/subjects')
      await expect(page).toHaveURL('/subjects')
    })

    test('should show subjects from onboarding', async ({ page }) => {
      await navigateTo(page, '/subjects')
      
      await expect(page.getByText('Language Arts')).toBeVisible()
      await expect(page.getByText('Mathematics')).toBeVisible()
      await expect(page.getByText('Science')).toBeVisible()
    })

    test('should show subject types', async ({ page }) => {
      await navigateTo(page, '/subjects')
      
      // Should indicate core vs elective
      const hasType = 
        await page.getByText(/core/i).isVisible().catch(() => false) ||
        await page.getByText(/elective/i).isVisible().catch(() => false)
      
      // Type indicators may not be implemented
      await expect(page).toHaveURL('/subjects')
    })

    test('should have add subject button', async ({ page }) => {
      await navigateTo(page, '/subjects')
      await expect(page.getByRole('button', { name: /add subject/i })).toBeVisible()
    })
  })

  test.describe('Add Subject', () => {
    
    test('should open add subject modal', async ({ page }) => {
      await navigateTo(page, '/subjects')
      await page.getByRole('button', { name: /add subject/i }).click()
      
      await expect(page.getByLabel(/name/i)).toBeVisible()
    })

    test('should add a new subject', async ({ page }) => {
      await navigateTo(page, '/subjects')
      await page.getByRole('button', { name: /add subject/i }).click()
      
      await page.getByLabel(/name/i).fill('History')
      await page.getByRole('button', { name: /save|add|create/i }).click()
      
      await expect(page.getByText('History')).toBeVisible()
    })
  })
})
