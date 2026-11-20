// Ends the web session when it is no longer valid: everything in localStorage is cleared and the
// browser goes to the sign-in page. Triggered by
//   · any API call answered 401 (token expired, revoked or invalid — see apiSlice), and
//   · the token's own expiry time passing while the tab is open (checked on focus and every minute).

import { paths } from '@/paths';

const TOKEN_KEY = 'custom-auth-token';
let ending = false;

/** Seconds-since-epoch expiry of a JWT, or null if it has none / can't be read */
function tokenExpiry(token: string): number | null {
  try {
    const part = token.split('.')[1];
    if (!part) return null;
    const json = JSON.parse(atob(part.replace(/-/g, '+').replace(/_/g, '/')));
    return typeof json.exp === 'number' ? json.exp : null;
  } catch {
    return null;
  }
}

export function hasToken(): boolean {
  try {
    return !!localStorage.getItem(TOKEN_KEY);
  } catch {
    return false;
  }
}

export function tokenExpired(now = Date.now()): boolean {
  let token: string | null = null;
  try {
    token = localStorage.getItem(TOKEN_KEY);
  } catch {
    return false;
  }
  if (!token) return false;
  const exp = tokenExpiry(token);
  return exp !== null && exp * 1000 <= now;
}

/** Clear all localStorage and open the sign-in page (once, however many calls fail at the same time). */
export function endSession(): void {
  if (ending || typeof window === 'undefined') return;
  ending = true;
  try {
    localStorage.clear();
    sessionStorage.clear();
  } catch {
    // storage blocked: still leave the page
  }
  if (window.location.pathname.startsWith(paths.auth.signIn)) {
    ending = false;
    return;
  }
  window.location.replace(`${paths.auth.signIn}?expired=1`);
}

/** Watches the token's expiry while the tab is open; returns a stop function. */
export function watchSessionExpiry(): () => void {
  const check = (): void => {
    if (tokenExpired()) endSession();
  };
  check();
  const timer = window.setInterval(check, 60_000);
  window.addEventListener('focus', check);
  document.addEventListener('visibilitychange', check);
  return () => {
    window.clearInterval(timer);
    window.removeEventListener('focus', check);
    document.removeEventListener('visibilitychange', check);
  };
}
