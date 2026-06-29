import { expect, test, type Locator, type Page } from '@playwright/test'
import { hooks } from './todo_hooks'

async function expectPolishedButton(control: Locator) {
  await expect(control).toBeVisible()
  const styles = await control.evaluate(element => {
    const html = element as HTMLElement
    const computed = window.getComputedStyle(html)
    const box = html.getBoundingClientRect()
    return {
      backgroundColor: computed.backgroundColor,
      backgroundImage: computed.backgroundImage,
      borderRadius: Number.parseFloat(computed.borderRadius),
      boxShadow: computed.boxShadow,
      cursor: computed.cursor,
      fontWeight: computed.fontWeight,
      height: box.height,
      textTransform: computed.textTransform
    }
  })

  expect(styles.height).toBeGreaterThan(30)
  expect(styles.borderRadius).toBeGreaterThan(8)
  expect(styles.cursor).toBe('pointer')
  expect(styles.textTransform).toBe('uppercase')
  expect(Number.parseInt(styles.fontWeight, 10)).toBeGreaterThanOrEqual(700)
  expect(styles.backgroundImage !== 'none' || styles.backgroundColor !== 'rgba(0, 0, 0, 0)').toBeTruthy()
}

async function expectServerFlashToast(page: Page, text: string | RegExp) {
  const flash = page.locator('.app-flash')
  await expect(flash).toContainText(text)
  const metrics = await flash.evaluate(element => {
    const html = element as HTMLElement
    const computed = window.getComputedStyle(html)
    const box = html.getBoundingClientRect()
    return {
      position: computed.position,
      top: box.top,
      width: box.width,
      height: box.height
    }
  })

  expect(metrics.position).toBe('fixed')
  expect(metrics.top).toBeGreaterThanOrEqual(0)
  expect(metrics.width).toBeGreaterThan(260)
  expect(metrics.height).toBeGreaterThan(40)
  await expect(flash).toBeHidden({ timeout: 7_000 })
}

async function gotoLogin(page: Page) {
  await page.goto('/todos', { waitUntil: 'domcontentloaded', timeout: 15_000 })
  await expect(page).toHaveURL(/\/users\/sign_in$/)
  await expect(page.locator('.login-shell')).toBeVisible()
  await expect(page.locator('.app-flash')).toHaveCount(0)
}

async function continueAsGuest(page: Page) {
  const guestButton = page.getByRole('button', { name: 'Continue as guest' })
  await expect(guestButton).toBeVisible()
  await guestButton.click()
  await expect(page).toHaveURL(/\/todos$/)
  await expect(page.locator(hooks.selectors.shell)).toBeVisible()
  await expect(page.locator('.session-chip').getByText('Guest Workspace', { exact: true })).toBeVisible()
  await expect(page.locator('.brand-mark').getByText('Devise session active')).toBeVisible()
  await expect(page.getByRole('link', { name: 'Users' })).toHaveCount(0)
}

async function loginAsOwner(page: Page) {
  await gotoLogin(page)
  await page.getByLabel('Email').fill('owner@example.test')
  await page.getByLabel('Password').fill('password123')
  await page.getByRole('button', { name: 'Log in' }).click()
  await expect(page).toHaveURL(/\/todos$/)
  await expect(page.locator(hooks.selectors.shell)).toBeVisible()
  await expect(page.locator('.session-chip').getByText('owner@example.test')).toBeVisible()
}

async function gotoAuthenticatedTodos(page: Page) {
  await gotoLogin(page)
  await continueAsGuest(page)
}

test('renders the designed DeviseHx login page before the protected board', async ({ page }) => {
  await gotoLogin(page)

  await expect(page).toHaveTitle(/RailsHx Todoapp/)
  await expect(page.getByText('Sign in to the typed Rails board.')).toBeVisible()
  await expect(page.getByText('Devise owns Warden')).toBeVisible()
  await expect(page.getByText('Seeded demo')).toBeVisible()
  await expect(page.getByText('owner@example.test')).toBeVisible()
  await expect(page.getByText('password123')).toBeVisible()
  await expect(page.locator(hooks.selectors.sessionForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.getByRole('button', { name: 'Continue as guest' })).toBeVisible()
  await expect(page.locator('.app-flash')).toHaveCount(0)
  await expect(page.locator('.login-flash')).toBeVisible()
  await expect(page.locator('.login-flash')).toContainText(/sign in/i)

  await page.goto('/users/sign_in', { waitUntil: 'domcontentloaded', timeout: 15_000 })
  await expect(page.locator('.login-flash')).toHaveCount(0)
  await page.getByLabel('Email').fill('owner@example.test')
  await page.getByLabel('Password').fill('wrong-password')
  const failedLogin = page.waitForResponse(response =>
    response.url().includes('/users/sign_in') && response.request().method() === 'POST'
  )
  await page.getByRole('button', { name: 'Log in' }).click()
  await failedLogin
  await expect(page.locator('.login-flash')).toBeVisible()
  await expect(page.locator('.login-flash')).toContainText(/invalid/i)
  await expect(page.locator('.app-flash')).toHaveCount(0)

  await loginAsOwner(page)
})

test('keeps DeviseHx session controls styled and functional', async ({ page }) => {
  await gotoLogin(page)
  await expectPolishedButton(page.getByRole('button', { name: 'Log in' }))
  await expectPolishedButton(page.getByRole('button', { name: 'Continue as guest' }))

  await page.getByLabel('Email').fill('owner@example.test')
  await page.getByLabel('Password').fill('password123')
  await page.getByRole('button', { name: 'Log in' }).click()

  await expect(page).toHaveURL(/\/todos$/)
  await expectPolishedButton(page.getByRole('button', { name: 'Log out' }))

  await page.getByRole('button', { name: 'Log out' }).click()
  await expect(page).toHaveURL(/\/users\/sign_in$/)
  await expect(page.locator('.login-shell')).toBeVisible()

  await page.goto('/todos', { waitUntil: 'domcontentloaded', timeout: 15_000 })
  await expect(page).toHaveURL(/\/users\/sign_in$/)
  await expect(page.locator('.login-flash')).toContainText(/sign in/i)
})

test('keeps user management admin-only for guest sessions', async ({ page }) => {
  await gotoLogin(page)
  await continueAsGuest(page)
  await expect(page.getByRole('link', { name: 'Users' })).toHaveCount(0)

  await page.goto('/users', { waitUntil: 'domcontentloaded', timeout: 15_000 })

  await expect(page).toHaveURL(/\/todos$/)
  await expect(page.locator(hooks.selectors.userFrame)).toHaveCount(1)
  await expect(page.locator(hooks.selectors.userFrame)).not.toContainText('Admin-only RailsHx user management')
  await expect(page.getByRole('link', { name: 'Users' })).toHaveCount(0)
})

test('renders the typed RailsHx todo page through real browser assets', async ({ page }) => {
  await loginAsOwner(page)

  await expect(page).toHaveTitle(/RailsHx Todoapp/)
  await expect(page.getByText('Typed Rails, polished Ruby.')).toBeVisible()
  await expect(page.locator(`meta[name="${hooks.meta.templateName}"]`)).toHaveAttribute('content', hooks.meta.templateContent)
  await expect(page.locator(hooks.selectors.scrollLinks).first()).toHaveAttribute(hooks.attrs.bound, 'true')

  const bodyText = await page.locator('body').innerText()
  expect(bodyText).toMatch(/RailsHx sample/i)
  expect(bodyText).toMatch(/Devise session active/i)
  expect(bodyText).toMatch(/owner@example\.test/i)
  expect(bodyText).toMatch(/Typed Turbo room/i)
  expect(bodyText).toContain('Ship typed Rails templates')
  expect(bodyText).toContain('Routes, params, and HHX are all typed for this room.')
  expect(bodyText).not.toMatch(/DeviseHx auth layer|Continue as guest|Turbo Frame ready/i)
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

  await expect(page.locator(hooks.selectors.form)).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator(hooks.selectors.chatForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
})

test('deep-links typed user management as a refreshable Rails page', async ({ page }) => {
  await loginAsOwner(page)

  const frame = page.locator(hooks.selectors.userFrame)
  await expect(frame).toHaveCount(1)

  await page.getByRole('link', { name: 'Users' }).click()

  await expect(page).toHaveURL(/\/users$/)
  await expect(frame).toContainText('Admin-only RailsHx user management', { timeout: 20_000 })
  await expect(frame).toContainText('Typed users, ordinary Rails CRUD.')
  await expect(frame.locator('.user-management-card')).toHaveCount(4)
  await expectPolishedButton(frame.getByRole('button', { name: 'Create user' }))
  await expectPolishedButton(frame.locator('.user-management-card').filter({ hasText: 'member@example.test' }).getByRole('button', { name: 'Save user' }))
  await expectPolishedButton(frame.locator('.user-management-card').filter({ hasText: 'member@example.test' }).getByRole('button', { name: 'Remove user' }))
  await expect(frame.locator('.user-management-card.is-current').getByRole('button', { name: 'Remove user' })).toHaveCount(0)

  await page.reload()
  await expect(page).toHaveURL(/\/users$/)
  await expect(frame).toContainText('Admin-only RailsHx user management')
})

test('renders the users route directly as a Rails fallback with the same frame contract', async ({ page }) => {
  await loginAsOwner(page)
  await page.goto('/users', { waitUntil: 'domcontentloaded', timeout: 15_000 })

  const frame = page.locator(hooks.selectors.userFrame)
  await expect(frame).toBeVisible()
  await expect(frame).toContainText('Admin-only RailsHx user management')
  await expect(page.getByRole('link', { name: 'Back to todo board' })).toBeVisible()
})

test('lets admins create, update, and remove users through typed RailsHx CRUD', async ({ page }) => {
  await loginAsOwner(page)
  await page.getByRole('link', { name: 'Users' }).click()

  const frame = page.locator(hooks.selectors.userFrame)
  const createForm = frame.locator('.user-create-card')
  const unique = Date.now()
  const email = `teammate-${unique}@example.test`

  await createForm.getByLabel('Name').fill(`Typed Teammate ${unique}`)
  await createForm.getByLabel('Email').fill(email)
  await createForm.getByLabel('Role').selectOption('member')
  await createForm.getByLabel('Password', { exact: true }).fill('password123')
  await createForm.getByLabel('Confirm password').fill('password123')
  await createForm.getByRole('button', { name: 'Create user' }).click()

  const card = frame.locator('.user-management-card').filter({ hasText: email })
  await expect(card).toBeVisible({ timeout: 20_000 })
  await expectServerFlashToast(page, 'User saved')
  await card.locator('select[name="user[role]"]').selectOption('admin')
  await card.getByRole('button', { name: 'Save user' }).click()

  const updatedCard = frame.locator('.user-management-card').filter({ hasText: email })
  await expect(updatedCard).toContainText('Admin', { timeout: 20_000 })
  await expectServerFlashToast(page, 'User updated')
  await updatedCard.getByRole('button', { name: 'Remove user' }).click()
  await expectServerFlashToast(page, 'User removed')
  await expect(frame).not.toContainText(email, { timeout: 20_000 })
})

test('shows typed Rails validation feedback when user creation fails', async ({ page }) => {
  await loginAsOwner(page)
  await page.getByRole('link', { name: 'Users' }).click()
  await expect(page).toHaveURL(/\/users$/)

  const frame = page.locator(hooks.selectors.userFrame)
  const createForm = frame.locator('.user-create-card')

  await createForm.getByLabel('Name').fill('Duplicate Member')
  await createForm.getByLabel('Email').fill('member@example.test')
  await createForm.getByLabel('Role').selectOption('member')
  await createForm.getByLabel('Password', { exact: true }).fill('password123')
  await createForm.getByLabel('Confirm password').fill('different123')
  await createForm.getByRole('button', { name: 'Create user' }).click()

  await expect(page).toHaveURL(/\/users$/)
  await expectServerFlashToast(page, 'Could not save user')
  await expect(frame.locator('.error-summary')).toBeVisible()
  await expect(frame.locator('.error-summary')).toContainText(/Email has already been taken|Password confirmation/i)
  await expect(createForm.getByLabel('Email')).toHaveValue('member@example.test')
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
  await expect(page.locator('.session-chip').getByText('Guest Workspace', { exact: true })).toBeVisible()
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

test('submits chat composer with Enter and preserves Shift+Enter newlines', async ({ page }) => {
  await gotoAuthenticatedTodos(page)
  await expect(page.locator(hooks.selectors.chatForms).first()).toHaveAttribute(hooks.attrs.bound, 'true')
  await expect(page.locator('turbo-cable-stream-source[connected]')).toBeVisible()

  const beforeCount = await page.locator(hooks.selectors.chatMessages).count()
  const firstLine = `Keyboard note ${Date.now()}`
  const secondLine = 'second line stays multiline before submit'
  const composer = page.getByLabel('Add a typed room note')

  await composer.fill(firstLine)
  await composer.press('Shift+Enter')
  await composer.type(secondLine)
  await expect(composer).toHaveValue(`${firstLine}\n${secondLine}`)

  await composer.press('Enter')

  await expect(page.locator(hooks.selectors.chatPanel)).toContainText(firstLine, { timeout: 20_000 })
  await expect(page.locator(hooks.selectors.chatPanel)).toContainText(secondLine)
  await expect(page.getByText('Room note posted')).toBeVisible()
  await expect(composer).toHaveValue('')
  await expect.poll(async () => page.locator(hooks.selectors.chatMessages).count()).toBeGreaterThanOrEqual(beforeCount)
})

test('broadcasts typed Turbo Stream room notes to another browser session', async ({ browser }) => {
  const sender = await browser.newPage()
  const receiver = await browser.newPage()
  try {
    await gotoAuthenticatedTodos(sender)
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
      'chat_message[body]': body
    }
  })

  await page.reload()
  await expect(page.locator(hooks.selectors.chatPanel)).toContainText(body, { timeout: 20_000 })
})
