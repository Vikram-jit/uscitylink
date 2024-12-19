import { pagination } from '@/redux/models/ChannelModel';

import { apiSlice } from './apiSlice';

export const TemplateApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getTemplates: builder.query<
      {
        status: boolean;
        message: string;
        data: { data: { id: string; name: string; body: string; url?: string }[]; pagination: pagination };
      },
      { page: number; search?: string,source:string }
    >({
      query: (payload) => ({
        url: `template?page=${payload.page}&search=${payload.search}&source=${payload.source}`,
        method: 'GET',
      }),
      keepUnusedDataFor: 0,
      providesTags: ['templates'],
    }),
    getTemplateById: builder.query<
    {
      status: boolean;
      message: string;
      data: { id: string; name: string; body: string; url?: string};
    },
    { id:string }
  >({
    query: (payload) => ({
      url: `template/${payload.id}`,
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
      { name: string; body: string; url?: string }
    >({
      query: (payload) => ({
        url: 'template',
        method: 'POST',
        body: payload,
      }),

      invalidatesTags: ['templates'],
    }),
    deleteTemplate: builder.mutation<
      {
        status: boolean;
        message: string;
      },
      { id: string }
    >({
      query: (payload) => ({
        url: `template/${payload.id}`,
        method: 'DELETE',
        body: payload,
      }),

      invalidatesTags: ['templates'],
    }),
    updateTemplate: builder.mutation<
    {
      status: boolean;
      message: string;

    },
    {id:string,name: string; body: string; url?: string}
  >({
    query: (payload) => ({
      url: `template/${payload.id}`,
      method: 'PUT',
      body: payload,
    }),

    invalidatesTags: ['templates'],
  }),
  }),
});

export const { useGetTemplatesQuery, useCreateTemplateMutation, useDeleteTemplateMutation,useUpdateTemplateMutation,useGetTemplateByIdQuery } = TemplateApiSlice;
