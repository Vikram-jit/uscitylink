import { ChannelModel, pagination } from '@/redux/models/ChannelModel';
import { ApiResponse, apiSlice } from './apiSlice';
import { GroupModel, SingleGroupModel } from './models/GroupModel';
import { TruckModel } from './models/TruckModel';

export const TruckChatApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getTruckGroups: builder.query<
      {
        status: boolean;
        message: string;
        data: {data:GroupModel[],pagination:pagination,channel:ChannelModel};
      },
      Partial<{ type: string,page:number,search?:string }>
    >({
      providesTags: ['truck-groups'],
      query: (payload) => ({
        url: `group/truck-groups?page=${payload.page}&search=${payload.search}`,
        method: 'GET',
        params: payload?.type ? { type: payload.type } : {},
      }),
    }),
   
  }),
});

export const {
  useGetTruckGroupsQuery,
  
} = TruckChatApiSlice;
