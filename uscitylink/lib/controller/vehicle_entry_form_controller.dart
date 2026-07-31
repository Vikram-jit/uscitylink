import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/security/place_models.dart';
import 'package:uscitylink/model/security/security_driver_model.dart';
import 'package:uscitylink/model/security/security_trailer_model.dart';
import 'package:uscitylink/model/security/security_truck_model.dart';
import 'package:uscitylink/model/security/trailer_status_check_result.dart';
import 'package:uscitylink/model/security/vehicle_entry_payload.dart';
import 'package:uscitylink/services/security/security_entry_service.dart';
import 'package:uscitylink/utils/utils.dart';

enum VehicleEntryStatus { entry, depart }

extension VehicleEntryStatusX on VehicleEntryStatus {
  String get apiValue => this == VehicleEntryStatus.entry ? 'entry' : 'depart';
  String get label => this == VehicleEntryStatus.entry ? 'Vehicle Entry' : 'Vehicle Exit';
}

/// Yard origin (1601 S Union Ave, Bakersfield, CA) — exact same fixed point
/// the web reference uses (dashboard.blade.php YARD_ORIGIN).
const double _kYardLat = 35.3352865;
const double _kYardLng = -119.0039316;

/// Hardcoded security guard roster — mirrors the web's <select name="security">
/// options exactly (dashboard.blade.php), not a DB-driven list.
const List<String> kSecurityGuardOptions = [
  'Gurmeet Singh',
  'Chanan Singh',
  'Ranjodh Singh',
  'Kamal',
  'Sucha Singh',
];

class VehicleEntryFormController extends GetxController {
  final VehicleEntryStatus status;
  VehicleEntryFormController(this.status);

  final _entryService = SecurityEntryService();

  var loadingFormData = false.obs;
  var submitting = false.obs;

  var trucks = <SecurityTruckModel>[].obs;
  var trailers = <SecurityTrailerModel>[].obs;
  var drivers = <SecurityDriverModel>[].obs;

  var selectedTruck = Rxn<SecurityTruckModel>();
  var selectedTrailer = Rxn<SecurityTrailerModel>();

  var truckLicensePlateController = TextEditingController();
  var trailerLicensePlateController = TextEditingController();
  var truckFuel = Rxn<String>();
  var trailerFuel = Rxn<String>();

  var emptyLoaded = Rxn<String>(); // 'empty' | 'loaded'
  var loadType = Rxn<String>(); // 'refer' | 'dry'

  var truckKeyAttached = Rxn<String>();
  var truckMatt = Rxn<String>();
  var logBookStand = Rxn<String>();
  var securityGuardInspect = Rxn<String>();
  var spareTyre = Rxn<String>();
  var anualInspection = Rxn<String>();
  var registration = Rxn<String>();
  var damage = Rxn<String>();
  var fireExt = Rxn<String>();
  var warningTriangles = Rxn<String>();
  var seal = Rxn<String>();
  var alartm = Rxn<String>();
  var loadLocks = Rxn<String>();

  var damageDescriptionController = TextEditingController();
  var setTempController = TextEditingController();
  var runningTempController = TextEditingController();
  var descriptionController = TextEditingController();

  var logBookOk = Rxn<String>();
  var logBookRemark = Rxn<String>();
  var fuelCard = Rxn<String>();
  var fuelCardRemarkController = TextEditingController();

  var selectedDriverIds = <int>[].obs;

  var deliveryAddressController = TextEditingController();
  var deliveryCity = ''.obs;
  var deliveryState = ''.obs;
  var deliveryZipcode = ''.obs;
  var deliveryCountry = ''.obs;
  var deliveryLat = Rxn<double>();
  var deliveryLng = Rxn<double>();
  var deliveryDistanceMiles = Rxn<double>();
  var deliveryDurationMinutes = Rxn<int>();
  var deliverAt = Rxn<DateTime>();
  var departureAt = Rxn<DateTime>();

  var selectedSecurity = Rxn<String>();

  bool get hasTrailer => selectedTrailer.value != null;
  bool get isLoaded => emptyLoaded.value == 'loaded';
  bool get isEmptyTrailer => emptyLoaded.value == 'empty';
  bool get isRefer => loadType.value == 'refer';

  @override
  void onInit() {
    super.onInit();
    fetchFormData();
  }

  void fetchFormData() {
    loadingFormData.value = true;
    _entryService.getFormData().then((response) {
      trucks.value = response.data.trucks;
      trailers.value = response.data.trailers;
      drivers.value = response.data.drivers;
      loadingFormData.value = false;
    }).onError((error, stackTrace) {
      loadingFormData.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }

  void selectTruck(SecurityTruckModel? truck) {
    selectedTruck.value = truck;
    truckLicensePlateController.text = truck?.licensePlateNumber ?? '';
  }

  void selectTrailer(SecurityTrailerModel? trailer) {
    selectedTrailer.value = trailer;
    trailerLicensePlateController.text = trailer?.licensePlateNumber ?? '';
    if (trailer == null) {
      emptyLoaded.value = null;
    }
  }

  void selectReadyTrailer(ReadyTrailerOption option) {
    SecurityTrailerModel? match;
    for (final t in trailers) {
      if (t.id == option.id) {
        match = t;
        break;
      }
    }
    selectTrailer(match ?? SecurityTrailerModel(id: option.id, number: option.number));
  }

  /// Runs the "empty trailer not ready" check only when it applies — mirrors the web's
  /// verifyTrailerReadiness(): Exit only, and only once Empty is selected. Best-effort: a
  /// network error is treated as "allow through" (returns null), matching the web's own
  /// fetch-catch behavior of not blocking on a check failure.
  Future<TrailerStatusCheckResult?> checkTrailerReadiness() async {
    if (status != VehicleEntryStatus.depart) return null;
    if (emptyLoaded.value != 'empty') return null;
    final trailerId = selectedTrailer.value?.id;
    if (trailerId == null) return null;

    try {
      final response = await _entryService.checkTrailerStatus(trailerId);
      return response.data.blocked ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  static String readyStatusLabel(String? raw) {
    switch (raw) {
      case 'not-ready':
        return 'not ready';
      case 'processing':
        return 'processing';
      case 'out-of-yard':
        return 'out of yard';
      default:
        return raw ?? '';
    }
  }

  void applyPlaceDetails(PlaceDetails details) {
    deliveryCity.value = details.city;
    deliveryState.value = details.state;
    deliveryZipcode.value = details.zipcode;
    deliveryCountry.value = details.country;
    deliveryLat.value = details.lat;
    deliveryLng.value = details.lng;
    if (details.lat != null && details.lng != null) {
      _calculateRoute(details.lat!, details.lng!);
    }
  }

  // Straight-line distance × a circuity correction factor (same buckets as
  // the web's estimateRouteFallback), then a flat 55mph time model — this
  // reproduces the web app's actual time math exactly (it discards the live
  // Directions API duration and always recomputes minutes this same way).
  void _calculateRoute(double lat, double lng) {
    final straightMiles = _haversineMiles(_kYardLat, _kYardLng, lat, lng);
    final factor =
        straightMiles <= 100 ? 1.30 : (straightMiles <= 500 ? 1.20 : 1.13);
    final roadMiles = straightMiles * factor;
    final minutes = ((roadMiles / 55) * 60).round();
    deliveryDistanceMiles.value = double.parse(roadMiles.toStringAsFixed(2));
    deliveryDurationMinutes.value = minutes;
    recomputeDepartureAt();
  }

  double _haversineMiles(double lat1, double lng1, double lat2, double lng2) {
    const r = 3958.8; // Earth radius in miles
    double toRad(double deg) => deg * (math.pi / 180);
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  bool get _isCaliforniaDelivery {
    final state = deliveryState.value.trim().toLowerCase();
    return state == 'california' || state == 'ca';
  }

  /// e.g. "200.0 mi from yard • Est: 3.6 hr + Grace (25%): 0.9 hr = Total: 4.5 hr
  /// (estimated)" — mirrors the web's applyRouteResult() banner text exactly.
  String? get routeInfoLabel {
    final miles = deliveryDistanceMiles.value;
    final minutes = deliveryDurationMinutes.value;
    if (miles == null || minutes == null) return null;

    final graceFactor = _isCaliforniaDelivery ? 1.25 : 1.05;
    final gracePercentLabel = _isCaliforniaDelivery ? '25%' : '5%';
    final estHours = minutes / 60;
    final graceHours = estHours * (graceFactor - 1);
    final totalHours = estHours * graceFactor;
    String fmt(double h) => ((h * 10).round() / 10).toStringAsFixed(1);

    return '${miles.toStringAsFixed(1)} mi from yard • '
        'Est: ${fmt(estHours)} hr + Grace ($gracePercentLabel): ${fmt(graceHours)} hr '
        '= Total: ${fmt(totalHours)} hr (estimated)';
  }

  void setDeliverAt(DateTime dt) {
    deliverAt.value = dt;
    recomputeDepartureAt();
  }

  void recomputeDepartureAt() {
    final minutes = deliveryDurationMinutes.value;
    final deliver = deliverAt.value;
    if (minutes == null || deliver == null) return;
    final graceFactor = _isCaliforniaDelivery ? 1.25 : 1.05;
    final bufferedMinutes = (minutes * graceFactor).round();
    departureAt.value = deliver.subtract(Duration(minutes: bufferedMinutes));
  }

  /// Mirrors the backend's required-field rules so the guard sees a clear
  /// message before a network round trip, not just a generic API error.
  String? validate() {
    if (selectedSecurity.value == null) return 'Please select a security guard.';
    if (selectedTruck.value == null) return 'Please select a truck.';
    if (truckFuel.value == null) return 'Please select truck fuel.';
    if (truckLicensePlateController.text.trim().isEmpty) {
      return 'Truck license plate is required.';
    }

    if (hasTrailer) {
      if (trailerFuel.value == null) return 'Please select trailer fuel.';
      if (trailerLicensePlateController.text.trim().isEmpty) {
        return 'Trailer license plate is required.';
      }
      if (emptyLoaded.value == null) return 'Please choose Empty or Loaded.';

      final requiredToggles = <String, String?>{
        'Truck Key Attached': truckKeyAttached.value,
        'Truck Matt': truckMatt.value,
        'Log Book Stand': logBookStand.value,
        'Security Guard Inspect': securityGuardInspect.value,
        'Spare Tyre': spareTyre.value,
        'Annual Inspection': anualInspection.value,
        'Registration': registration.value,
        'Damage': damage.value,
        'Fire Extinguisher': fireExt.value,
        'Warning Triangles': warningTriangles.value,
      };
      for (final entry in requiredToggles.entries) {
        if (entry.value == null) return '${entry.key} is required.';
      }

      if (isLoaded) {
        if (loadType.value == null) return 'Please select load type.';
        if (seal.value == null) return 'Please answer Seal.';
        if (alartm.value == null) return 'Please answer Any Alarm.';
        if (deliveryAddressController.text.trim().isEmpty) {
          return 'Delivery address is required.';
        }
        if (deliverAt.value == null) return 'Deliver At is required.';
        if (deliverAt.value!.isBefore(DateTime.now())) {
          return 'Deliver At time cannot be in the past.';
        }
        if (isRefer) {
          if (setTempController.text.trim().isEmpty) {
            return 'Set Temp is required.';
          }
          if (runningTempController.text.trim().isEmpty) {
            return 'Running Temp is required.';
          }
        }
      }

      if (isEmptyTrailer) {
        if (loadLocks.value == null) return 'Please answer Load Locks.';
      }
    }
    return null;
  }

  Future<bool> submit() async {
    final error = validate();
    if (error != null) {
      Utils.snackBar('Missing Information', error);
      return false;
    }

    submitting.value = true;
    final payload = VehicleEntryPayload(
      status: status.apiValue,
      truckId: selectedTruck.value?.id,
      truckFuel: truckFuel.value,
      truckLicensePlate: truckLicensePlateController.text.trim(),
      security: selectedSecurity.value,
      trailerId: selectedTrailer.value?.id,
      trailerFuel: hasTrailer ? trailerFuel.value : null,
      trailerLicensePlate:
          hasTrailer ? trailerLicensePlateController.text.trim() : null,
      emptyLoaded: hasTrailer ? emptyLoaded.value : null,
      loadType: isLoaded ? loadType.value : null,
      truckKeyAttached: hasTrailer ? truckKeyAttached.value : null,
      truckMatt: hasTrailer ? truckMatt.value : null,
      logBookStand: hasTrailer ? logBookStand.value : null,
      securityGuardInspect: hasTrailer ? securityGuardInspect.value : null,
      spareTyre: hasTrailer ? spareTyre.value : null,
      anualInspection: hasTrailer ? anualInspection.value : null,
      registration: hasTrailer ? registration.value : null,
      damage: hasTrailer ? damage.value : null,
      damageDescription:
          damage.value == 'yes' ? damageDescriptionController.text.trim() : null,
      fireExt: hasTrailer ? fireExt.value : null,
      warningTriangles: hasTrailer ? warningTriangles.value : null,
      seal: isLoaded ? seal.value : null,
      alartm: isLoaded ? alartm.value : null,
      loadLocks: isEmptyTrailer ? loadLocks.value : null,
      setTemp: isRefer ? setTempController.text.trim() : null,
      runningTemp: isRefer ? runningTempController.text.trim() : null,
      driverIds: selectedDriverIds,
      description: descriptionController.text.trim(),
      logBookRemark: logBookOk.value == 'no' ? logBookRemark.value : null,
      fuelCard: fuelCard.value,
      fuelCardRemark:
          fuelCard.value == 'no' ? fuelCardRemarkController.text.trim() : null,
      deliveryAddress:
          isLoaded ? deliveryAddressController.text.trim() : null,
      deliveryCity: isLoaded ? deliveryCity.value : null,
      deliveryState: isLoaded ? deliveryState.value : null,
      deliveryZipcode: isLoaded ? deliveryZipcode.value : null,
      deliveryCountry: isLoaded ? deliveryCountry.value : null,
      deliveryLat: isLoaded ? deliveryLat.value : null,
      deliveryLng: isLoaded ? deliveryLng.value : null,
      deliveryDistanceMiles: isLoaded ? deliveryDistanceMiles.value : null,
      deliveryDurationMinutes: isLoaded ? deliveryDurationMinutes.value : null,
      deliverAt: isLoaded ? deliverAt.value?.toIso8601String() : null,
      departureAt: isLoaded ? departureAt.value?.toIso8601String() : null,
    );

    try {
      final response = await _entryService.submitEntry(payload);
      submitting.value = false;
      Utils.snackBar('Success', response.message);
      return true;
    } catch (e) {
      submitting.value = false;
      Utils.snackBar('Error', e.toString());
      return false;
    }
  }

  @override
  void onClose() {
    truckLicensePlateController.dispose();
    trailerLicensePlateController.dispose();
    damageDescriptionController.dispose();
    setTempController.dispose();
    runningTempController.dispose();
    descriptionController.dispose();
    deliveryAddressController.dispose();
    fuelCardRemarkController.dispose();
    super.onClose();
  }
}
