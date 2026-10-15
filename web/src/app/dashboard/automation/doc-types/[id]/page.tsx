import * as React from 'react';

import { DocTypeEditor } from '@/components/dashboard/automation/DocTypeEditor';

export default function Page({ params }: { params: { id: string } }): React.JSX.Element {
  return <DocTypeEditor id={params.id} />;
}
