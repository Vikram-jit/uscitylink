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
// The text below must stay identical to the server's LOAD_TEMPLATE and the web's loadFormat.ts
// (server/scripts/trips/format.check.ts compares the three).

const String kLoadTemplate = 'LOAD #\n\nTRUCK #\n\nTEAM #\n\nTRAILER #\n\nTEMP #\n\nPICKUP\nPENDING\n\nDROP\nPENDING';

const String kLoadFormatName = 'Load format';
const String kLoadFormatHint =
    'Fill in the LOAD # (required). Pickup and drop are each optional — leave PENDING until confirmed; a pending pickup or drop is not sent to the driver. One address with no PICKUP / DROP line is the drop.';
