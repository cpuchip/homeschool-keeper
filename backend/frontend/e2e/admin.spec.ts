import { test, expect, Page } from '@playwright/test'
import { navigateTo, waitForPageLoad, completeOnboarding } from './helpers'

/**
 * Admin Portal E2E Tests
 * 
 * Uses admin@hmslogs.com which is configured as a super admin
 */

const ADMIN_USER = {
  email: 'admin@hmslogs.com',
  password: 'AdminPassword123!',
  name: 'Test Admin',
  familyName: 'Admin Test Family',
}

// Helper to register the admin user (only needs to happen once)
async function registerAdminUser(page: Page) {
  await navigateTo(page, '/register')
  await page.locator('#name').fill(ADMIN_USER.name)
  await page.locator('#email').fill(ADMIN_USER.email)
  await page.locator('#password').fill(ADMIN_USER.password)
  await page.locator('#confirmPassword').fill(ADMIN_USER.password)
  await page.locator('#familyName').fill(ADMIN_USER.familyName)
  await page.getByRole('button', { name: 'Create account' }).click()
  await page.waitForURL('/onboarding')
}

// Helper to login as admin
async function loginAsAdmin(page: Page) {
  await navigateTo(page, '/login')
  await page.locator('#email').fill(ADMIN_USER.email)
  await page.locator('#password').fill(ADMIN_USER.password)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.waitForURL(/\/(onboarding|$)/, { timeout: 10000 })
}

// Helper to ensure admin is registered and logged in
async function ensureAdminLoggedIn(page: Page) {
  // Try to login first
  await navigateTo(page, '/login')
  await page.locator('#email').fill(ADMIN_USER.email)
  await page.locator('#password').fill(ADMIN_USER.password)
  await page.getByRole('button', { name: 'Sign in' }).click()
  
  // Wait a bit for response
  await page.waitForTimeout(2000)
  
  // Check if login failed (still on login page with error)
  const currentUrl = page.url()
  if (currentUrl.includes('/login')) {
    // User doesn't exist, need to register
    await registerAdminUser(page)
    await completeOnboarding(page)
  } else if (currentUrl.includes('/onboarding')) {
    // User exists but hasn't completed onboarding
    await completeOnboarding(page)
  }
  
  // Should now be on dashboard
  await waitForPageLoad(page)
}

test.describe('Admin Portal', () => {
  
  test.beforeEach(async ({ page }) => {
    await ensureAdminLoggedIn(page)
  })

  test('should navigate to admin dashboard', async ({ page }) => {
    await navigateTo(page, '/admin')
    await waitForPageLoad(page)
    
    // Should redirect to /admin/dashboard
    await expect(page).toHaveURL(/\/admin\/dashboard/)
    
    // Should see the admin header
    await expect(page.getByText('Super Admin Portal')).toBeVisible()
  })

  test('should display dashboard stats', async ({ page }) => {
    await navigateTo(page, '/admin/dashboard')
    await waitForPageLoad(page)
    
    // Wait for stats to load
    await page.waitForTimeout(2000)
    
    // Should see stats cards
    await expect(page.getByText('Total Families')).toBeVisible()
    await expect(page.getByText('Organizations')).toBeVisible()
    await expect(page.getByText('Total Students')).toBeVisible()
    await expect(page.getByText('Log Entries')).toBeVisible()
  })

  test('should navigate between admin tabs', async ({ page }) => {
    await navigateTo(page, '/admin/dashboard')
    await waitForPageLoad(page)
    
    // Click on Families tab
    await page.getByRole('button', { name: /Families/ }).click()
    await expect(page).toHaveURL(/\/admin\/families/)
    
    // Click on Organizations tab
    await page.getByRole('button', { name: /Organizations/ }).click()
    await expect(page).toHaveURL(/\/admin\/orgs/)
    
    // Click on Storage tab
    await page.getByRole('button', { name: /Storage/ }).click()
    await expect(page).toHaveURL(/\/admin\/storage/)
    
    // Click on Telemetry tab
    await page.getByRole('button', { name: /Telemetry/ }).click()
    await expect(page).toHaveURL(/\/admin\/telemetry/)
    
    // Click back to Dashboard
    await page.getByRole('button', { name: /Dashboard/ }).click()
    await expect(page).toHaveURL(/\/admin\/dashboard/)
  })

  test('should have working Back to App link', async ({ page }) => {
    await navigateTo(page, '/admin/dashboard')
    await waitForPageLoad(page)
    
    // Click "Back to App" link
    await page.getByRole('link', { name: /Back to App/ }).click()
    
    // Should navigate to root (not /dashboard)
    await page.waitForURL('/')
    await expect(page).toHaveURL('/')
  })

  test('should show families list', async ({ page }) => {
    await navigateTo(page, '/admin/families')
    await waitForPageLoad(page)
    
    // Should see the families page content
    await expect(page.getByText('All Families')).toBeVisible()
  })

  test('should show organizations list', async ({ page }) => {
    await navigateTo(page, '/admin/orgs')
    await waitForPageLoad(page)
    
    // Should see the orgs page content
    await expect(page.getByText('Organizations')).toBeVisible()
  })

  test('should show R2 storage page', async ({ page }) => {
    await navigateTo(page, '/admin/storage')
    await waitForPageLoad(page)
    
    // Should see storage-related content
    await expect(page.getByText(/Storage|R2/)).toBeVisible()
  })

  test('should show telemetry page', async ({ page }) => {
    await navigateTo(page, '/admin/telemetry')
    await waitForPageLoad(page)
    
    // Should see telemetry content
    await expect(page.getByText(/Telemetry|Analytics/)).toBeVisible()
  })
})

test.describe('Admin Access Control', () => {
  
  test('should deny access to non-admin users', async ({ page }) => {
    // Register a regular user
    const timestamp = Date.now()
    await navigateTo(page, '/register')
    await page.locator('#name').fill('Regular User')
    await page.locator('#email').fill(`regular-${timestamp}@example.com`)
    await page.locator('#password').fill('TestPassword123!')
    await page.locator('#confirmPassword').fill('TestPassword123!')
    await page.locator('#familyName').fill('Regular Family')
    await page.getByRole('button', { name: 'Create account' }).click()
    await page.waitForURL('/onboarding')
    
    // Complete onboarding
    await completeOnboarding(page)
    
    // Try to access admin page
    await navigateTo(page, '/admin')
    await waitForPageLoad(page)
    
    // Should see access denied message
    await expect(page.getByText('Access Denied')).toBeVisible()
    await expect(page.getByText("don't have permission")).toBeVisible()
  })

  test('should have return to dashboard link on access denied page', async ({ page }) => {
    // Register a regular user
    const timestamp = Date.now()
    await navigateTo(page, '/register')
    await page.locator('#name').fill('Regular User 2')
    await page.locator('#email').fill(`regular2-${timestamp}@example.com`)
    await page.locator('#password').fill('TestPassword123!')
    await page.locator('#confirmPassword').fill('TestPassword123!')
    await page.locator('#familyName').fill('Regular Family 2')
    await page.getByRole('button', { name: 'Create account' }).click()
    await page.waitForURL('/onboarding')
    await completeOnboarding(page)
    
    // Try to access admin page
    await navigateTo(page, '/admin')
    await waitForPageLoad(page)
    
    // Click return to dashboard link
    await page.getByRole('link', { name: /Return to Dashboard/ }).click()
    
    // Should navigate to root
    await expect(page).toHaveURL('/')
  })
})
