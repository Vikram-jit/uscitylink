class ApiResponse<T> {
  final T data;
  final String message;
  final bool status;

  ApiResponse({
    required this.data,
    required this.message,
    required this.status,
  });

  // Factory constructor to convert from JSON response
  factory ApiResponse.fromJson(Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonModel) {
    return ApiResponse<T>(
      data: fromJsonModel(json['data']),
      message: json['message'] ?? '',
      status: json['status'] ?? false,
    );
  }
}
