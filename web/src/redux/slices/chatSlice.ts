import { createSlice, PayloadAction } from '@reduxjs/toolkit';

// Define initial state type
interface ChatState {
  open: boolean;
  id:string
}

const initialState: ChatState = {
    open: false,
    id:""
};

// Create the loader slice
const chatSlice = createSlice({
  name: 'chat',
  initialState,
  reducers: {
    // Action to show the loader
    openChat(state,action) {
      state.open = true;
      state.id = action.payload.id;
    },
    // Action to hide the loader
    closeChat(state) {
        state.open = false;
        state.id = "";
      },
    
  },
});

// Export the actions and reducer
export const { openChat, closeChat } = chatSlice.actions;
export default chatSlice.reducer;
