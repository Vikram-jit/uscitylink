// The same rules as the server's load reader (server/src/services/trips/parseLoad.ts) and the web chat
// box: a message that looks like a load (addresses + PICKUP / DELIVERY) must carry its Load # so the
// server can make it a load (and the next leg when the number is used again).

final _cityStateZip = RegExp(r'^(.+?),?\s+([A-Za-z]{2})\.?,?\s*(\d{5})(?:-\d{4})?[.,]?$');
final _label = RegExp(r'^(?:pick(?:\s*-?\s*up)?|drop|delivery|deliver|del)\s*#?\s*\d*\s*:?\s*$', caseSensitive: false);
// LOAD / ORDER / TRIP / INVOICE (and LOAD ORDER) — "ORDER # 0056000" is a load id too
final _loadNo = RegExp(
  r'^(?:load\s+order|load|order|ord|trip|invoice|inv)(?:\s*(?:no\.?|id|number|num))?\s*[#:]+\s*([A-Za-z0-9][A-Za-z0-9-]*)\s*$|^(?:load\s+order|load|order|ord|trip|invoice|inv)\s+(?:no\.?|id|number|num)\s+([A-Za-z0-9][A-Za-z0-9-]*)\s*$',
  caseSensitive: false,
);

final _dateTime = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})\s+(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$');
final _switch = RegExp(r'^go\s+to\b', caseSensitive: false);

List<String> _lines(String t) => t.split(RegExp(r'\r?\n')).map((l) => l.trim()).toList();

// Words that mean a load / a stop anywhere in the text (same list as the server)
final _loadWords = RegExp(r'\b(?:pick\s*-?\s*ups?|pickups?|deliver(?:y|ies|ed|ing)?|del\s*#|drop(?:\s*-?\s*off)?s?|dropped|unload(?:ing)?|shipper|consignee|receiver|loads?|loaded)\b', caseSensitive: false);
final _street = RegExp(r"\b\d{1,6}\s+[A-Za-z0-9][A-Za-z0-9 .'-]*?\s(?:st|street|ave|avenue|rd|road|blvd|boulevard|dr|drive|hwy|highway|pkwy|parkway|ln|lane|way|ct|court|pl|place|cir|circle|fwy|freeway|pike|trl|trail|expy|expressway|ter|terrace|sq|loop)\b", caseSensitive: false);
// (capital state letters; states that are also words — OK, IN, ME, OR, HI, ID, OH — need a ZIP after)
final _cityState = RegExp(r"[A-Za-z][A-Za-z .'-]*,\s*([A-Z]{2})\b(\.?,?\s*\d{5})?");
const _wordStates = {'OK', 'IN', 'ME', 'OR', 'HI', 'ID', 'OH'};
const _usStates = {'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC'};

bool _hasPlace(String text, List<String> all) =>
    all.any((l) => _cityStateZip.hasMatch(l) || _street.hasMatch(l)) || _cityState.allMatches(text).any((m) => _usStates.contains(m.group(1)!) && (!_wordStates.contains(m.group(1)!) || m.group(2) != null));

/// An address plus any load word (pickup, delivery, drop, … anywhere, any format), or a PICKUP /
/// DELIVERY heading, an appointment time or a LOAD # line → a load: it must carry its Load #.
bool looksLikeLoad(String text) {
  final all = _lines(text);
  if (!_hasPlace(text, all)) return false;
  return _loadWords.hasMatch(text) || all.any((l) => _label.hasMatch(l) || _switch.hasMatch(l) || _dateTime.hasMatch(l) || _loadNo.hasMatch(l));
}

/// "LOAD # 1011" / "INVOICE #: 55-AB" → "1011" (PU# / PO# don't count)
String? loadNoIn(String text) {
  for (final l in _lines(text)) {
    final m = _loadNo.firstMatch(l);
    if (m != null) return (m.group(1) ?? m.group(2))!.toUpperCase();
  }
  return null;
}

/// A message that looks like a load but has no Load #: it can't be sent as a chat message.
bool loadMissingNo(String text) => looksLikeLoad(text) && loadNoIn(text) == null;
