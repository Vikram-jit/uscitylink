'use client';

import * as React from 'react';

import { useSocketEvent } from '@/hooks/use-socket-event';
import { LoadFeatures, useGetLoadFeaturesQuery } from '@/redux/TripApiSlice';

import { setLoadsFromChat } from './loadText';

// What every page sees until the server answers (the server's own defaults)
const DEFAULTS: LoadFeatures = {
  driver_loads: true,
  driver_buttons: true,
  driver_upcoming: true,
  driver_chat_lines: true,
  driver_chat_words: true,
  driver_paperwork: true,
  auto_send_next: true,
  loads_from_chat: false,
};

/** Settings → Loads switches, live: a change on the Settings page (any admin) reaches every open dashboard. */
export function useLoadFeatures(): LoadFeatures {
  const { data, refetch } = useGetLoadFeaturesQuery();
  const features = data?.data?.features || DEFAULTS;
  useSocketEvent('loads:features', () => void refetch());
  React.useEffect(() => setLoadsFromChat(features.loads_from_chat), [features.loads_from_chat]);
  return features;
}

/** Mounted once in the dashboard layout: keeps the chat boxes in step with the "Loads from chat" switch. */
export function LoadFeaturesSync(): null {
  useLoadFeatures();
  return null;
}
