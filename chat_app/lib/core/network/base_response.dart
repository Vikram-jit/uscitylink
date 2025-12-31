class BaseResponse<T> {
  final bool status;
  final String message;
  final T? data;

  BaseResponse({required this.status, required this.message, this.data});

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse(
      status: json["status"] ?? false,
      message: json["message"] ?? "",
      data: json["data"],
    );
  }
}

BaseResponse<List<T>> parseListResponse<T>(
  dynamic response,
  T Function(Map<String, dynamic>) fromJson,
) {
  return BaseResponse<List<T>>(
    status: response["status"] ?? false,
    message: response["message"] ?? "",
    data: response["data"] != null
        ? (response["data"] as List).map((item) => fromJson(item)).toList()
        : [],
  );
}
