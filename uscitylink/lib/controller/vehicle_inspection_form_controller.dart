import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/security/inspection_question_answer.dart';
import 'package:uscitylink/model/security/security_driver_model.dart';
import 'package:uscitylink/model/security/security_trailer_model.dart';
import 'package:uscitylink/model/security/security_truck_model.dart';
import 'package:uscitylink/services/security/security_entry_service.dart';
import 'package:uscitylink/services/security/security_inspection_service.dart';
import 'package:uscitylink/utils/utils.dart';

class VehicleInspectionFormController extends GetxController {
  final int? initialTruckId;
  VehicleInspectionFormController({this.initialTruckId});

  final _entryService = SecurityEntryService();
  final _inspectionService = SecurityInspectionService();

  var loadingFormData = false.obs;
  var loadingOdometer = false.obs;
  var submitting = false.obs;

  var trucks = <SecurityTruckModel>[].obs;
  var trailers = <SecurityTrailerModel>[].obs;
  var drivers = <SecurityDriverModel>[].obs;

  var truckQuestions = <String>[].obs;
  var trailerQuestions = <String>[].obs;

  var selectedTruck = Rxn<SecurityTruckModel>();
  var selectedTrailer = Rxn<SecurityTrailerModel>();

  var truckAnswers = <String, String?>{}.obs;
  var trailerAnswers = <String, String?>{}.obs;

  var companyNameController =
      TextEditingController(text: 'US City Link Corporation');
  var odometerController = TextEditingController();
  var noteController = TextEditingController();
  var inspectedAt = Rxn<DateTime>();
  var selectedDriverIds = <int>[].obs;
  var selectedSecurity = Rxn<String>();

  bool get hasTrailer => selectedTrailer.value != null;

  @override
  void onInit() {
    super.onInit();
    inspectedAt.value = DateTime.now();
    fetchFormData();
    fetchQuestions();
  }

  void fetchFormData() {
    loadingFormData.value = true;
    _entryService.getFormData().then((response) {
      trucks.value = response.data.trucks;
      trailers.value = response.data.trailers;
      drivers.value = response.data.drivers;
      loadingFormData.value = false;

      if (initialTruckId != null) {
        SecurityTruckModel? match;
        for (final t in trucks) {
          if (t.id == initialTruckId) {
            match = t;
            break;
          }
        }
        if (match != null) selectTruck(match);
      }
    }).onError((error, stackTrace) {
      loadingFormData.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }

  void fetchQuestions() {
    _inspectionService.getQuestions().then((response) {
      truckQuestions.value = response.data.truckQuestions;
      trailerQuestions.value = response.data.trailerQuestions;
      for (final q in truckQuestions) {
        truckAnswers[q] = null;
      }
    }).catchError((error) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void selectTruck(SecurityTruckModel? truck) {
    selectedTruck.value = truck;
    odometerController.clear();
    if (truck?.id != null) _fetchOdometer(truck!.id!);
  }

  Future<void> _fetchOdometer(int truckId) async {
    loadingOdometer.value = true;
    try {
      final response = await _inspectionService.getOdometer(truckId);
      if (response.data.odometerMiles != null) {
        odometerController.text =
            response.data.odometerMiles!.toStringAsFixed(2);
      }
    } catch (_) {
      // Best-effort — leave odometer blank for manual entry if the lookup fails.
    } finally {
      loadingOdometer.value = false;
    }
  }

  void selectTrailer(SecurityTrailerModel? trailer) {
    selectedTrailer.value = trailer;
    if (trailer == null) {
      trailerAnswers.clear();
    }
  }

  void setTruckAnswer(String question, String status) {
    truckAnswers[question] = status;
  }

  void setTrailerAnswer(String question, String status) {
    trailerAnswers[question] = status;
  }

  /// Mirrors the client-side rule the web's Blade JS already enforces (every
  /// visible checklist item must be answered) — the Laravel store() itself
  /// does no server-side validation, but this port applies the same rule the
  /// web's own form requires before allowing submission.
  String? validate() {
    if (selectedSecurity.value == null)
      return 'Please select a security guard.';
    if (selectedTruck.value == null) return 'Please select a truck.';
    if (inspectedAt.value == null) return 'Please select an inspection date.';

    for (final q in truckQuestions) {
      if (truckAnswers[q] == null) return 'Please answer "$q".';
    }
    if (hasTrailer) {
      for (final q in trailerQuestions) {
        if (trailerAnswers[q] == null) return 'Please answer "$q" (trailer).';
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
    // Everything below (including payload construction) is now inside the
    // try/finally — previously payload construction happened *before* the
    // try block, so any exception there would leave submitting stuck at
    // true forever, permanently disabling the submit button (onPressed:
    // submitting.value ? null : ...) with no visible error.
    try {
      final payload = {
        'companyName': companyNameController.text.trim(),
        'truckId': selectedTruck.value?.id,
        'trailerId': hasTrailer ? selectedTrailer.value?.id : null,
        'driverIds': selectedDriverIds.toList(),
        'odometer': odometerController.text.trim(),
        'inspectedAt': inspectedAt.value?.toIso8601String(),
        'note': noteController.text.trim(),
        'security': selectedSecurity.value,
        'truckAnswers': truckQuestions
            .map((q) =>
                InspectionQuestionAnswer(question: q, status: truckAnswers[q])
                    .toJson())
            .toList(),
        'trailerAnswers': hasTrailer
            ? trailerQuestions
                .map((q) => InspectionQuestionAnswer(
                        question: q, status: trailerAnswers[q])
                    .toJson())
                .toList()
            : [],
      };

      final response = await _inspectionService.createInspection(payload);
      Get.back(); // Close the form view
      Utils.snackBar('Success', response.message);
      return true;
    } catch (e) {
      Utils.snackBar('Error', e.toString());
      return false;
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    companyNameController.dispose();
    odometerController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
