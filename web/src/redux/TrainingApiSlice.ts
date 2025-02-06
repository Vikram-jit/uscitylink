import { apiSlice } from './apiSlice';
import { pagination, UserProfile } from './models/ChannelModel';

export interface Training {
  id: string;
  title: string;
  description: string;
  file_name: string;
  file_type: any;
  thumbnail: string;
  file_size: string;
  mime_type: string;
  duration: any;
  key: string;
  createdAt: string;
  updatedAt: string;
  questions: Question[];
  assgin_drivers: assgin_drivers[];
}

export interface Question {
  id: string;
  tainingId: string;
  question: string;
  createdAt: string;
  updatedAt: string;
  options: Option[];
}

export interface Option {
  id: string;
  questionId: string;
  option: string;
  isCorrect: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface assgin_drivers {
  id: string;
  tainingId: string;
  driverId: string;
  view_duration: any;
  isCompleteWatch: boolean;
  quiz_status?:string
  createdAt: string;
  updatedAt: string;
  user_profiles?: UserProfile;
}

export interface assginDriver {
  data: {
    training: Training;
    drivers: assgin_drivers[];
  };
  pagination: pagination;
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
    addQuestions: builder.mutation<
      {
        status: boolean;
        message: string;
        data: any;
      },
      { questions: any; id: string; drivers: any; removedDrivers: any }
    >({
      query: (payload) => ({
        url: `trainings/add-questions/${payload.id}`,
        method: 'POST',
        body: payload,
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
    getAllTraining: builder.query<
      {
        status: boolean;
        message: string;
        data: { data: Training[]; pagination: pagination };
      },
      Partial<{ page: number }>
    >({
      providesTags: ['trainings'],
      query: (payload) => ({
        url: `trainings?page=${payload.page}`,
        method: 'GET',
      }),
    }),

    getAssginDriver: builder.query<
      {
        status: boolean;
        message: string;
        data: assginDriver;
      },
      Partial<{ id:string, page: number }>
    >({
      providesTags: ['assgin_drivers'],
      query: (payload) => ({
        url: `trainings/assgin-drivers/${payload.id}?page=${payload.page}`,
        method: 'GET',
      }),
    }),
  }),
});

export const { useGetAssginDriverQuery, useCreateTrainingMutation, useGetTrainingByIdQuery, useAddQuestionsMutation, useGetAllTrainingQuery } =
  TrainingApiSlice;
