import { expect, test } from '@playwright/test'

test('renders the typed RailsHx todo page through real browser assets', async ({ page }) => {
  await page.goto('/todos')

  await expect(page).toHaveTitle(/RailsHx Todoapp/)
  await expect(page.getByText('Typed Rails, polished Ruby.')).toBeVisible()
  await expect(page.locator('meta[name="railshx-template"]')).toHaveAttribute('content', 'todo-index')
  await expect(page.locator('.todo-form')).toHaveAttribute('data-railshx-bound', 'true')
  await expect(page.locator('[data-railshx-scroll]').first()).toHaveAttribute('data-railshx-bound', 'true')

  const bodyText = await page.locator('body').innerText()
  expect(bodyText).toMatch(/RailsHx sample/i)
  expect(bodyText).toContain('Ship typed Rails templates')
  expect(bodyText).not.toMatch(/<%=?|%>|<\/?(div|span|form|input|textarea|section|article)(\s|>)/i)
})

test('creates a task through Turbo/importmap-backed Rails form flow', async ({ page }) => {
  await page.goto('/todos')

  const beforeCount = await page.locator('.todo-list .todo-item').count()
  const title = `Playwright task ${Date.now()}`
  const notes = 'Created through the RailsHx browser sentinel.'

  await page.getByLabel('What should ship next?').fill(title)
  await page.getByLabel('Why does it matter?').fill(notes)
  await page.getByRole('button', { name: 'Add task' }).click()

  await expect(page.getByText('Task added to open work')).toBeVisible()
  await expect(page.locator('.todo-item').filter({ hasText: title }).first()).toBeVisible()
  await expect(page.locator('.todo-item').filter({ hasText: notes }).first()).toBeVisible()
  await expect.poll(async () => page.locator('.todo-list .todo-item').count()).toBeGreaterThanOrEqual(beforeCount + 1)
})

test('uses typed Haxe client behavior for same-page Rails links', async ({ page }) => {
  await page.goto('/todos')

  await page.evaluate(() => window.scrollTo(0, 0))
  await page.locator('[data-railshx-scroll]').first().click()

  await expect(page.locator('#open-work')).toBeFocused()
  await expect.poll(async () => page.evaluate(() => window.scrollY)).toBeGreaterThan(0)
})
