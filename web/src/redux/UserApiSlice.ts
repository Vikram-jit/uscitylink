import { apiSlice } from "./apiSlice";
import { UserModel } from "./models/UserModel";

export const UserApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({

    getUsers: builder.query<{
      status:boolean,
      message:string,
      data:UserModel[]
    }, Partial<void>>({
      providesTags:['users'],
      query: () => ({
        url: 'user',
        method: 'GET',

      }),
    }),
  }),
});


export const {useGetUsersQuery} = UserApiSlice;
