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

test('renders the typed RailsHx todo page through real browser assets', async ({ page }) => {
  await gotoTodos(page)

  await expect(page).toHaveTitle(/RailsHx Todoapp/)
  await expect(page.getByText('Typed Rails, polished Ruby.')).toBeVisible()
  await expect(page.locator(`meta[name="${hooks.meta.templateName}"]`)).toHaveAttribute('content', hooks.meta.templateContent)
  await expect(page.locator(hooks.selectors.form)).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator(hooks.selectors.sessionForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator(hooks.selectors.chatForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator(hooks.selectors.scrollLinks).first()).toHaveAttribute(hooks.attrs.bound, 'true')

  const bodyText = await page.locator('body').innerText()
  expect(bodyText).toMatch(/RailsHx sample/i)
  expect(bodyText).toMatch(/Typed session layer/i)
  expect(bodyText).toMatch(/Typed Turbo room/i)
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
})

test('uses typed Haxe client behavior for same-page Rails links', async ({ page }) => {
  await gotoTodos(page)

  await page.evaluate(() => window.scrollTo(0, 0))
  await page.locator(hooks.selectors.scrollLinks).first().click()

  await expect(page.locator(hooks.selectors.openWork)).toBeFocused()
  await expect.poll(async () => page.evaluate(() => window.scrollY)).toBeGreaterThan(0)
})

test('handles importmap-backed Rails form flows (tracked in haxe.ruby-ae6.1)', async ({ page }) => {
  await gotoTodos(page)

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

  await page.getByRole('button', { name: /Template Maintainer/ }).click()

  await expect(page.getByText('Session updated')).toBeVisible()
  await expect(page.getByText(/Current user:/)).toBeVisible()
  await expect(page.locator(hooks.selectors.sessionFooter)).toContainText('Template Maintainer')
  await page.waitForLoadState('networkidle')
})

test('posts a typed RailsHx room note through Turbo-backed Haxe client hooks', async ({ page }) => {
  await gotoTodos(page)

  const beforeCount = await page.locator(hooks.selectors.chatMessages).count()
  const body = `Room note ${Date.now()}`

  await page.getByLabel('Add a typed room note').fill(body)
  await page.getByRole('button', { name: 'Post note' }).click()

  await expect(page.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
  await expect(page.getByText('Room note posted')).toBeVisible()
  await expect.poll(async () => page.locator(hooks.selectors.chatMessages).count()).toBeGreaterThanOrEqual(beforeCount)
})

test('broadcasts typed ActionCable room notes to another browser session', async ({ browser }) => {
  const sender = await browser.newPage()
  const receiver = await browser.newPage()
  try {
    await gotoTodos(sender)
    await gotoTodos(receiver)
    await expect(receiver.locator(hooks.selectors.chatPanel)).toHaveAttribute(hooks.attrs.chatCableReady, 'true')

    const body = `Cable note ${Date.now()}`
    await sender.getByLabel('Add a typed room note').fill(body)
    await sender.getByRole('button', { name: 'Post note' }).click()

    await expect(sender.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
    await expect(receiver.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
  } finally {
    await sender.close()
    await receiver.close()
  }
})
