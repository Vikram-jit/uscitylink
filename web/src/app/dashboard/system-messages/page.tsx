import { config } from '@/config';
import SystemMessageList from '@/components/dashboard/system-messages/SystemMessageList';

export const metadata = { title: `System Messages | Dashboard | ${config.site.name}` };

export default function Page(): React.JSX.Element {
  return <SystemMessageList />;
}
