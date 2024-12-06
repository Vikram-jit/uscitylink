import { configureStore } from '@reduxjs/toolkit';
import rootReducer from '../slices';
import { apiSlice } from '../apiSlice';
import messageReducer from '../slices/messageSlice';
import userChannelReducer from '../slices/userChannelSlice';
import loaderReducer from '../slices/loaderSlice';
import searchReducer from '../slices/searchSlice';

const store = configureStore({
  reducer: {
    ...rootReducer,
   UserChannel:userChannelReducer,
   message: messageReducer,
   loader: loaderReducer,
    search:searchReducer,
    [apiSlice.reducerPath]: apiSlice.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(apiSlice.middleware),
});

export default store;
