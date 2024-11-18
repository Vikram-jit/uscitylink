import { combineReducers } from 'redux';
import messageReducer from './messageSlice'; // Import your slices

const rootReducer = combineReducers({

  messages:messageReducer
  // Add other reducers here
});

export type RootState = ReturnType<typeof rootReducer>;
export default rootReducer;
