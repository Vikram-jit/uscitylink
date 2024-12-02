import type { NavItemConfig } from '@/types/nav';
import { paths } from '@/paths';

export const navItems = [
  { key: 'overview', title: 'Overview', href: paths.dashboard.overview, icon: 'chart-pie' },
  { key: 'messages', title: 'Messages', href: paths.dashboard.messages, icon: 'chat' },
  { key: 'groups', title: 'Groups', href: paths.dashboard.groups, icon: 'users' },
  { key: 'truckgroup', title: 'Truck Groups', href: paths.dashboard.truck_group, icon: 'truck' },
  { key: 'templates', title: 'Templates', href: paths.dashboard.templates, icon: 'template' },

  { key: 'user', title: 'Users', href: `${paths.dashboard.users}/staff`, icon: 'user' , items:[{ key: 'user', title: 'Users', href: paths.dashboard.users, icon: 'user' ,}]},
  { key: 'driver', title: 'Drivers', href: `${paths.dashboard.users}/driver`, icon: 'user' , items:[{ key: 'user', title: 'Users', href: paths.dashboard.users, icon: 'user' ,}]},
  { key: 'channels', title: 'Channels', href: paths.dashboard.channels, icon: 'channels' },
  { key: 'channel Members', title: 'Channel Members', href: paths.channel.members, icon: 'users-four' },


  // { key: 'error', title: 'Error', href: paths.errors.notFound, icon: 'x-square' },
] satisfies NavItemConfig[];
