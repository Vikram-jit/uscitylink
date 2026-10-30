# Voice calls (WebRTC)

Staff (web or app) ↔ driver (app), audio, peer-to-peer. Free stack: browser/`flutter_webrtc`,
Socket.IO signalling on this server, Google STUN + our own **coturn** for TURN.

```
web / app ── audio (Opus/SRTP, peer-to-peer, or relayed by coturn) ── app
     └──── Socket.IO "call:*" ──── this server ──── FCM data (Android) / APNs VoIP (iOS)
```

| Piece | Where |
|---|---|
| State machine (ringing → active → ended, busy, timeouts, reconnect) | `src/calls/callService.ts` |
| Socket events + who may call whom | `src/calls/callSocket.ts` |
| Push to closed apps | `src/calls/callPush.ts` |
| Chat bubble ("Voice call · 3:42") | `src/calls/callLog.ts` |
| REST: config/ICE, VoIP token, history, quality, on/off | `src/calls/callController.ts`, `src/routes/callRoutes.ts` |
| Tables | `calls`, `call_participants`, `messages.call_id`, `user_profiles.voip_token` |
| Tests | `npx ts-node -T scripts/calls/stateMachine.check.ts` |

## Dispatch line (driver → dispatch)

- Rings **every dispatcher online on the driver's channel** (at least one live connection — any
  dashboard tab or the staff app) **who isn't on a call**. All their tabs ring; the first to answer
  gets the call, everyone else stops ringing.
- Each new driver call rings only the dispatchers still free. When **all are busy** the driver
  waits in line ("You're #1 in line") and the oldest waiting call rings the next dispatcher who
  hangs up (or comes online). A dispatcher ringing for two drivers who answers one sends the other
  back into the line in its original place.
- Nobody online → missed immediately. Waiting more than 3 minutes → missed (`queue_timeout`).

Every call is logged (`calls` + `call_participants`): who called, who it rang and what each person
did (answered / declined / didn't answer / answered elsewhere), who answered, time waiting in line,
time to answer, talk time, how it ended, and the connection quality from both ends. Web → Calls
shows the history; click a row for the full timeline.

## Environment (`server/.env`)

```ini
# TURN (coturn) — needed for drivers on mobile data; without it some calls connect with no audio
TURN_URLS=turn:turn.example.com:3478?transport=udp,turn:turn.example.com:3478?transport=tcp,turns:turn.example.com:5349?transport=tcp
TURN_SECRET=<long random string, same as static-auth-secret in turnserver.conf>
TURN_TTL_SEC=21600
# STUN_URLS=stun:stun.l.google.com:19302      # optional override

# iOS ringing when the app is closed (APNs VoIP push). Apple Developer → Keys → new key with APNs.
APNS_KEY_PATH=/var/www/html/uscitylink/server/config/AuthKey_XXXXXXXXXX.p8
APNS_KEY_ID=XXXXXXXXXX
APNS_TEAM_ID=YYYYYYYYYY
APNS_BUNDLE_ID=com.uscitylinkcorp.uscitylink
APNS_PRODUCTION=true          # false for development builds from Xcode
```
Android needs nothing extra (uses the existing Firebase `config/firebase.json`).

## coturn on the AWS server (Ubuntu)

```bash
sudo apt-get update && sudo apt-get install -y coturn
sudo sed -i 's/^#TURNSERVER_ENABLED=1/TURNSERVER_ENABLED=1/' /etc/default/coturn
openssl rand -hex 32          # → use as TURN_SECRET and static-auth-secret
```

`/etc/turnserver.conf`:
```ini
listening-port=3478
tls-listening-port=5349
fingerprint
use-auth-secret
static-auth-secret=<TURN_SECRET>
realm=uscitylink
# EC2: private IP / public IP
listening-ip=<private-ip>
external-ip=<public-ip>/<private-ip>
min-port=49152
max-port=65535
# TLS (TURN over 443/5349 gets through strict networks) — reuse the site's Let's Encrypt cert
cert=/etc/letsencrypt/live/<domain>/fullchain.pem
pkey=/etc/letsencrypt/live/<domain>/privkey.pem
no-cli
no-multicast-peers
# never relay into the private network
denied-peer-ip=10.0.0.0-10.255.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
denied-peer-ip=192.168.0.0-192.168.255.255
total-quota=200
log-file=/var/log/turnserver.log
```

```bash
sudo systemctl enable --now coturn
sudo systemctl status coturn
```

**AWS security group** (inbound): UDP+TCP 3478, TCP 5349, UDP 49152-65535.

**Check it:** open https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/, add
`turn:<host>:3478` with a username/password from `GET /api/v2/calls/config` (signed in), "Gather
candidates" → a `relay` row must appear.

## Costs
Everything is free/open source. The only cost is AWS bandwidth for relayed calls (roughly
1–2 MB per minute; most calls connect directly and don't use the relay).

## Switching calls off
`PUT /api/v1/calls/settings {"enabled": false}` (admin) — the call buttons hide and invites are refused.

## Adding later
- **Video:** `type: "video"` already flows through invite/DB; add a video track in the clients.
- **Staff ↔ staff:** extend `resolveInvite` in `callSocket.ts`.
- **Group calls / recording:** replace the peer-to-peer engine in the clients with a self-hosted SFU
  (mediasoup or LiveKit OSS); `call_participants` already models multiple people.
