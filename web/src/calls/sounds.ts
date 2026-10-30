// Call tones generated with WebAudio (no audio files to ship):
//   ringback — what the caller hears while it rings (North American 440+480 Hz, 2 s on / 4 s off)
//   ringtone — incoming call (two short warbles, repeating)
//   endTone  — short beep when a call ends

let ctx: AudioContext | null = null;
const audio = () => {
  if (typeof window === 'undefined') return null;
  if (!ctx) ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
  if (ctx.state === 'suspended') void ctx.resume();
  return ctx;
};

function tone(freqs: number[], start: number, duration: number, volume = 0.08) {
  const ac = audio();
  if (!ac) return;
  const gain = ac.createGain();
  gain.gain.setValueAtTime(0, ac.currentTime + start);
  gain.gain.linearRampToValueAtTime(volume, ac.currentTime + start + 0.02);
  gain.gain.setValueAtTime(volume, ac.currentTime + start + duration - 0.03);
  gain.gain.linearRampToValueAtTime(0, ac.currentTime + start + duration);
  gain.connect(ac.destination);
  freqs.forEach((f) => {
    const osc = ac.createOscillator();
    osc.frequency.value = f;
    osc.connect(gain);
    osc.start(ac.currentTime + start);
    osc.stop(ac.currentTime + start + duration + 0.05);
  });
}

let loop: ReturnType<typeof setInterval> | null = null;

export function stopTones() {
  if (loop) clearInterval(loop);
  loop = null;
}

export function playRingback() {
  stopTones();
  const play = () => tone([440, 480], 0, 2);
  play();
  loop = setInterval(play, 6000);
}

export function playRingtone() {
  stopTones();
  const play = () => {
    for (let i = 0; i < 2; i++) {
      tone([1046, 1318], i * 0.45, 0.18, 0.12);
      tone([1318, 1568], i * 0.45 + 0.2, 0.18, 0.12);
    }
  };
  play();
  loop = setInterval(play, 2600);
}

export function playEndTone() {
  stopTones();
  tone([480, 620], 0, 0.25, 0.06);
}
