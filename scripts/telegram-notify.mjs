// Outbound sendMessage only. Importing this module performs no I/O.
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const telegramEnvPath = fileURLToPath(new URL('../.env', import.meta.url));
const configError = () => new Error('Telegram configuration invalid');
const sendError = () => new Error('Telegram notification failed');

function validateConfig({ token, chatId } = {}) {
  if (typeof token !== 'string' || !/^\d{5,20}:[A-Za-z0-9_-]{20,200}$/u.test(token)
      || typeof chatId !== 'string' || !/^-?[1-9]\d{0,19}$/u.test(chatId)) {
    throw configError();
  }
  return { token, chatId };
}

export function parseTelegramEnv(text) {
  if (typeof text !== 'string') throw configError();
  const selected = new Map();
  for (const line of text.replace(/^\uFEFF/u, '').split(/\r?\n/u)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const separator = trimmed.indexOf('=');
    if (separator <= 0) throw configError();
    const key = trimmed.slice(0, separator).trim().toUpperCase();
    if (!['TELEGRAM_BOT_TOKEN', 'TELEGRAM_CHAT_ID'].includes(key)) continue;
    if (selected.has(key)) throw configError();
    let value = trimmed.slice(separator + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"'))
        || (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1, -1);
    selected.set(key, value);
  }
  return validateConfig({ token: selected.get('TELEGRAM_BOT_TOKEN'), chatId: selected.get('TELEGRAM_CHAT_ID') });
}

export async function sendNotification(config, text, { silent = false, fetchImpl = globalThis.fetch, timeoutMs = 10_000 } = {}) {
  const { token, chatId } = validateConfig(config);
  if (typeof text !== 'string' || !text.trim() || text.length > 4096 || typeof silent !== 'boolean') {
    throw new Error('Notification text must contain 1–4096 characters');
  }
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 10_000) throw sendError();
  const controller = new AbortController();
  let timer;
  try {
    await Promise.race([
      (async () => {
        const response = await fetchImpl(`https://api.telegram.org/bot${token}/sendMessage`, {
          method: 'POST', redirect: 'error', signal: controller.signal,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ chat_id: chatId, text, disable_notification: silent }),
        });
        if (!response.ok || (await response.json()).ok !== true) throw sendError();
      })(),
      new Promise((_, reject) => {
        timer = setTimeout(() => { controller.abort(); reject(sendError()); }, timeoutMs);
      }),
    ]);
    return { ok: true };
  } catch {
    // Never expose fetch errors, response bodies, token-bearing URLs or chat IDs.
    throw sendError();
  } finally {
    clearTimeout(timer);
  }
}

async function main() {
  try {
    const args = process.argv.slice(2);
    if (args.length > 1 || (args.length === 1 && args[0] !== '--silent')) throw sendError();
    let text = '';
    process.stdin.setEncoding('utf8');
    for await (const chunk of process.stdin) {
      text += chunk;
      if (text.length > 4096) throw sendError();
    }
    const config = parseTelegramEnv(await readFile(telegramEnvPath, 'utf8'));
    await sendNotification(config, text, { silent: args[0] === '--silent' });
    process.stdout.write('Telegram notification sent.\n');
  } catch {
    process.stderr.write('Telegram notification failed.\n');
    process.exitCode = 1;
  }
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) await main();
