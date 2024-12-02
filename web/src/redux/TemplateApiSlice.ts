
import { apiSlice } from './apiSlice';
import { UserProfile } from './models/ChannelModel';
import { MediaModel } from './models/MediaModel';
import { MessageModel } from './models/MessageModel';

export const TemplateApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getTemplates: builder.query<
      {
        status: boolean;
        message: string;
        data: {id:string, name: string; body:string,url?:string }[];
      },
      void
    >({

      query: (payload) => ({
        url: `template`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['templates'],
    }),

    createTemplate: builder.mutation<
      {
        status: boolean;
        message: string;

      },
      {name:string,body:string,url?:string}
    >({
      query: (payload) => ({
        url: 'template',
        method: 'POST',
        body: payload,
      }),

      invalidatesTags: ['templates'],
    }),
  }),
});

export const { useGetTemplatesQuery, useCreateTemplateMutation } = TemplateApiSlice;
