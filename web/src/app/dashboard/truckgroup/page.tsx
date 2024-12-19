import * as React from 'react';
import type { Metadata } from 'next';

import { config } from '@/config';

import View from '@/components/dashboard/truckgroup/view';

export const metadata = { title: `Groups | Dashboard | ${config.site.name}` } satisfies Metadata;

export default function Page(): React.JSX.Element {
  return (


     <View type={"truck"}/>

  );
}
