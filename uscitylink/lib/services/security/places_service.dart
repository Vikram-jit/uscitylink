import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/model/security/place_models.dart';

class PlacesService {
  final _apiService = NetworkApiService();

  Future<List<PlacePrediction>> autocomplete(String input) async {
    try {
      final uri = Uri.parse('${Constant.url}/security/places/autocomplete')
          .replace(queryParameters: {'input': input});
      dynamic response = await _apiService.getApi(uri.toString());

      if (response != null && response is Map<String, dynamic>) {
        final predictions = (response['data']?['predictions'] as List<dynamic>? ?? [])
            .map((e) => PlacePrediction.fromJson(e))
            .toList();
        return predictions;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<PlaceDetails?> getDetails(String placeId) async {
    try {
      final uri = Uri.parse('${Constant.url}/security/places/details')
          .replace(queryParameters: {'placeId': placeId});
      dynamic response = await _apiService.getApi(uri.toString());

      if (response != null &&
          response is Map<String, dynamic> &&
          response['data'] != null) {
        return PlaceDetails.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
