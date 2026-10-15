'use client';

import * as React from 'react';

// Last-resort boundary (replaces the root layout), so it uses plain HTML and inline styles only
export default function GlobalError({ reset }: { error: Error & { digest?: string }; reset: () => void }): React.JSX.Element {
  return (
    <html lang="en">
      <body
        style={{
          alignItems: 'center',
          background: '#f8fafc',
          color: '#0f172a',
          display: 'flex',
          fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif',
          justifyContent: 'center',
          margin: 0,
          minHeight: '100vh',
        }}
      >
        <div style={{ maxWidth: 380, padding: 24, textAlign: 'center' }}>
          <h1 style={{ fontSize: 20, fontWeight: 600, margin: '0 0 8px' }}>Something went wrong</h1>
          <p style={{ color: '#64748b', fontSize: 14, lineHeight: 1.6, margin: '0 0 20px' }}>
            The dashboard hit an unexpected problem. Reload to continue.
          </p>
          <button
            onClick={() => (reset ? reset() : window.location.reload())}
            style={{
              background: '#2563eb',
              border: 0,
              borderRadius: 8,
              color: '#fff',
              cursor: 'pointer',
              fontSize: 14,
              fontWeight: 600,
              padding: '9px 18px',
            }}
            type="button"
          >
            Reload
          </button>
        </div>
      </body>
    </html>
  );
}
