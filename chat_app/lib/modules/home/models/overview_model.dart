import 'package:chat_app/models/group_model.dart';

class OverViewModel {
  int? templateCount;
  int? truckGroupCount;
  int? channelCount;
  int? messageCount;
  int? userUnMessage;
  List<LastFiveDriver>? lastFiveDriver;
  List<LastFiveDriver>? onlineDrivers;
  int? driverCount;
  String? channelId;
  List<GroupModel>? trucksgroups;

  OverViewModel({
    this.templateCount,
    this.truckGroupCount,
    this.channelCount,
    this.messageCount,
    this.userUnMessage,
    this.lastFiveDriver,
    this.driverCount,
    this.channelId,
    this.onlineDrivers,
    this.trucksgroups,
  });

  OverViewModel.fromJson(Map<String, dynamic> json) {
    templateCount = json['templateCount'];
    truckGroupCount = json['truckGroupCount'];
    channelCount = json['channelCount'];
    messageCount = json['messageCount'];
    userUnMessage = json['userUnMessage'];
    if (json['lastFiveDriver'] != null) {
      lastFiveDriver = <LastFiveDriver>[];
      json['lastFiveDriver'].forEach((v) {
        lastFiveDriver!.add(new LastFiveDriver.fromJson(v));
      });
    }
    if (json['onlineDrivers'] != null) {
      onlineDrivers = <LastFiveDriver>[];
      json['onlineDrivers'].forEach((v) {
        onlineDrivers!.add(new LastFiveDriver.fromJson(v));
      });
    }
    if (json['trucksgroups'] != null) {
      trucksgroups = <GroupModel>[];
      json['trucksgroups'].forEach((v) {
        trucksgroups!.add(new GroupModel.fromJson(v));
      });
    }
    driverCount = json['driverCount'];
    channelId = json['channelId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['templateCount'] = this.templateCount;
    data['truckGroupCount'] = this.truckGroupCount;
    data['channelCount'] = this.channelCount;
    data['messageCount'] = this.messageCount;
    data['userUnMessage'] = this.userUnMessage;
    if (this.lastFiveDriver != null) {
      data['lastFiveDriver'] = this.lastFiveDriver!
          .map((v) => v.toJson())
          .toList();
    }
    if (this.onlineDrivers != null) {
      data['onlineDrivers'] = this.onlineDrivers!
          .map((v) => v.toJson())
          .toList();
    }
    if (this.trucksgroups != null) {
      data['trucksgroups'] = this.trucksgroups!.map((v) => v.toJson()).toList();
    }
    data['driverCount'] = this.driverCount;
    data['channelId'] = this.channelId;
    return data;
  }

  OverViewModel copyWith({List<LastFiveDriver>? onlineDrivers}) {
    return OverViewModel(
      templateCount: templateCount,
      truckGroupCount: truckGroupCount,
      channelCount: channelCount,
      messageCount: messageCount,
      userUnMessage: userUnMessage,
      lastFiveDriver: lastFiveDriver,
      driverCount: driverCount,
      channelId: channelId,
      trucksgroups: trucksgroups,
      onlineDrivers: onlineDrivers ?? this.onlineDrivers,
    );
  }
}

class LastFiveDriver {
  String? id;
  String? phoneNumber;
  String? userType;
  String? driverNumber;
  int? yardId;
  String? email;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<Profiles>? profiles;
  int? unreadCount;

  LastFiveDriver({
    this.id,
    this.phoneNumber,
    this.userType,
    this.driverNumber,
    this.yardId,
    this.email,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.profiles,
    this.unreadCount,
  });
  LastFiveDriver copyWith({
    String? id,
    String? phoneNumber,
    String? userType,
    String? driverNumber,
    int? yardId,
    String? email,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Profiles>? profiles,
    int? unreadCount,
  }) {
    return LastFiveDriver(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      driverNumber: driverNumber ?? this.driverNumber,
      yardId: yardId ?? this.yardId,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      profiles: profiles ?? this.profiles,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  LastFiveDriver.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phoneNumber = json['phone_number'];
    userType = json['user_type'];
    driverNumber = json['driver_number'];
    yardId = json['yard_id'];
    email = json['email'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    unreadCount = json['unreadCount'];
    if (json['profiles'] != null) {
      profiles = <Profiles>[];
      json['profiles'].forEach((v) {
        profiles!.add(new Profiles.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['phone_number'] = this.phoneNumber;
    data['user_type'] = this.userType;
    data['driver_number'] = this.driverNumber;
    data['yard_id'] = this.yardId;
    data['email'] = this.email;
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['unreadCount'] = this.unreadCount;
    if (this.profiles != null) {
      data['profiles'] = this.profiles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Profiles {
  String? username;
  String? id;
  bool? isOnline;
  String? last_login;
  Profiles({this.username, this.id, this.isOnline, this.last_login});

  Profiles.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    id = json['id'];
    isOnline = json['isOnline'];
    last_login = json['last_login'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['id'] = this.id;
    data['isOnline'] = this.isOnline;
    data['last_login'] = this.last_login;
    return data;
  }
}
