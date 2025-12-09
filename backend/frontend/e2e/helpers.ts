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

// Helper to fill form fields
export async function fillField(page: Page, label: string, value: string) {
  await page.getByLabel(label).fill(value)
}

// Helper to click button by text
export async function clickButton(page: Page, text: string) {
  await page.getByRole('button', { name: text }).click()
}

// Check if element contains text
export async function expectText(page: Page, text: string) {
  await expect(page.getByText(text)).toBeVisible()
}

// Navigate and wait for load
export async function navigateTo(page: Page, path: string) {
  await page.goto(path)
  await waitForPageLoad(page)
}

// Login helper for tests that need authenticated state
export async function loginAs(page: Page, email: string, password: string) {
  await navigateTo(page, '/login')
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Log In' }).click()
  await page.waitForURL(/\/(dashboard|onboarding)/)
}

// Full registration flow helper
export async function registerUser(page: Page, user: ReturnType<typeof generateTestUser>) {
  await navigateTo(page, '/register')
  await page.getByLabel('Your Name').fill(user.name)
  await page.getByLabel('Email').fill(user.email)
  await page.getByLabel('Password').fill(user.password)
  await page.getByLabel('Family Name').fill(user.familyName)
  await page.getByRole('button', { name: 'Create Account' }).click()
  await page.waitForURL('/onboarding')
}

// Complete onboarding flow helper
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
    subjects = ['Language Arts', 'Mathematics', 'Science'],
    startDate = '2025-08-01',
    endDate = '2026-05-31',
  } = options || {}

  // Step 1: School Year Dates
  await page.getByLabel('School Year Start').fill(startDate)
  await page.getByLabel('School Year End').fill(endDate)
  await page.getByRole('button', { name: 'Next' }).click()

  // Step 2: Add Students
  for (const student of students) {
    await page.getByPlaceholder("Student's Name").fill(student.name)
    await page.getByLabel('Grade Level').selectOption(student.gradeLevel)
    await page.getByRole('button', { name: 'Add Student' }).click()
  }
  await page.getByRole('button', { name: 'Next' }).click()

  // Step 3: Select Subjects
  for (const subject of subjects) {
    await page.getByLabel(subject).check()
  }
  await page.getByRole('button', { name: 'Complete Setup' }).click()

  // Wait for dashboard
  await page.waitForURL('/dashboard')
}

// Logout helper
export async function logout(page: Page) {
  await page.getByRole('button', { name: 'Logout' }).click()
  await page.waitForURL('/login')
}
