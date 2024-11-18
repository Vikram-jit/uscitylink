import { configureStore } from '@reduxjs/toolkit';
import rootReducer from '../slices';
import { apiSlice } from '../apiSlice';
import messageReducer from '../slices/messageSlice';
import userChannelReducer from '../slices/userChannelSlice';

const store = configureStore({
  reducer: {
    ...rootReducer,
   message: messageReducer,
   UserChannel:userChannelReducer,
    [apiSlice.reducerPath]: apiSlice.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(apiSlice.middleware),
});

export default store;
