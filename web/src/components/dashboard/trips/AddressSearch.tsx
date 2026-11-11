'use client';

import * as React from 'react';
import { StopInput, useLazyGetStopPlaceQuery, useLazySearchStopPlacesQuery } from '@/redux/TripApiSlice';
import { TravelExplore } from '@mui/icons-material';
import { Autocomplete, CircularProgress, InputAdornment, Stack, TextField, Typography } from '@mui/material';
import { toast } from 'react-toastify';

// Search a customer or an address with Google ("SYSCO FREMONT", "609 Dacetown Rd") and pick it: the
// stop's name, street, city, state and ZIP fill in (still editable). Through the server, which keeps
// the Google key; one session per search so Google bills it as one lookup.

type Guess = { placeId: string; main: string; secondary: string };

const newSession = () =>
  typeof crypto !== 'undefined' && 'randomUUID' in crypto ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`;

export function AddressSearch({ onPick }: { onPick: (patch: Partial<StopInput>) => void }): React.JSX.Element {
  const [input, setInput] = React.useState('');
  const [options, setOptions] = React.useState<Guess[]>([]);
  const [session, setSession] = React.useState(newSession);
  const [search, { isFetching }] = useLazySearchStopPlacesQuery();
  const [details, { isFetching: loading }] = useLazyGetStopPlaceQuery();

  // Ask Google after typing stops
  React.useEffect(() => {
    const q = input.trim();
    if (q.length < 3) {
      setOptions([]);
      return;
    }
    const t = setTimeout(() => {
      search({ q, session }, true)
        .unwrap()
        .then((r) => setOptions(r.data || []))
        .catch((err) => {
          setOptions([]);
          if (err?.data?.message) toast.error(err.data.message);
        });
    }, 300);
    return () => clearTimeout(t);
  }, [input, session, search]);

  const pick = async (g: Guess | null) => {
    if (!g) return;
    try {
      const p = (await details({ placeId: g.placeId, session }).unwrap()).data;
      onPick({
        // A business fills the stop name; a plain street address keeps the name dispatch typed
        ...(p.name ? { name: p.name } : {}),
        street: p.street || '',
        city: p.city || '',
        state: p.state || '',
        zip: p.zip || '',
      });
      setInput('');
      setOptions([]);
      setSession(newSession());
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not read that address');
    }
  };

  return (
    <Autocomplete
      size="small"
      options={options}
      filterOptions={(x) => x}
      getOptionLabel={(o) => (typeof o === 'string' ? o : `${o.main}, ${o.secondary}`)}
      inputValue={input}
      onInputChange={(_, v, reason) => reason === 'input' && setInput(v)}
      onChange={(_, v) => void pick(v as Guess | null)}
      value={null}
      loading={isFetching}
      noOptionsText={input.trim().length < 3 ? 'Type a customer or an address' : 'No match'}
      renderOption={(props, o) => (
        <li {...props} key={o.placeId}>
          <Stack>
            <Typography variant="body2" fontWeight={600}>
              {o.main}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {o.secondary}
            </Typography>
          </Stack>
        </li>
      )}
      renderInput={(params) => (
        <TextField
          {...params}
          placeholder="Search a customer or address (Google)"
          inputProps={{ ...params.inputProps, 'data-testid': 'addressSearch' }}
          InputProps={{
            ...params.InputProps,
            startAdornment: (
              <InputAdornment position="start">
                {loading ? <CircularProgress size={16} /> : <TravelExplore fontSize="small" color="action" />}
              </InputAdornment>
            ),
          }}
        />
      )}
    />
  );
}
