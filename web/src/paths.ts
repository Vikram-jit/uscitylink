export const paths = {
  home: '/',
  auth: { signIn: '/auth/sign-in', signUp: '/auth/sign-up', resetPassword: '/auth/reset-password' },
  dashboard: {
    overview: '/dashboard',
    account: '/dashboard/account',
    customers: '/dashboard/customers',
    integrations: '/dashboard/integrations',
    settings: '/dashboard/settings',
    users: '/dashboard/users',

    channels: '/dashboard/channels',
    groups: '/dashboard/groups',
    messages: '/dashboard/messages',
  },
  user:{
    "add":'/dashboard/users/add'
  },
  channel:{
    "members":'/dashboard/channels/members'
  },
  errors: { notFound: '/errors/not-found' },
} as const;
