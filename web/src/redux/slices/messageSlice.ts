import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { MessageModel } from '../models/MessageModel';

interface ExampleState {
  messages: MessageModel[];
}

const initialState: ExampleState = {
  messages: []
};

const messagesSlice = createSlice({
  name: 'messages',
  initialState,
  reducers: {
    updateMessageList: (state, action: PayloadAction<MessageModel[]>) => {
      // Append the new messages to the existing list
      state.messages.push(...action.payload);
    },
    addMessage: (state, action: PayloadAction<MessageModel>) => {
      state.messages.push(action.payload);
    },
  },
});

export const { updateMessageList,addMessage } = messagesSlice.actions;
export default messagesSlice.reducer;
