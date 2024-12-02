import type { Icon } from '@phosphor-icons/react/dist/lib/types';
import { Chat, Wrench } from '@phosphor-icons/react/dist/ssr';
import { ChartPie as ChartPieIcon } from '@phosphor-icons/react/dist/ssr/ChartPie';
import { GearSix as GearSixIcon } from '@phosphor-icons/react/dist/ssr/GearSix';
import { PlugsConnected as PlugsConnectedIcon } from '@phosphor-icons/react/dist/ssr/PlugsConnected';
import { User as UserIcon } from '@phosphor-icons/react/dist/ssr/User';
import { Users as UsersIcon } from '@phosphor-icons/react/dist/ssr/Users';
import { XSquare } from '@phosphor-icons/react/dist/ssr/XSquare';
import { UsersFour } from '@phosphor-icons/react/dist/ssr/UsersFour';
import { Truck } from '@phosphor-icons/react/dist/ssr/Truck';
import { ToiletPaper } from '@phosphor-icons/react/dist/ssr/ToiletPaper';

export const navIcons = {
  'chart-pie': ChartPieIcon,
  'gear-six': GearSixIcon,
  'plugs-connected': PlugsConnectedIcon,
  'x-square': XSquare,
  user: UserIcon,
  users: UsersIcon,
  channels:Wrench,
  chat:Chat,
  truck:Truck,
  'users-four':UsersFour,
  'template':ToiletPaper
} as Record<string, Icon>;
