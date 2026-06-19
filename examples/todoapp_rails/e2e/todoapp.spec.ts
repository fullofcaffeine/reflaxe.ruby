import { expect, test, type Page } from '@playwright/test'
import { hooks } from './todo_hooks'

async function gotoTodos(page: Page) {
  let lastError: unknown = null
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      await page.goto('/todos', { waitUntil: 'domcontentloaded', timeout: 15_000 })
      await expect(page.locator(hooks.selectors.shell)).toBeVisible()
      return
    } catch (error) {
      lastError = error
      await page.waitForTimeout(400)
    }
  }
  throw lastError
}

async function continueAsGuest(page: Page) {
  const guestButton = page.getByRole('button', { name: 'Continue as guest' })
  if (await guestButton.isVisible().catch(() => false)) {
    await guestButton.click()
    await expect(page).toHaveURL(/\/todos$/)
  }
  await expect(page.locator(hooks.selectors.sessionFooter)).toContainText(/signed in/i)
}

async function gotoAuthenticatedTodos(page: Page) {
  await gotoTodos(page)
  await continueAsGuest(page)
}

test('renders the typed RailsHx todo page through real browser assets', async ({ page }) => {
  await gotoTodos(page)

  await expect(page).toHaveTitle(/RailsHx Todoapp/)
  await expect(page.getByText('Typed Rails, polished Ruby.')).toBeVisible()
  await expect(page.locator(`meta[name="${hooks.meta.templateName}"]`)).toHaveAttribute('content', hooks.meta.templateContent)
  await expect(page.locator(hooks.selectors.sessionForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator(hooks.selectors.scrollLinks).first()).toHaveAttribute(hooks.attrs.bound, 'true')

  const bodyText = await page.locator('body').innerText()
  expect(bodyText).toMatch(/RailsHx sample/i)
  expect(bodyText).toMatch(/DeviseHx auth layer/i)
  expect(bodyText).toMatch(/Continue as guest/i)
  expect(bodyText).toMatch(/Typed Turbo room/i)
  expect(bodyText).toMatch(/Turbo Frame ready/i)
  expect(bodyText).toContain('Ship typed Rails templates')
  expect(bodyText).toContain('Routes, params, and HHX are all typed for this room.')
  expect(bodyText).not.toMatch(/<%=?|%>|<\/?(div|span|form|input|textarea|section|article)(\s|>)/i)

  await expect(page.getByText(/Back to todos/i)).toHaveCount(0)

  const links = page.locator('a')
  const linkCount = await links.count()
  for (let index = 0; index < linkCount; index += 1) {
    const link = links.nth(index)
    await expect(link).toBeVisible()
    const href = await link.getAttribute('href')
    expect(href).toBeTruthy()
    expect(href).not.toMatch(/undefined|null|javascript:/i)
  }

  const items = page.locator(hooks.selectors.items)
  const dots = page.locator(hooks.selectors.dots)
  const dotCount = await dots.count()
  expect(dotCount).toBeGreaterThan(0)
  await expect(dots).toHaveCount(await items.count())

  for (let index = 0; index < dotCount; index += 1) {
    const dotBox = await dots.nth(index).boundingBox()
    const itemBox = await items.nth(index).boundingBox()
    expect(dotBox).not.toBeNull()
    expect(itemBox).not.toBeNull()
    expect(dotBox!.width).toBeGreaterThanOrEqual(13)
    expect(dotBox!.height).toBeGreaterThanOrEqual(13)
    expect(dotBox!.x).toBeGreaterThanOrEqual(itemBox!.x)
    expect(dotBox!.y).toBeGreaterThanOrEqual(itemBox!.y)
    expect(dotBox!.x + dotBox!.width).toBeLessThanOrEqual(itemBox!.x + itemBox!.width)
    expect(dotBox!.y + dotBox!.height).toBeLessThanOrEqual(itemBox!.y + itemBox!.height)
  }

  await continueAsGuest(page)
  await expect(page.locator(hooks.selectors.form)).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator(hooks.selectors.chatForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
})

test('loads typed user management through a standard Turbo Frame', async ({ page }) => {
  await gotoAuthenticatedTodos(page)

  const frame = page.locator(hooks.selectors.userFrame)
  await expect(frame).toContainText('Turbo Frame ready.')

  await page.getByRole('link', { name: 'Manage users' }).click()

  await expect(frame).toContainText('RailsHx user management', { timeout: 20_000 })
  await expect(frame).toContainText('Typed users, ordinary Rails output.')
  await expect(frame.locator('.user-management-card')).toHaveCount(4)
  await expect(page).toHaveURL(/\/todos$/)
})

test('renders the users route directly as a Rails fallback with the same frame contract', async ({ page }) => {
  await gotoAuthenticatedTodos(page)
  await page.goto('/users', { waitUntil: 'domcontentloaded', timeout: 15_000 })

  const frame = page.locator(hooks.selectors.userFrame)
  await expect(frame).toBeVisible()
  await expect(frame).toContainText('RailsHx user management')
  await expect(page.getByRole('link', { name: 'Back to todo board' })).toBeVisible()
})

test('uses typed Haxe client behavior for same-page Rails links', async ({ page }) => {
  await gotoAuthenticatedTodos(page)

  await page.evaluate(() => window.scrollTo(0, 0))
  await page.locator(hooks.selectors.scrollLinks).first().click()

  await expect(page.locator(hooks.selectors.openWork)).toBeFocused()
  await expect.poll(async () => page.evaluate(() => window.scrollY)).toBeGreaterThan(0)
})

test('handles importmap-backed Rails form flows (tracked in haxe.ruby-ae6.1)', async ({ page }) => {
  await gotoAuthenticatedTodos(page)

  const beforeCount = await page.locator(hooks.selectors.listItems).count()
  const title = `Playwright task ${Date.now()}`
  const notes = 'Created through the RailsHx browser sentinel.'

  await page.getByLabel('What should ship next?').fill(title)
  await page.getByLabel('Why does it matter?').fill(notes)
  await page.getByRole('button', { name: 'Add task' }).click()

  await expect(page.locator(hooks.selectors.items).filter({ hasText: title }).first()).toBeVisible({ timeout: 20_000 })
  await expect(page.locator(hooks.selectors.items).filter({ hasText: notes }).first()).toBeVisible()
  await expect.poll(async () => page.locator(hooks.selectors.listItems).count()).toBeGreaterThanOrEqual(beforeCount)
  await page.waitForLoadState('networkidle')

  await expect(page.getByText('Task added')).toBeVisible()
  await expect(page.locator(hooks.selectors.sessionFooter)).toContainText(/signed in/i)
  await page.waitForLoadState('networkidle')
})

test('posts a typed RailsHx room note through Turbo-backed Haxe client hooks', async ({ page }) => {
  await gotoAuthenticatedTodos(page)
  await expect(page.locator(hooks.selectors.chatForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator('turbo-cable-stream-source[connected]')).toBeVisible()

  const beforeCount = await page.locator(hooks.selectors.chatMessages).count()
  const body = `Room note ${Date.now()}`
  const composer = page.getByLabel('Add a typed room note')

  await composer.fill(body)
  await page.getByRole('button', { name: 'Post note' }).click()

  await expect(page.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
  await expect(page.getByText('Room note posted')).toBeVisible()
  await expect(composer).toHaveValue('')
  await expect.poll(async () => page.locator(hooks.selectors.chatMessages).count()).toBeGreaterThanOrEqual(beforeCount)
})

test('broadcasts typed Turbo Stream room notes to another browser session', async ({ browser }) => {
  const sender = await browser.newPage()
  const receiver = await browser.newPage()
  try {
    await gotoTodos(sender)
    await continueAsGuest(sender)
    await gotoAuthenticatedTodos(receiver)
    await expect(sender.locator('turbo-cable-stream-source[connected]')).toHaveCount(1)
    await expect(receiver.locator('turbo-cable-stream-source[connected]')).toHaveCount(1)
    await expect(sender.locator('turbo-cable-stream-source[connected]')).toBeVisible()
    await expect(receiver.locator('turbo-cable-stream-source[connected]')).toBeVisible()

    const body = `Stream note ${Date.now()}`
    await sender.getByLabel('Add a typed room note').fill(body)
    await sender.getByRole('button', { name: 'Post note' }).click()

    await expect(sender.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
    await expect(receiver.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
  } finally {
    await sender.close()
    await receiver.close()
  }
})

test('renders missed room notes from Rails state on reload', async ({ page }) => {
  await gotoAuthenticatedTodos(page)

  const body = `Late stream note ${Date.now()}`
  await page.context().request.post('/chat_messages', {
    form: {
      'chat_message[user_id]': '1',
      'chat_message[body]': body
    }
  })

  await page.reload()
  await expect(page.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
})
