import * as React from 'react';

import { FlowBuilder } from '@/components/dashboard/automation/FlowBuilder';

export default function Page({ params }: { params: { id: string } }): React.JSX.Element {
  return <FlowBuilder id={params.id} />;
}
