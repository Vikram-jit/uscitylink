import { createSlice } from '@reduxjs/toolkit';

interface ExampleState {
  trackChannelState:number
}

const initialState: ExampleState = {
  trackChannelState: 0
};

const channelSlice = createSlice({
  name: 'channel',
  initialState,
  reducers: {
    updateChannelState: (state) => {

      state.trackChannelState += 1
    },

  },
});

export const { updateChannelState } = channelSlice.actions;
export default channelSlice.reducer;
