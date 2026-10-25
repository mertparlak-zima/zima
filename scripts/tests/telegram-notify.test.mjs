import assert from 'node:assert/strict';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { parseTelegramEnv, sendNotification, telegramEnvPath } from '../telegram-notify.mjs';

// Construct opaque fixture credentials at runtime; no credential-shaped literal.
const token = `${123456 + 1}:${'x'.repeat(35)}`;
const chatId = String(987654 + 1);
const config = { token, chatId };
const envText = `TELEGRAM_BOT_TOKEN=${token}\nTELEGRAM_CHAT_ID=${chatId}\n`;
const hidden = error => error.message === 'Telegram notification failed'
  && !error.stack.includes(token) && !error.stack.includes(chatId);

test('configuration handles BOM, quotes, comments and unrelated machine settings', () => {
  assert.deepEqual(parseTelegramEnv(`\uFEFF# private fixture\r\nZIMA_LOCALE=en-US\r\n telegram_bot_token = '${token}'\r\nTELEGRAM_CHAT_ID="${chatId}"\r\n`), config);
  assert.equal(telegramEnvPath, resolve(dirname(fileURLToPath(import.meta.url)), '../../.env'));
});

test('missing, malformed and duplicate selected configuration fails without exposing values', () => {
  for (const text of ['', `TELEGRAM_BOT_TOKEN=${token}`, `${envText}telegram_bot_token=`, `${envText}TELEGRAM_CHAT_ID=`,
    `TELEGRAM_BOT_TOKEN='${token}\nTELEGRAM_CHAT_ID=${chatId}`, `TELEGRAM_BOT_TOKEN=bad\nTELEGRAM_CHAT_ID=${chatId}`, `${envText}malformed`]) {
    assert.throws(() => parseTelegramEnv(text), error => error.message === 'Telegram configuration invalid'
      && !error.stack.includes(token) && !error.stack.includes(chatId));
  }
});

test('one fixed HTTPS sendMessage POST contains only configured chat, stdin text and silent flag', async () => {
  let calls = 0;
  const result = await sendNotification(config, 'Fixture result\nVerification: PASS', { silent: true, fetchImpl: async (url, options) => {
    calls++;
    assert.equal(url, `https://api.telegram.org/bot${token}/sendMessage`);
    assert.equal(options.method, 'POST');
    assert.equal(options.redirect, 'error');
    assert.deepEqual(options.headers, { 'content-type': 'application/json' });
    assert.deepEqual(JSON.parse(options.body), { chat_id: chatId, text: 'Fixture result\nVerification: PASS', disable_notification: true });
    assert.ok(options.signal instanceof AbortSignal);
    return { ok: true, json: async () => ({ ok: true, result: { private: token } }) };
  } });
  assert.equal(calls, 1);
  assert.deepEqual(result, { ok: true });
});

test('default notification is audible and rejects invalid text before network access', async () => {
  await sendNotification(config, 'Fixture', { fetchImpl: async (_, options) => {
    assert.equal(JSON.parse(options.body).disable_notification, false);
    return { ok: true, json: async () => ({ ok: true }) };
  } });
  for (const text of ['', '  ', 'x'.repeat(4097)]) {
    await assert.rejects(sendNotification(config, text, { fetchImpl: () => assert.fail('network reached') }), /Notification text must contain/u);
  }
});

test('network, HTTP, API and response parsing errors never expose token, chat or response details', async () => {
  for (const fetchImpl of [
    async () => { throw new Error(`https://api.telegram.org/bot${token}/sendMessage ${chatId}`); },
    async () => ({ ok: false, json: async () => { throw new Error(token); } }),
    async () => ({ ok: true, json: async () => ({ ok: false, description: `${token} ${chatId}` }) }),
    async () => ({ ok: true, json: async () => { throw new Error(token); } }),
  ]) await assert.rejects(sendNotification(config, 'Fixture', { fetchImpl }), hidden);
});

test('deadline covers stalled request and response body and aborts the request', async () => {
  for (const phase of ['request', 'body']) {
    let signal;
    await assert.rejects(sendNotification(config, 'Fixture', { timeoutMs: 10, fetchImpl: async (_, options) => {
      signal = options.signal;
      if (phase === 'request') return new Promise(() => {});
      return { ok: true, json: () => new Promise(() => {}) };
    } }), hidden);
    assert.equal(signal.aborted, true);
  }
});

test('CLI rejects arguments without reading local configuration or exposing stdin', () => {
  const script = fileURLToPath(new URL('../telegram-notify.mjs', import.meta.url));
  const result = spawnSync(process.execPath, [script, '--invalid'], { input: token, encoding: 'utf8' });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  assert.equal(result.stderr, 'Telegram notification failed.\n');
});
