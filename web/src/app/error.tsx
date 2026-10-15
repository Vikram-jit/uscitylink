'use client';

import * as React from 'react';
import Button from '@mui/material/Button';
import Container from '@mui/material/Container';
import { WarningCircle } from '@phosphor-icons/react/dist/ssr/WarningCircle';

import { EmptyState } from '@/components/core/empty-state';

// Catches render errors in any page so one failing screen can't break the whole app
export default function Error({ error, reset }: { error: Error & { digest?: string }; reset: () => void }): React.JSX.Element {
  React.useEffect(() => {
    // eslint-disable-next-line no-console -- surface the real error in the browser console
    console.error(error);
  }, [error]);

  return (
    <Container maxWidth="sm" sx={{ py: 8 }}>
      <EmptyState
        action={
          <Button onClick={() => reset()} variant="contained">
            Try again
          </Button>
        }
        description="This page hit an unexpected problem. Try again, or reload the page if it keeps happening."
        icon={WarningCircle}
        title="Something went wrong"
      />
    </Container>
  );
}
