// polyfills.ts
import { ReadableStream as PonyfillReadableStream } from 'web-streams-polyfill';

(globalThis as any).ReadableStream = PonyfillReadableStream;
