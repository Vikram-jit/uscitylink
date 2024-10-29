"use client"

import store from '@/redux/store';
import React from 'react'
import { Provider } from 'react-redux';

export interface StoreProviderProps {
  children: React.ReactNode;
}


export default function StoreProvider({ children }: StoreProviderProps): React.JSX.Element {
  return (
    <Provider store={store}>{children}</Provider>
  )
}
