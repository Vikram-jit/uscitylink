import { ApiResponse, apiSlice } from './apiSlice';
import { pagination } from './models/ChannelModel';
import { DashboardModel } from './models/DashboardModel';
import { UserModel } from './models/UserModel';

export const UserApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getUsers: builder.query<
      {
        status: boolean;
        message: string;
        data: { users: UserModel[]; pagination: pagination };
      },
      Partial<{ role?: string; page: number; search?: string }>
    >({
      providesTags: ['users'],
      query: (payload) => ({
        url: `user?page=${payload.page}&search=${payload.search}`,
        method: 'GET',
        params: payload?.role ? { role: payload.role } : {},
      }),
    }),
    getUserById: builder.query<
      {
        status: boolean;
        message: string;
        data: UserModel;
      },
      Partial<{ id: string }>
    >({
      providesTags: ['users'],
      query: (payload) => ({
        url: `user/profile/${payload.id}`,
        method: 'GET',
      }),
    }),
    getDriverProfileById: builder.query<
    {
      status: boolean;
      message: string;
      data: {
        profile: UserModel;
        driver: any;
        documents: any[];
        incomeSummary: {
          totalTrips: number;
          totalIncome: number;
          totalDeductions: number;
          totalMileage: number;
        };
        trips: any[];
        pagination: {
          currentPage: number;
          pageSize: number;
          totalItems: number;
          totalPages: number;
        };
      };
    },
    { id: string; page?: number; pageSize?: number }
  >({
    providesTags: ['users'],
    query: ({ id, page = 1, pageSize = 10 }) => ({
      url: `user/driver-profile/${id}`,
      method: 'GET',
      params: { page, pageSize },
    }),
  }),

  getDriverDocumentUrl: builder.query<
  {
    status: boolean;
    message?: string;
    data: {
      url: string;
    };
  },
  {
    id: string;
    documentId: number;
  }
>({
  query: ({ id, documentId }) => ({
    url: `user/driver-profile/${id}/document/${documentId}`,
    method: 'GET',
  }),
}),
    getProfile: builder.query<
      {
        status: boolean;
        message: string;
        data: UserModel;
      },
      Partial<void>
    >({
      providesTags: ['users'],
      query: (payload) => ({
        url: `user/profile`,
        method: 'GET',
      }),
    }),
    genratePassword: builder.mutation<
      {
        status: boolean;
        message: string;
        data: UserModel;
      },
      Partial<{ id: string }>
    >({
      invalidatesTags: ['users'],
      query: (payload) => ({
        url: `user/genrate-password/${payload.id}`,
        method: 'POST',
      }),
    }),
    addUser: builder.mutation<ApiResponse, { email?: string; password?: string; role?: string; phone_number?: string }>(
      {
        invalidatesTags: ['users'],
        query: (newPost) => ({
          url: 'auth/register',
          method: 'POST',
          body: { ...newPost },
        }),
      }
    ),
    updateUser: builder.mutation<ApiResponse, { id?: string; username?: string; status?: string }>({
      invalidatesTags: ['users'],
      query: (newPost) => ({
        url: `user/update-profile-web/${newPost.id}`,
        method: 'PUT',
        body: { ...newPost },
      }),
    }),
    syncUser: builder.mutation<ApiResponse, any>({
      invalidatesTags: ['users'],
      query: (newPost) => ({
        url: 'auth/syncUser',
        method: 'POST',
      }),
    }),
    syncDriver: builder.mutation<ApiResponse, any>({
      invalidatesTags: ['users'],
      query: (newPost) => ({
        url: 'auth/syncDriver',
        method: 'POST',
      }),
    }),
    updateActiveChannel: builder.mutation<ApiResponse, { channelId: string }>({
      invalidatesTags: ['channels', 'groups', 'channel', 'channelUsers',"dashboard","media","members","trucks"],
      query: (newPost) => ({
        url: `user/updateActiveChannel`,
        method: 'PUT',
        body: { channelId: newPost?.channelId },
      }),
    }),
    updateDeviceToken: builder.mutation<ApiResponse, { device_token: string; platform: string }>({
      invalidatesTags: ['channels', 'groups', 'channel', 'channelUsers'],
      query: (newPost) => ({
        url: `user/updateDeviceToken`,
        method: 'PUT',
        body: { device_token: newPost?.device_token, platform: newPost?.platform },
      }),
    }),
    getUserWithoutChannel: builder.query<
      {
        status: boolean;
        message: string;
        data: UserModel[];
      },
      {type?:string}
    >({
      providesTags: ['channelUsers'],
      query: (payload) => ({
        url:  `user/drivers?type=${payload.type}`,
        method: 'GET',
      }),
    }),
    dashbaord: builder.query<
    {
      status: boolean;
      message: string;
      data: DashboardModel;
    },
    Partial<void>
  >({
    providesTags: ['dashboard'],
    query: () => ({
      url: 'user/dashboard-web',
      method: 'GET',
    }),
  }),
  }),
});

export const {
  useGenratePasswordMutation,
  useGetUsersQuery,
  useUpdateUserMutation,
  useAddUserMutation,
  useGetUserByIdQuery,
  useGetDriverProfileByIdQuery,
  useLazyGetDriverDocumentUrlQuery,
  useUpdateActiveChannelMutation,
  useGetUserWithoutChannelQuery,
  useSyncDriverMutation,
  useSyncUserMutation,
  useUpdateDeviceTokenMutation,
  useGetProfileQuery,
  useDashbaordQuery,
  
} = UserApiSlice;
