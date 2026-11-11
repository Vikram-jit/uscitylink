// Google Places for load stops (Add load / Edit leg): dispatch types a customer or an address
// ("SYSCO FREMONT", "609 Dacetown Rd") and picks it — the stop's name, street, city, state (2 letters)
// and ZIP fill in. The key stays on the server (GOOGLE_PLACES_API_KEY). A session token ties the
// typing and the pick together so Google bills one lookup.

const KEY = () => process.env.GOOGLE_PLACES_API_KEY || "";

export interface PlaceGuess {
  placeId: string;
  main: string;
  secondary: string;
}

export interface PlaceStop {
  name: string | null;
  street: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
  lat: number | null;
  lng: number | null;
}

export class PlacesError extends Error {}

export async function searchPlaces(q: string, session?: string): Promise<PlaceGuess[]> {
  const input = q.trim();
  if (input.length < 3) return [];
  if (!KEY()) throw new PlacesError("Google address search isn't set up on the server");
  const url = new URL("https://maps.googleapis.com/maps/api/place/autocomplete/json");
  url.searchParams.set("input", input);
  // Businesses and addresses, North America (loads cross into Canada / Mexico)
  url.searchParams.set("components", "country:us|country:ca|country:mx");
  if (session) url.searchParams.set("sessiontoken", session);
  url.searchParams.set("key", KEY());
  const json: any = await (await fetch(url)).json();
  if (json.status !== "OK" && json.status !== "ZERO_RESULTS") {
    throw new PlacesError(`Google address search failed (${json.status}${json.error_message ? `: ${json.error_message}` : ""})`);
  }
  return (json.predictions || []).slice(0, 8).map((p: any) => ({
    placeId: p.place_id,
    main: p.structured_formatting?.main_text || p.description,
    secondary: p.structured_formatting?.secondary_text || "",
  }));
}

/** "Sysco San Francisco - Food Distributor & Restaurant Supplies" → "SYSCO SAN FRANCISCO" */
const shortName = (name: string) => {
  const cut = name.length > 30 ? name.split(/\s[-–|]\s/)[0] : name;
  return cut.trim().toUpperCase();
};

/** Google's address parts → a stop. A business keeps its name; a plain address has none. */
export function stopFromPlace(result: any): PlaceStop {
  const parts: any[] = result?.address_components || [];
  const get = (type: string, short = false) => {
    const c = parts.find((x) => (x.types || []).includes(type));
    return c ? (short ? c.short_name : c.long_name) : null;
  };
  const street = [get("street_number"), get("route")].filter(Boolean).join(" ") || null;
  const isBusiness = (result?.types || []).some((t: string) => ["establishment", "point_of_interest", "premise"].includes(t));
  return {
    name: isBusiness && result?.name && result.name !== street ? shortName(String(result.name)) : null,
    street: street ? street.toUpperCase() : null,
    city: (get("locality") || get("sublocality") || get("postal_town") || get("administrative_area_level_3"))?.toUpperCase() || null,
    state: get("administrative_area_level_1", true),
    zip: get("postal_code"),
    lat: result?.geometry?.location?.lat ?? null,
    lng: result?.geometry?.location?.lng ?? null,
  };
}

export async function placeStop(placeId: string, session?: string): Promise<PlaceStop> {
  if (!placeId) throw new PlacesError("Pick an address");
  if (!KEY()) throw new PlacesError("Google address search isn't set up on the server");
  const url = new URL("https://maps.googleapis.com/maps/api/place/details/json");
  url.searchParams.set("place_id", placeId);
  url.searchParams.set("fields", "name,types,address_components,geometry");
  if (session) url.searchParams.set("sessiontoken", session);
  url.searchParams.set("key", KEY());
  const json: any = await (await fetch(url)).json();
  if (json.status !== "OK") throw new PlacesError(`Google couldn't read that place (${json.status})`);
  return stopFromPlace(json.result);
}

/** A point (the truck's GPS) → the nearest address as a stop. Google Geocoding; null when it can't. */
export async function placeAt(lat: number, lng: number): Promise<PlaceStop | null> {
  if (!KEY()) return null;
  const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
  url.searchParams.set("latlng", `${lat},${lng}`);
  url.searchParams.set("key", KEY());
  try {
    const json: any = await (await fetch(url)).json();
    if (json.status !== "OK" || !json.results?.length) return null;
    // The first result with a city is the useful one (the very first can be a highway segment)
    const best = json.results.find((r: any) => (r.address_components || []).some((c: any) => (c.types || []).includes("locality"))) || json.results[0];
    return { ...stopFromPlace({ ...best, types: [] }), lat, lng };
  } catch {
    return null;
  }
}
