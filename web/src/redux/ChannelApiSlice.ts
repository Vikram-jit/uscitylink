import { apiSlice } from './apiSlice';
import { ChannelModel, SingleChannelModel } from './models/ChannelModel';
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
    getActiveChannel: builder.query<
      {
        status: boolean;
        message: string;
        data: ChannelModel;
      },
      Partial<void>
    >({
      providesTags: ['channels'],
      query: () => ({
        url: 'channel/activeChannel',
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
    getChannelMembers: builder.query<
      {
        status: boolean;
        message: string;
        data: SingleChannelModel;
      },
      Partial<void>
    >({
      providesTags: ['channel',"members"],
      query: () => ({
        url: 'channel/members',
        method: 'GET',
      }),

    }),
    addMemberToChannel: builder.mutation<
      {
        status: boolean;
        message: string;

      },
      {ids:string[]}
    >({
      invalidatesTags: ['channel',"channelUsers"],
      query: (payload) => ({
        url: 'channel/addToChannel',
        method: 'POST',
        body:payload
      }),
    }),
  }),
});

export const { useGetChannelsQuery, useAddChannelMutation, useGetActiveChannelQuery, useGetChannelMembersQuery ,useAddMemberToChannelMutation} =
  ChannelApiSlice;
