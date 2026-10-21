export const paths = {
  home: '/',
  auth: { signIn: '/auth/sign-in', signUp: '/auth/sign-up', resetPassword: '/auth/reset-password' },
  dashboard: {
    overview: '/dashboard/overview',
    account: '/dashboard/account',
    customers: '/dashboard/customers',
    integrations: '/dashboard/integrations',
    settings: '/dashboard/settings',
    users: '/dashboard/users',

    channels: '/dashboard/channels',
    groups: '/dashboard/groups',
    messages: '/dashboard/messages',
    truck_group: '/dashboard/truckgroup',
    truck_chat: '/dashboard/truck-chat',
    broadcast_messages: '/dashboard/broadcast-messages',
    templates: '/dashboard/templates',
    trainings: '/dashboard/trainings',
    staff_chat: '/dashboard/staff_chat',
    system_messages: '/dashboard/system-messages',
    automation: '/dashboard/automation',
  },
  user:{
    "add":'/dashboard/users/add'
  },
  template:{
    "add":'/dashboard/templates/add',
    "edit":'/dashboard/templates/edit'
  },
  channel:{
    "members":'/dashboard/channels/members'
  },
  compliance: {
    scaleChecks: '/dashboard/compliance/scale-checks',
    equipment: '/dashboard/compliance/equipment',
  },
  automation: {
    flows: '/dashboard/automation/flows',
    docTypes: '/dashboard/automation/doc-types',
    runs: '/dashboard/automation/runs',
    review: '/dashboard/automation/review',
    usage: '/dashboard/automation/usage',
    settings: '/dashboard/automation/settings',
  },
  errors: { notFound: '/errors/not-found' },
} as const;
