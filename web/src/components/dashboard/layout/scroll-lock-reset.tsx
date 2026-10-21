'use client';

import * as React from 'react';
import { usePathname } from 'next/navigation';

// Some screens lock page scrolling while a slide-in pane is open (Messages on phones). Leaving the
// screen through the sidebar never closes that pane, so release the lock on every navigation.
export function ScrollLockReset(): null {
  const pathname = usePathname();
  React.useEffect(() => {
    document.body.style.removeProperty('overflow');
    document.documentElement.style.removeProperty('--MessagesPane-slideIn');
    document.documentElement.style.removeProperty('--SideNavigation-slideIn');
  }, [pathname]);
  return null;
}
