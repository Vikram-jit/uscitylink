'use client';

import * as React from 'react';
import { Alert, Box, CircularProgress } from '@mui/material';

import { useGetAutomationMeQuery } from '@/redux/AutomationApiSlice';

// Who may do what:
//   Automation  — staff can read everything, only admins change it (the server enforces the same)
//   Compliance  — staff and admins have full control
export function useAutomationAccess(): { loading: boolean; isAdmin: boolean; isStaff: boolean; readOnly: boolean } {
  const { data, isLoading } = useGetAutomationMeQuery();
  const isAdmin = !!data?.data?.isAdmin;
  const isStaff = isAdmin || data?.data?.role === 'staff';
  return { loading: isLoading, isAdmin, isStaff, readOnly: !isAdmin };
}

// Renders its children only for admins (action buttons in Automation)
export function AdminOnly({ children }: { children: React.ReactNode }): React.JSX.Element | null {
  const { isAdmin } = useAutomationAccess();
  return isAdmin ? <>{children}</> : null;
}

// For staff, shows a form as-is but locked: nothing inside can be clicked or typed into
export function ReadOnlyArea({ children }: { children: React.ReactNode }): React.JSX.Element {
  const { readOnly } = useAutomationAccess();
  if (!readOnly) return <>{children}</>;
  return (
    <Box
      aria-disabled
      component="fieldset"
      disabled
      sx={{
        border: 0,
        m: 0,
        p: 0,
        minWidth: 0,
        '& input, & textarea, & button, & [role="button"], & [role="combobox"], & .MuiSwitch-root, & .MuiChip-deleteIcon': {
          pointerEvents: 'none',
        },
      }}
    >
      {children}
    </Box>
  );
}

function Loading(): React.JSX.Element {
  return (
    <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
      <CircularProgress />
    </Box>
  );
}

// Automation: staff get a read-only view, admins full access
export function AutomationGuard({ children }: { children: React.ReactNode }): React.JSX.Element {
  const { loading, isStaff } = useAutomationAccess();
  if (loading) return <Loading />;
  if (!isStaff) return <Alert severity="warning">Automation is only available to staff.</Alert>;
  return <>{children}</>;
}

export function ReadOnlyBanner(): React.JSX.Element | null {
  const { readOnly } = useAutomationAccess();
  if (!readOnly) return null;
  return (
    <Alert severity="info">
      View only — you can see flows, document types, runs, review and usage, but only an admin can change automation.
    </Alert>
  );
}

// Compliance: full control for staff and admins
export function StaffGuard({ children }: { children: React.ReactNode }): React.JSX.Element {
  const { loading, isStaff } = useAutomationAccess();
  if (loading) return <Loading />;
  if (!isStaff) return <Alert severity="warning">This area is only available to staff.</Alert>;
  return <>{children}</>;
}

// Kept for any admin-only screen
export function AdminGuard({ children }: { children: React.ReactNode }): React.JSX.Element {
  const { loading, isAdmin } = useAutomationAccess();
  if (loading) return <Loading />;
  if (!isAdmin) return <Alert severity="warning">Only available to admins.</Alert>;
  return <>{children}</>;
}
