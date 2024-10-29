import { configureStore } from '@reduxjs/toolkit';
import rootReducer from '../slices';
import { apiSlice } from '../apiSlice';

const store = configureStore({
  reducer: {
    ...rootReducer,
    [apiSlice.reducerPath]: apiSlice.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(apiSlice.middleware),
});

export default store;
