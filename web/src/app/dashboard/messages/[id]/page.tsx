import * as React from 'react';
import type { Metadata } from 'next';

import { config } from '@/config';
import SingleMessagesPane from '@/components/messages/SingleMessagesPane';
import SingleChatUi from '@/components/messages/SingleChatUi';

export const metadata = { title: `Users | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page({ params }: { params: { id: string } }): React.JSX.Element {
  return <SingleChatUi id={params.id} />;
}
