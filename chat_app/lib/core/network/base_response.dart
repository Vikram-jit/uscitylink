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
