import { apiSlice } from './apiSlice';

export type AppPlatform = 'android' | 'ios';
export type AppVersionStatus = 'pending' | 'active' | 'deprecated';

export interface AppVersion {
  id: string;
  version: string;
  buildNumber: number;
  platform: AppPlatform;
  status: AppVersionStatus;
  releaseNotes?: string | null;
  force_update: boolean; // users on an older build of this platform must update
  users: number; // logins whose last reported version + build match this row
  createdAt: string;
  updatedAt: string;
}

export type AppVersionInput = Pick<AppVersion, 'version' | 'buildNumber' | 'platform' | 'status'> & {
  id?: string;
  releaseNotes?: string | null;
  force_update?: boolean;
};

export interface InstallGroup {
  version: string;
  buildNumber: string;
  users: number;
  online: number;
  lastSeen: string | null;
  // status: null when this build was never added as an app version
  platforms: { platform: AppPlatform | null; users: number; status: AppVersionStatus | null }[];
}

export interface InstallUser {
  id: string;
  username: string | null;
  platform: string | null;
  version: string | null;
  buildNumber: string | null;
  appUpdate: string | null;
  isOnline: boolean;
  last_login: string | null;
  status: string | null;
  user?: { email: string | null; phone_number: string | null; driver_number: string | null };
  role?: { name: string };
}

export interface InstallUsersArgs {
  version?: string; // empty = logins that never reported a version
  buildNumber?: string;
  platform?: string; // android | ios | unknown
  withUnknown?: boolean;
  search?: string;
  page?: number;
  pageSize?: number;
}

interface Res<T> {
  status: boolean;
  message?: string;
  data: T;
}

export const AppVersionApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getAppVersions: builder.query<Res<{ versions: AppVersion[]; updatePending: number }>, void>({
      query: () => ({ url: 'app-versions', method: 'GET' }),
      providesTags: ['appVersions'],
    }),
    getInstalls: builder.query<Res<{ installs: InstallGroup[]; notReported: number }>, void>({
      query: () => ({ url: 'app-versions/installs', method: 'GET' }),
      providesTags: ['appVersions'],
    }),
    getInstallUsers: builder.query<Res<{ users: InstallUser[]; total: number; page: number; pageSize: number }>, InstallUsersArgs>({
      query: ({ withUnknown, ...args }) => ({
        url: 'app-versions/installs/users',
        method: 'GET',
        params: { ...args, ...(withUnknown ? { withUnknown: 1 } : {}) },
      }),
      providesTags: ['appVersions'],
    }),
    saveAppVersion: builder.mutation<Res<AppVersion>, Partial<AppVersionInput>>({
      query: ({ id, ...body }) => ({ url: id ? `app-versions/${id}` : 'app-versions', method: id ? 'PUT' : 'POST', body }),
      invalidatesTags: ['appVersions'],
    }),
    deleteAppVersion: builder.mutation<Res<null>, { id: string }>({
      query: ({ id }) => ({ url: `app-versions/${id}`, method: 'DELETE' }),
      invalidatesTags: ['appVersions'],
    }),
  }),
});

export const { useGetAppVersionsQuery, useGetInstallsQuery, useGetInstallUsersQuery, useSaveAppVersionMutation, useDeleteAppVersionMutation } = AppVersionApiSlice;
