class PaginationModel {
  int? currentPage;
  int? pageSize;
  int? totalPages;
  int? totalItems;

  PaginationModel(
      {this.currentPage, this.pageSize, this.totalPages, this.totalItems});

  PaginationModel.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['pageSize'] = this.pageSize;
    data['totalPages'] = this.totalPages;
    data['totalItems'] = this.totalItems;
    return data;
  }
}
