import * as React from 'react';
import type { Viewport } from 'next';

import '@/styles/global.css';

import { UserProvider } from '@/contexts/user-context';
import { LocalizationProvider } from '@/components/core/localization-provider';
import StoreProvider from '@/components/core/StoreProvider';
import { ThemeProvider } from '@/components/core/theme-provider/theme-provider';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

export const viewport = { width: 'device-width', initialScale: 1 } satisfies Viewport;

interface LayoutProps {
  children: React.ReactNode;
}

export default function Layout({ children }: LayoutProps): React.JSX.Element {
  return (
    <html lang="en">
      <body>
        <StoreProvider>
          <LocalizationProvider>
            <UserProvider>
              <ThemeProvider>{children}</ThemeProvider>
            </UserProvider>
          </LocalizationProvider>
        </StoreProvider>
        <ToastContainer />
      </body>
    </html>
  );
}
