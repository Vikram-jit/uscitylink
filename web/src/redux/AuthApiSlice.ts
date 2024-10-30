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

  }),
});


export const {useLoginMutation} = AuthApiSlice;
