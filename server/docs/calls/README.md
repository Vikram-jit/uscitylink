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

## Group calls (staff adds staff)
During an answered call, anyone on it who is staff can ask another **staff member** to join, from the
**Add** button on the dashboard call bar. Drivers can't be added. A call holds at most **6 people**
(`MAX_PARTICIPANTS` in `callService.ts`).

- The person asked gets a ringing "Request to join a call" card on the dashboard, or a call on the
  staff app. It times out after 45 s. Whoever asked can take it back while it rings.
- Everyone connects directly to everyone else (mesh). The person joining sends the offers. Signals
  carry `to` / `from`, so each pair has its own connection.
- When someone hangs up while 3 or more are on the call, only they leave. With 2 left, a hang-up ends
  the call for both. A dropped connection that doesn't come back within 15 s counts as leaving.
- **Older driver apps** (builds before group calls) can't take part. The server refuses to add anyone
  while such an app is on the call, and says who needs to update. New apps and the dashboard send
  `group: true` with `call:invite` / `call:accept`.
- **Logged:** `call_participants` has a row per person asked, with `role = 'added'`, `invited_by`, and
  `state` set to joined / declined / missed / cancelled, plus `joined_at` / `left_at`. The chat bubble
  says "Voice call · 3:42 · 3 people". The Calls page marks group calls, and the call details list who
  added whom.
- **Recorded:** every person on the call sends their own voice to the recorder, so the recording has
  everyone, lined up in time.

## Transfer (hand a call to another dispatcher)
The dashboard call bar has a **Transfer** button (⇄) for calls with a driver. The chosen dispatcher
gets a ringing **Transferred call** card. When they pick up, they join, and the one who transferred
leaves automatically (`call:transferred`, then `call:ended` with reason `transferred`). The driver
never hears a disconnect: they just see someone join and someone leave. If the new dispatcher
declines or doesn't answer, the first one is told (`call:transfer_failed`) and stays on the call. A
transfer still works when the call is full, because it replaces whoever transferred. It's logged as
`call_participants.join_type = 'transfer'` with `invited_by`. The rules for older driver apps are
the same as for group calls.

## "On call" marks
Every staff connection gets `calls:on_call` with the answered calls: the driver, and everyone on
each call. It's sent on connect, and then whenever someone answers, joins, leaves or a call ends;
`calls:on_call_get` asks for it on demand. Drivers in the chat list (dashboard and staff app) are
highlighted with **On call · <who>**.

## Call recording
Every answered call is recorded (admin switch: **Record calls** on the Calls page, or
`PUT /api/v1/calls/settings {"recording": false}`). The decision is made when the call starts.

How it works (`src/calls/callRecorder.ts`):
1. The call itself stays peer-to-peer. Once it connects, each side opens a second, send-only WebRTC
   connection to this server with its own microphone (`call:rec_offer`), using the `werift` library.
2. The server writes each voice to its own file while the call runs. If an app or tab dies mid-call,
   the audio up to that moment is already on disk.
3. When the call ends, ffmpeg (`ffmpeg-static`, installed by `npm install`) mixes the voices, lined up
   by when each started, into one mono AAC `.m4a`. The file's SHA-256 is saved, and the file goes to
   S3 at `call-recordings/YYYY/MM/<callId>.m4a` with server-side encryption.
4. The `call_recordings` row records the status (`recording → processing → ready | failed`), the S3 key,
   length, size, SHA-256 and whose audio is in it.
5. Staff play or download a recording from the call's details (Calls page). The link is a presigned
   S3 URL valid for 15 minutes, and every opening is logged.

If the server restarts mid-call, or an upload fails, the files stay in `RECORDING_DIR`, and the next
start finishes them (`recoverRecordings`).

**Consent:** both people hear two short beeps when a recorded call connects, and see a red
**Recorded** badge. An incoming call also says "This call will be recorded". California and several
other states require every party to know a call is recorded, so keep these.

**AWS setup (once):**
1. Security group: allow **inbound UDP 40000–40200**, the `RECORDING_UDP_PORTS` range.
2. In `.env`, set `RECORDING_UDP_PORTS=40000-40200` and `RECORDING_PUBLIC_IP=<public IP>`.
3. Run `npx sequelize-cli db:migrate` to create the `call_recordings` table, then restart.

Storage: about 0.35 MB per minute of call (48 kbps AAC). To delete old recordings automatically, add
an S3 lifecycle rule on the `call-recordings/` prefix. There's no expiry by default.

## Adding later
- **Video:** `type: "video"` already flows through invite/DB; add a video track in the clients.
- **Staff ↔ staff:** extend `resolveInvite` in `callSocket.ts`.
- **Bigger group calls (5+):** move from the mesh to a server that forwards audio (an SFU, such as
  mediasoup or LiveKit OSS). The recorder already receives everyone's audio.
