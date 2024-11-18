import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { SingleChannelModel } from '../models/ChannelModel'; // Assuming SingleChannelModel exists

// Define the state structure to include user_channels as an array
interface UserChannelState {
  userList: SingleChannelModel | null; // This can be null if no data is loaded
}

const initialState: UserChannelState = {
  userList: null, // Initialize userList as null
};

const userChannelSlice = createSlice({
  name: 'user_channels',
  initialState,
  reducers: {
    // Add or update the user list with user channels
    setUserList: (state, action) => {
      state.userList =  action.payload ;
    },

    // Action to update the message count and last message
    updateChannelMessage: (state, action: PayloadAction<{ userId: string, message: string }>) => {
      if (!state.userList) return;

      const { userId, message } = action.payload;

      // Check if userList has user_channels
      if (state.userList.user_channels) {
        const updatedUserChannels = state.userList.user_channels.map((channel) => {
          if (channel.userProfileId === userId) {
            // Increment the message count and update the last message
            return {
              ...channel,
              sent_message_count: channel.sent_message_count + 1,
              last_message: message,
            };
          }
          return channel;
        });

        // Sort the user channels to bring the updated channel to the front
        const updatedUserList:any = updatedUserChannels.sort((a, b) => {
          if (a.userProfileId === userId) return -1;
          if (b.userProfileId === userId) return 1;
          return 0;
        });

        // Update the userList with sorted channels
        state.userList.user_channels = updatedUserList;
      }
    },
  },
});

// Export the actions to be used in your components
export const { setUserList, updateChannelMessage } = userChannelSlice.actions;

// Export the reducer to be used in the store
export default userChannelSlice.reducer;
