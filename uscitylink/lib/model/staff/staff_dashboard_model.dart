class StaffDashboardModel {
  int? channelCount;
  int? messageCount;
  int? groupCount;
  int? userUnMessage;
  //List<LastFiveDriver> lastFiveDriver;
  int? driverCount;
  String? channelId;
  //List<UserUnReadMessage> userUnReadMessage;

  StaffDashboardModel({
    this.channelCount,
    this.messageCount,
    this.groupCount,
    this.userUnMessage,
    // this.lastFiveDriver,
    this.driverCount,
    this.channelId,
    // this.userUnReadMessage
  });

  StaffDashboardModel.fromJson(Map<String, dynamic> json) {
    channelCount = json['channelCount'];
    messageCount = json['messageCount'];
    groupCount = json['groupCount'];
    userUnMessage = json['userUnMessage'];
    // if (json['lastFiveDriver'] != null) {
    //   lastFiveDriver = new List<LastFiveDriver>();
    //   json['lastFiveDriver'].forEach((v) {
    //     lastFiveDriver.add(new LastFiveDriver.fromJson(v));
    //   });
    // }
    driverCount = json['driverCount'];
    channelId = json['channelId'];
    // if (json['userUnReadMessage'] != null) {
    //   userUnReadMessage = new List<UserUnReadMessage>();
    //   json['userUnReadMessage'].forEach((v) {
    //     userUnReadMessage.add(new UserUnReadMessage.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['channelCount'] = this.channelCount;
    data['messageCount'] = this.messageCount;
    data['groupCount'] = this.groupCount;
    data['userUnMessage'] = this.userUnMessage;
    // if (this.lastFiveDriver != null) {
    //   data['lastFiveDriver'] =
    //       this.lastFiveDriver.map((v) => v.toJson()).toList();
    // }
    data['driverCount'] = this.driverCount;
    data['channelId'] = this.channelId;
    // if (this.userUnReadMessage != null) {
    //   data['userUnReadMessage'] =
    //       this.userUnReadMessage.map((v) => v.toJson()).toList();
    // }
    return data;
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

  LastFiveDriver(
      {this.id,
      this.phoneNumber,
      this.userType,
      this.driverNumber,
      this.yardId,
      this.email,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.profiles});

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
    if (json['profiles'] != null) {
      profiles = <Profiles>[];
      json['profiles'].forEach((v) {
        profiles?.add(new Profiles.fromJson(v));
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
    if (this.profiles != null) {
      data['profiles'] = this.profiles?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Profiles {
  String? username;
  String? id;

  Profiles({this.username, this.id});

  Profiles.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['id'] = this.id;
    return data;
  }
}

class UserUnReadMessage {
  String? id;
  String? channelId;
  String? userProfileId;
  String? groupId;
  String? body;
  String? messageDirection;
  String? deliveryStatus;
  String? messageTimestampUtc;
  String? senderId;
  String? url;
  bool? isRead;
  String? status;
  String? type;
  String? createdAt;
  String? updatedAt;
  Sender? sender;

  UserUnReadMessage(
      {this.id,
      this.channelId,
      this.userProfileId,
      this.groupId,
      this.body,
      this.messageDirection,
      this.deliveryStatus,
      this.messageTimestampUtc,
      this.senderId,
      this.url,
      this.isRead,
      this.status,
      this.type,
      this.createdAt,
      this.updatedAt,
      this.sender});

  UserUnReadMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    userProfileId = json['userProfileId'];
    groupId = json['groupId'];
    body = json['body'];
    messageDirection = json['messageDirection'];
    deliveryStatus = json['deliveryStatus'];
    messageTimestampUtc = json['messageTimestampUtc'];
    senderId = json['senderId'];
    url = json['url'];
    isRead = json['isRead'];
    status = json['status'];
    type = json['type'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    sender =
        json['sender'] != null ? new Sender.fromJson(json['sender']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channelId'] = this.channelId;
    data['userProfileId'] = this.userProfileId;
    data['groupId'] = this.groupId;
    data['body'] = this.body;
    data['messageDirection'] = this.messageDirection;
    data['deliveryStatus'] = this.deliveryStatus;
    data['messageTimestampUtc'] = this.messageTimestampUtc;
    data['senderId'] = this.senderId;
    data['url'] = this.url;
    data['isRead'] = this.isRead;
    data['status'] = this.status;
    data['type'] = this.type;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.sender != null) {
      data['sender'] = this.sender?.toJson();
    }
    return data;
  }
}

class Sender {
  String? id;
  String? username;
  bool? isOnline;
  User? user;

  Sender({this.id, this.username, this.isOnline, this.user});

  Sender.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    isOnline = json['isOnline'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['isOnline'] = this.isOnline;
    if (this.user != null) {
      data['user'] = this.user?.toJson();
    }
    return data;
  }
}

class User {
  String? id;
  String? phoneNumber;
  String? userType;
  String? driverNumber;
  int? yardId;
  String? email;
  String? status;
  String? createdAt;
  String? updatedAt;

  User(
      {this.id,
      this.phoneNumber,
      this.userType,
      this.driverNumber,
      this.yardId,
      this.email,
      this.status,
      this.createdAt,
      this.updatedAt});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phoneNumber = json['phone_number'];
    userType = json['user_type'];
    driverNumber = json['driver_number'];
    yardId = json['yard_id'];
    email = json['email'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
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
    return data;
  }
}
