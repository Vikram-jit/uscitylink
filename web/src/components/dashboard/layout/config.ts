import type { NavItemConfig } from '@/types/nav';
import { paths } from '@/paths';

export const navItems = [
  { key: 'overview', title: 'Overview', href: paths.dashboard.overview, icon: 'chart-pie' },
  { key: 'messages', title: 'Messages', href: paths.dashboard.messages, icon: 'chat' },
  // { key: 'customers', title: 'Customers', href: paths.dashboard.customers, icon: 'users' },
  // { key: 'integrations', title: 'Integrations', href: paths.dashboard.integrations, icon: 'plugs-connected' },
  // { key: 'settings', title: 'Settings', href: paths.dashboard.settings, icon: 'gear-six' },
  // { key: 'account', title: 'Account', href: paths.dashboard.account, icon: 'user' },
  { key: 'user', title: 'Users', href: paths.dashboard.users, icon: 'user' , items:[{ key: 'user', title: 'Users', href: paths.dashboard.users, icon: 'user' ,}]},
  { key: 'channels', title: 'Channels', href: paths.dashboard.channels, icon: 'channels' },
  { key: 'channel Members', title: 'Channel Members', href: paths.channel.members, icon: 'users-four' },
  { key: 'groups', title: 'Groups', href: paths.dashboard.groups, icon: 'users' },
  // { key: 'error', title: 'Error', href: paths.errors.notFound, icon: 'x-square' },
] satisfies NavItemConfig[];
