import * as React from 'react';
import type { Metadata } from 'next';

import { config } from '@/config';

import ChatView from '@/components/dashboard/staff_chat/chat_view';

export const metadata = { title: `Staff Chat | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (


     <ChatView/>

  );
}
