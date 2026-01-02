class PaginationModel {
  int? currentPage;
  int? pageSize;
  int? total;
  int? totalPages;

  PaginationModel({
    this.currentPage,
    this.pageSize,
    this.total,
    this.totalPages,
  });

  PaginationModel.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
    total = json['total'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['pageSize'] = this.pageSize;
    data['total'] = this.total;
    data['totalPages'] = this.totalPages;
    return data;
  }
}
