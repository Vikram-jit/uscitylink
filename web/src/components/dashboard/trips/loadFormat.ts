// THE load pattern every dispatcher follows — for the driver's chat and for truck chats. The server writes
// loads in exactly this layout (server/src/services/trips/tripMessages.ts formatLoad) and reads it back
// (parseLoad). Only the LOAD # is required; the pickup and the drop are each optional, and a place or a
// date that is not confirmed yet is written PENDING. A pending pickup or drop is left out of the message the
// driver gets (a known place with no date shows DATE PENDING).
//
//   LOAD # 0056000
//
//   TRUCK # 35865
//
//   TEAM # ABBY + AMIT
//
//   TRAILER # 107065
//
//   TEMP # 34 CONT.
//
//   PICKUP
//   PENDING
//
//   DROP
//   FreshPoint Atlanta
//   1200 Oakley Industrial Blvd B
//   FAIRBURN, GA 30213
//   11/16/2026 06:00AM        (or DATE PENDING)
//
// One address with no PICKUP / DROP line is the DROP; the pickup stays empty.
// The text below must stay identical to the server's LOAD_TEMPLATE and the app's load_format.dart
// (server/scripts/trips/format.check.ts compares the three).

export const LOAD_TEMPLATE = ['LOAD #', '', 'TRUCK #', '', 'TEAM #', '', 'TRAILER #', '', 'TEMP #', '', 'PICKUP', 'PENDING', '', 'DROP', 'PENDING'].join('\n');

/** Shown in the Templates list on top of the saved templates. */
export const LOAD_FORMAT_TEMPLATE = {
  id: 'load-format',
  name: 'Load format',
  body: LOAD_TEMPLATE,
  hint: 'Fill in the LOAD # (required). Pickup and drop are each optional — leave PENDING until confirmed; a pending pickup or drop is not sent to the driver. One address with no PICKUP / DROP line is the drop.',
};
