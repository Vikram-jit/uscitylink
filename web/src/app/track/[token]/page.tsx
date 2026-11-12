import * as React from 'react';
import type { Metadata } from 'next';

import { TrackingPage } from '@/components/tracking/TrackingPage';

// Public shipment tracking for shippers / customers (no login). One link per load; it stops showing
// the load once the load is completed.
export const metadata = { title: 'Shipment tracking | US City Link', robots: { index: false, follow: false } } satisfies Metadata;

export default function Page({ params }: { params: { token: string } }): React.JSX.Element {
  return <TrackingPage token={params.token} />;
}
