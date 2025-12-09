import { test, expect } from '@playwright/test'
import { generateTestUser, navigateTo, registerUser, completeOnboarding, loginAs, logout } from './helpers'

/**
 * Authentication E2E Tests
 * Tests the complete auth flow: registration, login, logout, session persistence
 */

test.describe('Authentication', () => {
  
  test.describe('Registration', () => {
    
    test('should show registration form with all required fields', async ({ page }) => {
      await navigateTo(page, '/register')
      
      await expect(page.getByLabel('Your Name')).toBeVisible()
      await expect(page.getByLabel('Email')).toBeVisible()
      await expect(page.getByLabel('Password')).toBeVisible()
      await expect(page.getByLabel('Family Name')).toBeVisible()
      await expect(page.getByRole('button', { name: 'Create Account' })).toBeVisible()
    })

    test('should show validation errors for empty fields', async ({ page }) => {
      await navigateTo(page, '/register')
      
      await page.getByRole('button', { name: 'Create Account' }).click()
      
      // Form validation should prevent submission
      await expect(page).toHaveURL('/register')
    })

    test('should register new user and redirect to onboarding', async ({ page }) => {
      const user = generateTestUser()
      
      await registerUser(page, user)
      
      await expect(page).toHaveURL('/onboarding')
      await expect(page.getByText('Welcome')).toBeVisible()
    })

    test('should show error for duplicate email', async ({ page }) => {
      const user = generateTestUser()
      
      // Register first time
      await registerUser(page, user)
      await logout(page)
      
      // Try to register again with same email
      await navigateTo(page, '/register')
      await page.getByLabel('Your Name').fill(user.name)
      await page.getByLabel('Email').fill(user.email)
      await page.getByLabel('Password').fill(user.password)
      await page.getByLabel('Family Name').fill(user.familyName)
      await page.getByRole('button', { name: 'Create Account' }).click()
      
      // Should show error
      await expect(page.getByText(/already exists|already registered/i)).toBeVisible()
    })
  })

  test.describe('Login', () => {
    
    test('should show login form with email and password fields', async ({ page }) => {
      await navigateTo(page, '/login')
      
      await expect(page.getByLabel('Email')).toBeVisible()
      await expect(page.getByLabel('Password')).toBeVisible()
      await expect(page.getByRole('button', { name: 'Log In' })).toBeVisible()
    })

    test('should show error for invalid credentials', async ({ page }) => {
      await navigateTo(page, '/login')
      
      await page.getByLabel('Email').fill('nonexistent@example.com')
      await page.getByLabel('Password').fill('wrongpassword')
      await page.getByRole('button', { name: 'Log In' }).click()
      
      await expect(page.getByText(/invalid|incorrect|not found/i)).toBeVisible()
    })

    test('should login existing user and redirect to dashboard', async ({ page }) => {
      const user = generateTestUser()
      
      // Register and complete onboarding first
      await registerUser(page, user)
      await completeOnboarding(page)
      await logout(page)
      
      // Now login
      await loginAs(page, user.email, user.password)
      
      await expect(page).toHaveURL('/dashboard')
    })

    test('should redirect unonboarded user to onboarding', async ({ page }) => {
      const user = generateTestUser()
      
      // Register but don't complete onboarding
      await registerUser(page, user)
      await logout(page)
      
      // Login again
      await loginAs(page, user.email, user.password)
      
      await expect(page).toHaveURL('/onboarding')
    })
  })

  test.describe('Session', () => {
    
    test('should persist session on page reload', async ({ page }) => {
      const user = generateTestUser()
      
      await registerUser(page, user)
      await completeOnboarding(page)
      
      // Reload page
      await page.reload()
      
      // Should still be on dashboard
      await expect(page).toHaveURL('/dashboard')
    })

    test('should logout and redirect to login', async ({ page }) => {
      const user = generateTestUser()
      
      await registerUser(page, user)
      await completeOnboarding(page)
      await logout(page)
      
      await expect(page).toHaveURL('/login')
    })

    test('should not allow access to dashboard when logged out', async ({ page }) => {
      await navigateTo(page, '/dashboard')
      
      // Should redirect to login
      await expect(page).toHaveURL('/login')
    })
  })

  test.describe('Link Navigation', () => {
    
    test('should navigate from login to register', async ({ page }) => {
      await navigateTo(page, '/login')
      
      await page.getByRole('link', { name: /register|sign up|create account/i }).click()
      
      await expect(page).toHaveURL('/register')
    })

    test('should navigate from register to login', async ({ page }) => {
      await navigateTo(page, '/register')
      
      await page.getByRole('link', { name: /login|sign in/i }).click()
      
      await expect(page).toHaveURL('/login')
    })
  })
})
