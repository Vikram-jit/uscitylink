import { apiSlice } from './apiSlice';

export interface Training {
  ETag: string;
  ServerSideEncryption: string;
  Location: string;
  key: string;
  Key: string;
  Bucket: string;
  thumbnail: string;
  id: string;
  title: string;
  description: string;
  file_name: string;
  file_size: number;
  mime_type: string;
  updatedAt: string;
  createdAt: string;
}

export const TrainingApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    createTraining: builder.mutation<
      {
        status: boolean;
        message: string;
        data: any;
      },
      { formData: FormData }
    >({
      query: (formData) => ({
        url: `trainings`,
        method: 'POST',
        body: formData.formData,
        formData: true,
      }),

      invalidatesTags: ['trainings'],
    }),
    getTrainingById: builder.query<
      {
        status: boolean;
        message: string;
        data: Training;
      },
      Partial<{ id: string }>
    >({
      providesTags: ['trainings'],
      query: (payload) => ({
        url: `trainings/${payload.id}`,
        method: 'GET',
      }),
    }),
  }),
});

export const { useCreateTrainingMutation,useGetTrainingByIdQuery } = TrainingApiSlice;
