import { test, expect, Page } from '@playwright/test'

/**
 * Test helpers and utilities for Home School Logs E2E tests
 */

// Generate unique test user for each test run
export function generateTestUser() {
  const timestamp = Date.now()
  const random = Math.random().toString(36).substring(7)
  return {
    email: `test-${timestamp}-${random}@example.com`,
    password: 'TestPassword123!',
    name: `Test User ${timestamp}`,
    familyName: `Test Family ${timestamp}`,
  }
}

// Wait for loading states to complete
export async function waitForPageLoad(page: Page) {
  await page.waitForLoadState('networkidle')
}

// Navigate and wait for load
export async function navigateTo(page: Page, path: string) {
  await page.goto(path)
  await waitForPageLoad(page)
}

// Login helper for tests that need authenticated state
export async function loginAs(page: Page, email: string, password: string) {
  await navigateTo(page, '/login')
  await page.locator('#email').fill(email)
  await page.locator('#password').fill(password)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.waitForURL(/\/(dashboard|onboarding|$)/)
}

// Full registration flow helper
export async function registerUser(page: Page, user: ReturnType<typeof generateTestUser>) {
  await navigateTo(page, '/register')
  await page.locator('#name').fill(user.name)
  await page.locator('#email').fill(user.email)
  await page.locator('#password').fill(user.password)
  await page.locator('#confirmPassword').fill(user.password)
  await page.locator('#familyName').fill(user.familyName)
  await page.getByRole('button', { name: 'Create account' }).click()
  await page.waitForURL('/onboarding')
}

// Complete onboarding flow helper (4 steps)
export async function completeOnboarding(
  page: Page,
  options?: {
    students?: { name: string; gradeLevel: string }[]
    subjects?: string[]
    startDate?: string
    endDate?: string
  }
) {
  const {
    students = [{ name: 'Emma Test', gradeLevel: '5th Grade' }],
    startDate = '2025-08-01',
    endDate = '2026-05-31',
  } = options || {}

  // Step 1: Location (state, timezone) - just click Continue
  await page.getByRole('button', { name: 'Continue' }).click()

  // Step 2: School Year Dates
  await page.locator('#yearStart').fill(startDate)
  await page.locator('#yearEnd').fill(endDate)
  await page.getByRole('button', { name: 'Continue' }).click()

  // Step 3: Subjects - already pre-selected, just continue
  await page.getByRole('button', { name: 'Continue' }).click()

  // Step 4: Add Students
  const studentNameInput = page.locator('input[placeholder="Student name"]').first()
  await studentNameInput.fill(students[0].name)
  // Select grade from the select next to the student name
  await page.locator('.flex.gap-3 select').first().selectOption(students[0].gradeLevel)
  
  // Add additional students if needed
  for (let i = 1; i < students.length; i++) {
    await page.getByText('+ Add another student').click()
    await page.locator('input[placeholder="Student name"]').nth(i).fill(students[i].name)
    await page.locator('.flex.gap-3 select').nth(i).selectOption(students[i].gradeLevel)
  }
  
  await page.getByRole('button', { name: 'Complete Setup' }).click()

  // Wait for redirect - could be / or /dashboard
  await page.waitForTimeout(2000) // Allow redirect to happen
}

// Logout helper
export async function logout(page: Page) {
  // Look for logout button in various places
  const logoutBtn = page.getByRole('button', { name: /logout|sign out/i })
  if (await logoutBtn.isVisible().catch(() => false)) {
    await logoutBtn.click()
    await page.waitForURL('/login')
  } else {
    // Navigate directly to login
    await navigateTo(page, '/login')
  }
}
