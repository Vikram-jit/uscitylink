import 'package:uscitylink/model/pagination_model.dart';
import 'package:uscitylink/model/security/security_entry_list_item.dart';

class SecurityEntriesPage {
  List<SecurityEntryListItem> entries;
  PaginationModel? pagination;

  SecurityEntriesPage({this.entries = const [], this.pagination});

  SecurityEntriesPage.fromJson(Map<String, dynamic> json)
      : entries = (json['entries'] as List<dynamic>? ?? [])
            .map((e) => SecurityEntryListItem.fromJson(e))
            .toList(),
        pagination = json['pagination'] != null
            ? PaginationModel.fromJson(json['pagination'])
            : null;
}
