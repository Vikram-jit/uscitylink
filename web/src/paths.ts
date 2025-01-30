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
    templates: '/dashboard/templates',
    trainings: '/dashboard/trainings',
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
  errors: { notFound: '/errors/not-found' },
} as const;
