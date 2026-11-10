'use client';

import 'leaflet/dist/leaflet.css';

import * as React from 'react';
import L from 'leaflet';
import { MapContainer, Marker, Polyline, TileLayer, Tooltip, useMap } from 'react-leaflet';

import type { LiveStopEta, LiveTruck } from '@/redux/TripApiSlice';

// The trip panel's map (Leaflet + OpenStreetMap tiles, no key in the browser): the road ahead from
// Google, the truck where Samsara last saw it, and the remaining stops. Loaded only in the browser
// (TripLivePanel imports it with next/dynamic).

const truckColor = (t: LiveTruck) => ((t.speedMph || 0) > 3 ? '#16a34a' : t.engine === 'On' || t.engine === 'Idle' ? '#f59e0b' : '#64748b');

function truckIcon(t: LiveTruck) {
  const color = truckColor(t);
  const rotate = t.headingDegrees ?? 0;
  return L.divIcon({
    className: '',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    html: `<div style="width:36px;height:36px;border-radius:50%;background:${color};border:3px solid #fff;box-shadow:0 2px 8px rgba(0,0,0,.35);display:flex;align-items:center;justify-content:center">
      <svg width="18" height="18" viewBox="0 0 24 24" style="transform:rotate(${rotate}deg)"><path d="M12 2 20 21 12 17 4 21z" fill="#fff"/></svg>
    </div>`,
  });
}

function stopIcon(s: LiveStopEta, n: number) {
  const late = (s.lateMinutes ?? -1) > 0;
  const bg = s.type === 'pickup' ? '#2563eb' : late ? '#dc2626' : '#0f172a';
  return L.divIcon({
    className: '',
    iconSize: [30, 30],
    iconAnchor: [15, 30],
    html: `<div style="width:30px;height:30px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);background:${bg};border:2px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,.35);display:flex;align-items:center;justify-content:center">
      <span style="transform:rotate(45deg);color:#fff;font:600 12px system-ui">${s.type === 'pickup' ? 'P' : 'D'}${n}</span>
    </div>`,
  });
}

/** Zoom to fit the truck, the route and the stops (once, and again when the trip changes). */
function FitAll({ points, fitKey }: { points: [number, number][]; fitKey: string }) {
  const map = useMap();
  React.useEffect(() => {
    if (!points.length) return;
    if (points.length === 1) map.setView(points[0], 9);
    else map.fitBounds(L.latLngBounds(points), { padding: [28, 28], maxZoom: 12 });
    // eslint-disable-next-line react-hooks/exhaustive-deps -- refit only for a different trip / route
  }, [map, fitKey]);
  return null;
}

export default function TripMap({
  truck,
  stops,
  path,
  fitKey,
}: {
  truck: LiveTruck | null;
  stops: LiveStopEta[];
  path: [number, number][];
  fitKey: string;
}): React.JSX.Element {
  const located = stops.filter((s) => s.lat !== null && s.lng !== null);
  const points: [number, number][] = [
    ...(truck ? [[truck.lat, truck.lng] as [number, number]] : []),
    ...located.map((s) => [s.lat!, s.lng!] as [number, number]),
    ...path.filter((_, i) => i % 10 === 0),
  ];
  const center: [number, number] = points[0] || [39.5, -98.35];

  return (
    <MapContainer center={center} zoom={4} scrollWheelZoom style={{ height: 320, width: '100%', borderRadius: 12 }}>
      <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>' url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
      {path.length > 1 && (
        <>
          <Polyline positions={path} pathOptions={{ color: '#ffffff', weight: 8, opacity: 0.9 }} />
          <Polyline positions={path} pathOptions={{ color: '#2563eb', weight: 5 }} />
        </>
      )}
      {located.map((s, i) => (
        <Marker key={s.stopId} position={[s.lat!, s.lng!]} icon={stopIcon(s, i + 1)}>
          <Tooltip direction="top" offset={[0, -28]}>
            {s.name || s.place} · {s.place}
          </Tooltip>
        </Marker>
      ))}
      {truck && (
        <Marker position={[truck.lat, truck.lng]} icon={truckIcon(truck)} zIndexOffset={1000}>
          <Tooltip direction="top" offset={[0, -16]}>
            Truck {truck.vehicleName || ''} · {truck.address || ''}
          </Tooltip>
        </Marker>
      )}
      <FitAll points={points} fitKey={fitKey} />
    </MapContainer>
  );
}
