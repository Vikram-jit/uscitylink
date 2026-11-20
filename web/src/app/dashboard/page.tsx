import { redirect } from 'next/navigation';

import { paths } from '@/paths';

// "/dashboard" has no page of its own (old bookmarks, the site root): open the overview.
export default function Page(): never {
  redirect(paths.dashboard.overview);
}
