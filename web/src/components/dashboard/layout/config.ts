import type { NavItemConfig } from '@/types/nav';
import { paths } from '@/paths';

export const navItems = [
  { key: 'overview', title: 'Overview', href: paths.dashboard.overview, icon: 'chart-pie' ,badge:false},
  { key: 'messages', title: 'Messages', href: paths.dashboard.messages, icon: 'chat',badge:true },
  { key: 'groups', title: 'Groups', href: paths.dashboard.groups, icon: 'users',badge:true },
  { key: 'truckgroup', title: 'Truck Groups', href: paths.dashboard.truck_group, icon: 'truck',badge:false },
  { key: 'templates', title: 'Templates', href: paths.dashboard.templates, icon: 'template',badge:false },

  { key: 'user', title: 'Users', href: `${paths.dashboard.users}/staff`, icon: 'user' ,badge:false, items:[{ key: 'user', title: 'Users', href: paths.dashboard.users, icon: 'user' ,badge:false}]},
  { key: 'driver', title: 'Drivers', href: `${paths.dashboard.users}/driver`, icon: 'user' ,badge:false, items:[{badge:false, key: 'user', title: 'Users', href: paths.dashboard.users, icon: 'user' ,}]},
  { key: 'channels', title: 'Channels', href: paths.dashboard.channels, icon: 'channels',badge:false },
  { key: 'channel Members', title: 'Channel Members', href: paths.channel.members, icon: 'users-four',badge:false },
  { key: 'training', title: 'Training Section', href: paths.dashboard.trainings, icon: 'users-four',badge:false },
  { key: 'staff chat', title: 'Staff Chat', href: paths.dashboard.staff_chat, icon: 'chat',badge:true },


  // { key: 'error', title: 'Error', href: paths.errors.notFound, icon: 'x-square' },
] satisfies NavItemConfig[];
