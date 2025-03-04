import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/truck_model.dart';
import 'package:uscitylink/model/vehicle_model.dart';

class PayModel {
  List<Pay>? data;
  Pagination? pagination;
  double? totalAmount;
  PayModel({this.data, this.pagination, this.totalAmount});

  PayModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Pay>[];
      json['data'].forEach((v) {
        data?.add(Pay.fromJson(v));
      });
    }

    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
    totalAmount = (json['totalAmount'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data?.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    data['totalAmount'] =
        (this.totalAmount is num) ? this.totalAmount?.toDouble() : 0.0;
    return data;
  }
}

class Pay {
  int? id;
  String? driverId;
  String? tripId;
  String? startDate;
  String? endDate;
  double? amount;
  String? document;
  String? createdAt;
  String? updatedAt;

  Pay(
      {this.id,
      this.driverId,
      this.tripId,
      this.startDate,
      this.endDate,
      this.amount,
      this.document,
      this.createdAt,
      this.updatedAt});

  Pay.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driverId = json['driver_id'];
    tripId = json['tripId'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    amount = (json['amount'] as num?)?.toDouble();
    document = json['document'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['driver_id'] = this.driverId;
    data['tripId'] = this.tripId;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['amount'] = (amount as num?)?.toDouble();
    data['document'] = this.document;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class DocumentService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<TruckModel>> getTrucks(
      {int page = 1, // Default to page 1
      int pageSize = 15, // Default to 10 items per page
      String type = "trucks",
      String search = ""}) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/yard/trucks?page=$page&pageSize=$pageSize&type=$type&search=$search');

      if (response != null && response is Map<String, dynamic>) {
        TruckModel dashboard = TruckModel.fromJson(response['data']);

        return ApiResponse<TruckModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Truck Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error document: $e');
    }
  }

  Future<ApiResponse<VehicleModel>> getVechicleById(
      {String type = "truck", String id = ""}) async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/yard/$id?type=$type');

      if (response != null && response is Map<String, dynamic>) {
        VehicleModel details = VehicleModel.fromJson(response['data']);

        return ApiResponse<VehicleModel>(
          data: details,
          message: response['message'] ?? 'Get Details Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error dd\ocument : $e');
    }
  }

  Future<ApiResponse<PayModel>> getPays(
      {int page = 1, // Default to page 1
      int pageSize = 15,
      String search = ""}) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/yard/pays?page=$page&pageSize=$pageSize&search=${search}');

      if (response != null && response is Map<String, dynamic>) {
        PayModel details = PayModel.fromJson(response['data']);

        return ApiResponse<PayModel>(
          data: details,
          message: response['message'] ?? 'Get Details Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error dd\ocument : $e');
    }
  }
}
