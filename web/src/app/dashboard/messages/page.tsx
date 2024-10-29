import * as React from 'react';
import type { Metadata } from 'next';

import { config } from '@/config';
import ChatUi from '@/components/messages/ChatUi';

export const metadata = { title: `Users | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return <ChatUi />;
}
