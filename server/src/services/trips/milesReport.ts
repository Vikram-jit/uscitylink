import { Op, QueryTypes } from "sequelize";
import { secondarySequelize } from "../../sequelize";
import { ChatLoad, ChatTrip, ChatTripStop } from "../../models/ChatTrip";
import { UserProfile } from "../../models/UserProfile";

// Miles by driver / by truck over a date range, from the legs they drove (each leg: one driver or a
// team, one truck, Samsara or typed miles). Driver pay reads the driver view, truck maintenance the
// truck view. A team leg counts in full for both drivers. Legs count when they ended in the range.

export interface MilesItem {
  legId: number;
  loadId: number | null;
  tripNo: string | null;
  invoiceNo: string | null;
  truck: string | null;
  drivers: string[];
  from: string;
  to: string;
  startedAt: Date | null;
  endedAt: Date | null;
  hours: number | null;
  miles: number | null;
  milesSource: string | null;
}

export interface MilesRow {
  key: string;
  name: string;
  legs: number;
  loads: number;
  miles: number;
  hours: number;
  /** Legs with no miles yet (Samsara missing) */
  missing: number;
  /** by=truck: who drove it · by=driver: which trucks */
  others: string[];
  items: MilesItem[];
}

const place = (s?: ChatTripStop) => (s ? [s.city, s.state].filter(Boolean).join(", ") || s.name || "—" : "—");

export async function milesReport(input: { by: "driver" | "truck"; from: Date; to: Date; q?: string }): Promise<{ rows: MilesRow[]; totals: { miles: number; legs: number; missing: number } }> {
  const legs = await ChatTrip.findAll({
    where: { status: { [Op.notIn]: ["cancelled"] }, ended_at: { [Op.between]: [input.from, input.to] } },
    include: [{ model: ChatTripStop, as: "stops" }],
    order: [["ended_at", "ASC"]],
  });
  const loadIds = [...new Set(legs.map((l) => l.load_id).filter(Boolean))] as number[];
  const invoices = new Map((loadIds.length ? await ChatLoad.findAll({ where: { id: loadIds } }) : []).map((l) => [Number(l.id), l.invoice_no]));
  const yardIds = [...new Set(legs.flatMap((l) => [l.driver_id_1, l.driver_id_2]).filter(Boolean).map(Number))];
  const yardNames = new Map(
    (yardIds.length
      ? await secondarySequelize.query<{ id: number; name: string }>(`SELECT id, name FROM drivers WHERE id IN (:ids)`, { replacements: { ids: yardIds }, type: QueryTypes.SELECT })
      : []
    ).map((r) => [Number(r.id), r.name])
  );
  const profileIds = [...new Set(legs.map((l) => l.driver_profile_id).filter(Boolean))] as string[];
  const profiles = new Map((profileIds.length ? await UserProfile.findAll({ where: { id: profileIds }, attributes: ["id", "username"] }) : []).map((p) => [p.id, p.username]));

  const rows = new Map<string, MilesRow>();
  const add = (key: string, name: string, item: MilesItem, other: string[]) => {
    const row = rows.get(key) || { key, name, legs: 0, loads: 0, miles: 0, hours: 0, missing: 0, others: [], items: [] };
    row.legs += 1;
    row.miles = Math.round((row.miles + (item.miles || 0)) * 10) / 10;
    row.hours = Math.round((row.hours + (item.hours || 0)) * 10) / 10;
    if (item.miles === null) row.missing += 1;
    for (const o of other) if (o && !row.others.includes(o)) row.others.push(o);
    row.items.push(item);
    row.loads = new Set(row.items.map((i) => i.loadId ?? -i.legId)).size;
    rows.set(key, row);
  };

  for (const l of legs) {
    const stops = [...(l.stops || [])].sort((a, b) => a.seq - b.seq);
    const drivers: { key: string; name: string }[] = [];
    if (l.driver_id_1) drivers.push({ key: `y${l.driver_id_1}`, name: yardNames.get(Number(l.driver_id_1)) || (l.driver_profile_id && profiles.get(l.driver_profile_id)) || "Driver" });
    else if (l.driver_profile_id) drivers.push({ key: `p${l.driver_profile_id}`, name: profiles.get(l.driver_profile_id) || "Driver" });
    if (l.driver_id_2) drivers.push({ key: `y${l.driver_id_2}`, name: yardNames.get(Number(l.driver_id_2)) || "Team driver" });
    const start = l.started_at ? new Date(l.started_at) : null;
    const end = l.ended_at ? new Date(l.ended_at) : null;
    const item: MilesItem = {
      legId: l.id,
      loadId: l.load_id,
      tripNo: l.trip_no,
      invoiceNo: (l.load_id ? invoices.get(Number(l.load_id)) : null) ?? l.invoice_no ?? null,
      truck: l.truck_number,
      drivers: drivers.map((d) => d.name),
      from: place(stops[0]),
      to: place(stops[stops.length - 1]),
      startedAt: start,
      endedAt: end,
      hours: start && end ? Math.round(((end.getTime() - start.getTime()) / 3600000) * 10) / 10 : null,
      miles: l.total_mileage !== null && l.total_mileage !== undefined ? Number(l.total_mileage) : null,
      milesSource: l.miles_source,
    };
    if (input.by === "truck") {
      const key = (l.truck_number || "").trim().toUpperCase();
      add(key || "—", key ? `Truck ${l.truck_number}` : "No truck", item, drivers.map((d) => d.name));
    } else {
      for (const d of drivers) add(d.key, d.name, item, l.truck_number ? [l.truck_number] : []);
    }
  }

  const q = (input.q || "").trim().toUpperCase();
  const list = [...rows.values()]
    .filter((r) => !q || r.name.toUpperCase().includes(q) || r.others.some((o) => o.toUpperCase().includes(q)))
    .sort((a, b) => b.miles - a.miles);
  return {
    rows: list,
    totals: {
      miles: Math.round(legs.reduce((a, l) => a + (Number(l.total_mileage) || 0), 0) * 10) / 10,
      legs: legs.length,
      missing: legs.filter((l) => l.total_mileage === null || l.total_mileage === undefined).length,
    },
  };
}
