import * as React from 'react';
import type { Metadata } from 'next';

import { config } from '@/config';
import SingleChatUi from '@/components/messages/SingleChatUi';

export const metadata = { title: `Chat | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page({ params }: { params: { id: string } }): React.JSX.Element {
  return <SingleChatUi id={params.id} />;
}
