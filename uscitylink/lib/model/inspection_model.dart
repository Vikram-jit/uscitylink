import 'dart:convert';

InspectionModel inspectionModelFromJson(String str) =>
    InspectionModel.fromJson(json.decode(str));

String inspectionModelToJson(InspectionModel data) =>
    json.encode(data.toJson());

class InspectionModel {
  GroupUser? groupUser;
  List<String>? questionsTrailer;
  List<String>? questionsTruck;
  List<Trailer>? trailers;
  GetYardDriver? getYardDriver;
  double? odometerMiles;

  InspectionModel({
    this.groupUser,
    this.questionsTrailer,
    this.questionsTruck,
    this.trailers,
    this.getYardDriver,
    this.odometerMiles,
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) =>
      InspectionModel(
        groupUser: json["groupUser"] == null
            ? null
            : GroupUser.fromJson(json["groupUser"]),
        questionsTrailer: json["questionsTrailer"] == null
            ? []
            : List<String>.from(json["questionsTrailer"].map((x) => x)),
        questionsTruck: json["questionsTruck"] == null
            ? []
            : List<String>.from(json["questionsTruck"].map((x) => x)),
        trailers: json["trailers"] == null
            ? []
            : List<Trailer>.from(
                json["trailers"].map((x) => Trailer.fromJson(x))),
        getYardDriver: json["getYardDriver"] == null
            ? null
            : GetYardDriver.fromJson(json["getYardDriver"]),
        odometerMiles: json["odometerMiles"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "groupUser": groupUser?.toJson(),
        "questionsTrailer": questionsTrailer == null
            ? []
            : List<dynamic>.from(questionsTrailer!.map((x) => x)),
        "questionsTruck": questionsTruck == null
            ? []
            : List<dynamic>.from(questionsTruck!.map((x) => x)),
        "trailers": trailers == null
            ? []
            : List<dynamic>.from(trailers!.map((x) => x.toJson())),
        "getYardDriver": getYardDriver?.toJson(),
        "odometerMiles": odometerMiles,
      };
}

class GetYardDriver {
  int? id;
  String? samsaraVehicleId;
  dynamic companyId;
  dynamic parkingFees;
  String? trailerPresent;
  String? number;
  int? year;
  String? make;
  String? model;
  String? vin;
  String? licensePlateNumber;
  State? state;
  dynamic prePassId;
  dynamic driverFuelId;
  dynamic fuelCardNumber;
  int? status;
  CurrentPosition? currentPosition;
  String? readyStatus;
  dynamic assginVehicleEntryId;
  String? assginStatus;
  dynamic deletedAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  GetYardDriver({
    this.id,
    this.samsaraVehicleId,
    this.companyId,
    this.parkingFees,
    this.trailerPresent,
    this.number,
    this.year,
    this.make,
    this.model,
    this.vin,
    this.licensePlateNumber,
    this.state,
    this.prePassId,
    this.driverFuelId,
    this.fuelCardNumber,
    this.status,
    this.currentPosition,
    this.readyStatus,
    this.assginVehicleEntryId,
    this.assginStatus,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory GetYardDriver.fromJson(Map<String, dynamic> json) => GetYardDriver(
        id: json["id"],
        samsaraVehicleId: json["samsara_vehicle_id"],
        companyId: json["company_id"],
        parkingFees: json["parking_fees"],
        trailerPresent: json["trailer_present"],
        number: json["number"],
        year: json["year"],
        make: json["make"],
        model: json["model"],
        vin: json["vin"],
        licensePlateNumber: json["license_plate_number"],
        state: json["state"] == null ? null : stateValues.map[json["state"]],
        prePassId: json["pre_pass_id"],
        driverFuelId: json["driver_fuel_id"],
        fuelCardNumber: json["fuel_card_number"],
        status: json["status"],
        currentPosition: json["current_position"] == null
            ? null
            : currentPositionValues.map[json["current_position"]],
        readyStatus: json["ready_status"],
        assginVehicleEntryId: json["assgin_vehicle_entry_id"],
        assginStatus: json["assgin_status"],
        deletedAt: json["deleted_at"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.tryParse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.tryParse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "samsara_vehicle_id": samsaraVehicleId,
        "company_id": companyId,
        "parking_fees": parkingFees,
        "trailer_present": trailerPresent,
        "number": number,
        "year": year,
        "make": make,
        "model": model,
        "vin": vin,
        "license_plate_number": licensePlateNumber,
        "state": stateValues.reverse[state],
        "pre_pass_id": prePassId,
        "driver_fuel_id": driverFuelId,
        "fuel_card_number": fuelCardNumber,
        "status": status,
        "current_position": currentPositionValues.reverse[currentPosition],
        "ready_status": readyStatus,
        "assgin_vehicle_entry_id": assginVehicleEntryId,
        "assgin_status": assginStatus,
        "deleted_at": deletedAt,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

enum CurrentPosition { departed, in_yard, unknown }

final currentPositionValues = EnumValues({
  "departed": CurrentPosition.departed,
  "in_yard": CurrentPosition.in_yard,
});

extension CurrentPositionExtension on CurrentPosition {
  String get value {
    switch (this) {
      case CurrentPosition.departed:
        return "departed";
      case CurrentPosition.in_yard:
        return "in_yard";
      default:
        return "unknown";
    }
  }
}

enum State { AL, CA, MA, MD, unknown }

final stateValues = EnumValues({
  "AL": State.AL,
  "CA": State.CA,
  "MA": State.MA,
  "MD": State.MD,
});

extension StateExtension on State {
  String get value {
    switch (this) {
      case State.AL:
        return "AL";
      case State.CA:
        return "CA";
      case State.MA:
        return "MA";
      case State.MD:
        return "MD";
      default:
        return "unknown";
    }
  }
}

class GroupUser {
  String? id;
  String? groupId;
  String? userProfileId;
  String? status;
  dynamic lastMessageId;
  int? messageCount;
  DateTime? lastMessageUtc;
  DateTime? createdAt;
  DateTime? updatedAt;
  Group? group;

  GroupUser({
    this.id,
    this.groupId,
    this.userProfileId,
    this.status,
    this.lastMessageId,
    this.messageCount,
    this.lastMessageUtc,
    this.createdAt,
    this.updatedAt,
    this.group,
  });

  factory GroupUser.fromJson(Map<String, dynamic> json) => GroupUser(
        id: json["id"],
        groupId: json["groupId"],
        userProfileId: json["userProfileId"],
        status: json["status"],
        lastMessageId: json["last_message_id"],
        messageCount: json["message_count"],
        lastMessageUtc: json["last_message_utc"] == null
            ? null
            : DateTime.tryParse(json["last_message_utc"]),
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.tryParse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"]),
        group: json["Group"] == null ? null : Group.fromJson(json["Group"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "groupId": groupId,
        "userProfileId": userProfileId,
        "status": status,
        "last_message_id": lastMessageId,
        "message_count": messageCount,
        "last_message_utc": lastMessageUtc?.toIso8601String(),
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "Group": group?.toJson(),
      };
}

class Group {
  String? id;
  String? name;
  String? description;
  String? type;
  String? lastMessageId;
  dynamic messageCount;
  DateTime? createdAt;
  DateTime? updatedAt;

  Group({
    this.id,
    this.name,
    this.description,
    this.type,
    this.lastMessageId,
    this.messageCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        type: json["type"],
        lastMessageId: json["last_message_id"],
        messageCount: json["message_count"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.tryParse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "type": type,
        "last_message_id": lastMessageId,
        "message_count": messageCount,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}

class Trailer {
  int? id;
  String? companyId;
  String? parkingFees;
  String? number;
  int? year;
  String? make;
  String? model;
  String? vin;
  String? licensePlateNumber;
  State? state;
  Type? type;
  CurrentPosition? currentPosition;
  String? readyStatus;
  Status? status;
  String? localAssign;
  String? longAssign;
  dynamic assginVehicleEntryId;
  String? assginStatus;
  String? pendingToWashout;
  DateTime? deletedAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  Trailer({
    this.id,
    this.companyId,
    this.parkingFees,
    this.number,
    this.year,
    this.make,
    this.model,
    this.vin,
    this.licensePlateNumber,
    this.state,
    this.type,
    this.currentPosition,
    this.readyStatus,
    this.status,
    this.localAssign,
    this.longAssign,
    this.assginVehicleEntryId,
    this.assginStatus,
    this.pendingToWashout,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Trailer.fromJson(Map<String, dynamic> json) => Trailer(
        id: json["id"],
        companyId: json["company_id"],
        parkingFees: json["parking_fees"],
        number: json["number"],
        year: json["year"],
        make: json["make"],
        model: json["model"],
        vin: json["vin"],
        licensePlateNumber: json["license_plate_number"],
        state: json["state"] == null ? null : stateValues.map[json["state"]],
        type: json["type"] == null ? null : typeValues.map[json["type"]],
        currentPosition: json["current_position"] == null
            ? null
            : currentPositionValues.map[json["current_position"]],
        readyStatus: json["ready_status"],
        status:
            json["status"] == null ? null : statusValues.map[json["status"]],
        localAssign: json["local_assign"],
        longAssign: json["long_assign"],
        assginVehicleEntryId: json["assgin_vehicle_entry_id"],
        assginStatus: json["assgin_status"],
        pendingToWashout: json["pending_to_washout"],
        deletedAt: json["deleted_at"] == null
            ? null
            : DateTime.tryParse(json["deleted_at"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.tryParse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.tryParse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "company_id": companyId,
        "parking_fees": parkingFees,
        "number": number,
        "year": year,
        "make": make,
        "model": model,
        "vin": vin,
        "license_plate_number": licensePlateNumber,
        "state": stateValues.reverse[state],
        "type": typeValues.reverse[type],
        "current_position": currentPositionValues.reverse[currentPosition],
        "ready_status": readyStatus,
        "status": statusValues.reverse[status],
        "local_assign": localAssign,
        "long_assign": longAssign,
        "assgin_vehicle_entry_id": assginVehicleEntryId,
        "assgin_status": assginStatus,
        "pending_to_washout": pendingToWashout,
        "deleted_at": deletedAt?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

enum Status { not_ready, ready, unknown }

final statusValues = EnumValues({
  "not-ready": Status.not_ready,
  "ready": Status.ready,
});

extension StatusExtension on Status {
  String get value {
    switch (this) {
      case Status.not_ready:
        return "not-ready";
      case Status.ready:
        return "ready";
      default:
        return "unknown";
    }
  }
}

enum Type { dry_van, reefer, unknown }

final typeValues = EnumValues({
  "dry_van": Type.dry_van,
  "reefer": Type.reefer,
});

extension TypeExtension on Type {
  String get value {
    switch (this) {
      case Type.dry_van:
        return "dry_van";
      case Type.reefer:
        return "reefer";
      default:
        return "unknown";
    }
  }
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
