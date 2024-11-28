import { createSlice, PayloadAction } from '@reduxjs/toolkit';

// Define initial state type
interface LoaderState {
  loading: boolean;
}

const initialState: LoaderState = {
  loading: false,
};

// Create the loader slice
const loaderSlice = createSlice({
  name: 'loader',
  initialState,
  reducers: {
    // Action to show the loader
    showLoader(state) {
      state.loading = true;
    },
    // Action to hide the loader
    hideLoader(state) {
      state.loading = false;
    },
  },
});

// Export the actions and reducer
export const { showLoader, hideLoader } = loaderSlice.actions;
export default loaderSlice.reducer;
