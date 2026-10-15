// polyfills.ts
import { ReadableStream as PonyfillReadableStream } from 'web-streams-polyfill';

// Only fill the gap on old Node versions. Replacing Node's built-in ReadableStream breaks every
// library that uses the built-in fetch (for example the Anthropic SDK, whose requests then never finish).
if (typeof (globalThis as any).ReadableStream === 'undefined') {
  (globalThis as any).ReadableStream = PonyfillReadableStream;
}
