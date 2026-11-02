/**
 * Which API/socket server the dashboard talks to, chosen from the address the dashboard was
 * opened on:
 *   http://52.9.12.189:3004         → API_URL / SOCKET_URL from the build (http://52.9.12.189:4300)
 *   https://chatbox.truckcrave.com  → https://chatbox-server.truckcrave.com
 * An https page cannot call an http server (the browser blocks "mixed content"), so the domain
 * must use the domain server. Add a line to DOMAIN_SERVERS for any new domain.
 */
const DOMAIN_SERVERS: Record<string, string> = {
  'chatbox.truckcrave.com': 'https://chatbox-server.truckcrave.com',
};

// Old builds hard-coded this for chat media; still used when the dashboard is opened by IP
const IP_SERVER = 'http://52.9.12.189:4300';

function domainServer(): string | null {
  if (typeof window === 'undefined') return null;
  return DOMAIN_SERVERS[window.location.hostname] ?? null;
}

/** Base for REST calls, e.g. http://52.9.12.189:4300/api/v1/ — keeps the build's /api/vN/ path. */
export function apiUrl(): string {
  const built = process.env.API_URL ?? '';
  const server = domainServer();
  if (!server) return built;
  let path = '/api/v1/';
  try {
    path = new URL(built).pathname;
  } catch {
    // API_URL not set or relative: keep the default path
  }
  return `${server}${path}`;
}

/** Socket.IO server and files served by the API server (e.g. /uscitylink/<key>). */
export function socketUrl(): string {
  return domainServer() ?? process.env.SOCKET_URL ?? '';
}

/** Server for chat media links that were hard-coded to the IP. */
export function mediaServerUrl(): string {
  return domainServer() ?? IP_SERVER;
}
