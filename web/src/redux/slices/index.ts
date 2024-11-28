import { combineReducers } from 'redux';
import messageReducer from './messageSlice'; // Import your slices
import loaderReducer from './loaderSlice'; // Import your slices

const rootReducer = combineReducers({

  messages:messageReducer,
  loader:loaderReducer
  // Add other reducers here
});

export type RootState = ReturnType<typeof rootReducer>;
export default rootReducer;
