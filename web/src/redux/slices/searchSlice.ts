
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

// Define initial state type
interface SearchState {
  search: string;
}

const initialState: SearchState = {
  search: "",
};


const searchSlice = createSlice({
  name: 'search',
  initialState,
  reducers: {

    setSearch(state,action) {
      state.search = action.payload;
    },

  },
});

export const { setSearch } = searchSlice.actions;
export default searchSlice.reducer;
