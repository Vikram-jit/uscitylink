import { combineReducers } from 'redux';
import messageReducer from './messageSlice'; // Import your slices
import loaderReducer from './loaderSlice'; // Import your slices
import chatReducer from './chatSlice'; // Import your slices
import searchReducer from './searchSlice'; // Import your slices
import channelReducer from './channelSlice'; // Import your slices

const rootReducer = combineReducers({

  messages:messageReducer,
  loader:loaderReducer,
  search:searchReducer,
  channel:channelReducer,
  chat:chatReducer
  // Add other reducers here
});

export type RootState = ReturnType<typeof rootReducer>;
export default rootReducer;
