import { combineReducers } from 'redux';
import exampleReducer from './exampleSlice'; // Import your slices

const rootReducer = combineReducers({
  example: exampleReducer,
  // Add other reducers here
});

export type RootState = ReturnType<typeof rootReducer>;
export default rootReducer;
