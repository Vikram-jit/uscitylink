import { apiSlice } from "./apiSlice";

export const AuthApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({

    login: builder.mutation<{email:string,password:string}, Partial<any>>({
      invalidatesTags:['profile'],
      query: (newPost) => ({
        url: 'auth/loginWithWeb',
        method: 'POST',
        body: {...newPost},
      }),
    }),
    loginWithToken: builder.query<
      {
        status: boolean;
        message: string;
        data: any;
      },
      {token:string}
    >({
      providesTags: ['trucks'],
      query: (payload) => ({
        url: `auth/loginWithToken/${payload.token}`,
        method: 'GET',
      }),
    }),
  }),
});


export const {useLoginMutation,useLoginWithTokenQuery} = AuthApiSlice;
