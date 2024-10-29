import { apiSlice } from './apiSlice';
import { ChannelModel } from './models/ChannelModel';
import { UserModel } from './models/UserModel';

export const ChannelApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getChannels: builder.query<
      {
        status: boolean;
        message: string;
        data: ChannelModel[];
      },
      Partial<void>
    >({
      providesTags: ['channels'],
      query: () => ({
        url: 'channel',
        method: 'GET',
      }),
    }),

    addChannel: builder.mutation<
      {
        name: string;
        description?: string;
      },
      Partial<any>
    >({
      invalidatesTags: ['channels'],
      query: (payload) => ({
        url: 'channel',
        method: 'POST',
        body: payload,
      }),
    }),
  }),
});

export const { useGetChannelsQuery,useAddChannelMutation } = ChannelApiSlice;
