// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class DashboardModelAdapter extends TypeAdapter<DashboardModel> {
  @override
  final typeId = 0;

  @override
  DashboardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DashboardModel(
      trucks: fields[1] as String?,
      channelCount: (fields[2] as num?)?.toInt(),
      messageCount: (fields[3] as num?)?.toInt(),
      groupCount: (fields[4] as num?)?.toInt(),
      truckCount: (fields[5] as num?)?.toInt(),
      trailerCount: (fields[6] as num?)?.toInt(),
      latestMessage: (fields[9] as List?)?.cast<LatestMessage>(),
      latestGroupMessage: (fields[10] as List?)?.cast<LatestGroupMessage>(),
      channel: fields[0] as Channel?,
      totalAmount: (fields[7] as num?)?.toDouble(),
      isDocumentExpired: fields[8] as bool?,
      isInspectionDone: fields[11] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, DashboardModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.channel)
      ..writeByte(1)
      ..write(obj.trucks)
      ..writeByte(2)
      ..write(obj.channelCount)
      ..writeByte(3)
      ..write(obj.messageCount)
      ..writeByte(4)
      ..write(obj.groupCount)
      ..writeByte(5)
      ..write(obj.truckCount)
      ..writeByte(6)
      ..write(obj.trailerCount)
      ..writeByte(7)
      ..write(obj.totalAmount)
      ..writeByte(8)
      ..write(obj.isDocumentExpired)
      ..writeByte(9)
      ..write(obj.latestMessage)
      ..writeByte(10)
      ..write(obj.latestGroupMessage)
      ..writeByte(11)
      ..write(obj.isInspectionDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChannelAdapter extends TypeAdapter<Channel> {
  @override
  final typeId = 1;

  @override
  Channel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Channel(
      id: fields[0] as String?,
      name: fields[1] as String?,
      description: fields[2] as String?,
      createdAt: fields[3] as String?,
      updatedAt: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Channel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LatestMessageAdapter extends TypeAdapter<LatestMessage> {
  @override
  final typeId = 2;

  @override
  LatestMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatestMessage(
      id: fields[0] as String?,
      channelId: fields[1] as String?,
      userProfileId: fields[2] as String?,
      groupId: fields[3] as String?,
      body: fields[4] as String?,
      messageDirection: fields[5] as String?,
      deliveryStatus: fields[6] as String?,
      messageTimestampUtc: fields[7] as String?,
      senderId: fields[8] as String?,
      url: fields[9] as String?,
      isRead: fields[10] as bool?,
      status: fields[11] as String?,
      type: fields[12] as String?,
      createdAt: fields[13] as String?,
      updatedAt: fields[14] as String?,
      sender: fields[15] as SenderModel?,
      channel: fields[16] as Channel?,
    );
  }

  @override
  void write(BinaryWriter writer, LatestMessage obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.channelId)
      ..writeByte(2)
      ..write(obj.userProfileId)
      ..writeByte(3)
      ..write(obj.groupId)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.messageDirection)
      ..writeByte(6)
      ..write(obj.deliveryStatus)
      ..writeByte(7)
      ..write(obj.messageTimestampUtc)
      ..writeByte(8)
      ..write(obj.senderId)
      ..writeByte(9)
      ..write(obj.url)
      ..writeByte(10)
      ..write(obj.isRead)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.type)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.sender)
      ..writeByte(16)
      ..write(obj.channel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatestMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LatestGroupMessageAdapter extends TypeAdapter<LatestGroupMessage> {
  @override
  final typeId = 3;

  @override
  LatestGroupMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatestGroupMessage(
      id: fields[0] as String?,
      channelId: fields[1] as String?,
      userProfileId: fields[2] as String?,
      groupId: fields[3] as String?,
      body: fields[4] as String?,
      messageDirection: fields[5] as String?,
      deliveryStatus: fields[6] as String?,
      messageTimestampUtc: fields[7] as String?,
      senderId: fields[8] as String?,
      url: fields[9] as String?,
      isRead: fields[10] as bool?,
      status: fields[11] as String?,
      type: fields[12] as String?,
      createdAt: fields[13] as String?,
      updatedAt: fields[14] as String?,
      sender: fields[15] as SenderModel?,
      channel: fields[16] as Channel?,
      group: fields[17] as GroupDashboard?,
    );
  }

  @override
  void write(BinaryWriter writer, LatestGroupMessage obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.channelId)
      ..writeByte(2)
      ..write(obj.userProfileId)
      ..writeByte(3)
      ..write(obj.groupId)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.messageDirection)
      ..writeByte(6)
      ..write(obj.deliveryStatus)
      ..writeByte(7)
      ..write(obj.messageTimestampUtc)
      ..writeByte(8)
      ..write(obj.senderId)
      ..writeByte(9)
      ..write(obj.url)
      ..writeByte(10)
      ..write(obj.isRead)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.type)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.sender)
      ..writeByte(16)
      ..write(obj.channel)
      ..writeByte(17)
      ..write(obj.group);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatestGroupMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupDashboardAdapter extends TypeAdapter<GroupDashboard> {
  @override
  final typeId = 4;

  @override
  GroupDashboard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupDashboard(
      id: fields[0] as String?,
      name: fields[1] as String?,
      description: fields[2] as String?,
      type: fields[3] as String?,
      lastMessageId: fields[4] as String?,
      messageCount: (fields[5] as num?)?.toInt(),
      createdAt: fields[6] as String?,
      updatedAt: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupDashboard obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.lastMessageId)
      ..writeByte(5)
      ..write(obj.messageCount)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupDashboardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SenderModelAdapter extends TypeAdapter<SenderModel> {
  @override
  final typeId = 5;

  @override
  SenderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SenderModel(
      id: fields[0] as String?,
      username: fields[1] as String?,
      isOnline: fields[2] as bool?,
      user: fields[3] as UserModel?,
    );
  }

  @override
  void write(BinaryWriter writer, SenderModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.isOnline)
      ..writeByte(3)
      ..write(obj.user);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SenderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserChannelModelAdapter extends TypeAdapter<UserChannelModel> {
  @override
  final typeId = 6;

  @override
  UserChannelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserChannelModel(
      id: fields[0] as String?,
      userProfileId: fields[1] as String?,
      channelId: fields[2] as String?,
      createdAt: fields[3] as String?,
      updatedAt: fields[4] as String?,
      channel: fields[5] as ChannelModel?,
      last_message: fields[6] as MessageModel?,
      recieve_message_count: (fields[7] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, UserChannelModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userProfileId)
      ..writeByte(2)
      ..write(obj.channelId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.channel)
      ..writeByte(6)
      ..write(obj.last_message)
      ..writeByte(7)
      ..write(obj.recieve_message_count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserChannelModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final typeId = 7;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String?,
      channelId: fields[1] as String?,
      userProfileId: fields[2] as String?,
      groupId: fields[3] as String?,
      body: fields[4] as String?,
      messageDirection: fields[5] as String?,
      deliveryStatus: fields[6] as String?,
      messageTimestampUtc: fields[7] as String?,
      senderId: fields[8] as String?,
      isRead: fields[9] as bool?,
      status: fields[10] as String?,
      createdAt: fields[12] as String?,
      updatedAt: fields[13] as String?,
      url: fields[11] as String?,
      sender: fields[14] as SenderModel?,
      group: fields[15] as Group?,
      type: fields[16] as String?,
      thumbnail: fields[17] as String?,
      r_message: fields[21] as MessageModel?,
      driverPin: fields[18] as String?,
      staffPin: fields[19] as String?,
      url_upload_type: fields[20] as String?,
      temp_id: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.channelId)
      ..writeByte(2)
      ..write(obj.userProfileId)
      ..writeByte(3)
      ..write(obj.groupId)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.messageDirection)
      ..writeByte(6)
      ..write(obj.deliveryStatus)
      ..writeByte(7)
      ..write(obj.messageTimestampUtc)
      ..writeByte(8)
      ..write(obj.senderId)
      ..writeByte(9)
      ..write(obj.isRead)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.url)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.sender)
      ..writeByte(15)
      ..write(obj.group)
      ..writeByte(16)
      ..write(obj.type)
      ..writeByte(17)
      ..write(obj.thumbnail)
      ..writeByte(18)
      ..write(obj.driverPin)
      ..writeByte(19)
      ..write(obj.staffPin)
      ..writeByte(20)
      ..write(obj.url_upload_type)
      ..writeByte(21)
      ..write(obj.r_message)
      ..writeByte(22)
      ..write(obj.temp_id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupModelAdapter extends TypeAdapter<GroupModel> {
  @override
  final typeId = 8;

  @override
  GroupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupModel(
      id: fields[0] as String?,
      groupId: fields[1] as String?,
      userProfileId: fields[2] as String?,
      status: fields[3] as String?,
      createdAt: fields[4] as String?,
      updatedAt: fields[5] as String?,
      group: fields[8] as Group?,
      last_message: fields[6] as MessageModel?,
      message_count: (fields[7] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, GroupModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.userProfileId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.last_message)
      ..writeByte(7)
      ..write(obj.message_count)
      ..writeByte(8)
      ..write(obj.group);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final typeId = 9;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String?,
      phoneNumber: fields[1] as String?,
      userType: fields[2] as String?,
      driverNumber: fields[3] as String?,
      yardId: (fields[4] as num?)?.toInt(),
      email: fields[5] as String?,
      status: fields[6] as String?,
      createdAt: fields[7] as String?,
      updatedAt: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.userType)
      ..writeByte(3)
      ..write(obj.driverNumber)
      ..writeByte(4)
      ..write(obj.yardId)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChannelModelAdapter extends TypeAdapter<ChannelModel> {
  @override
  final typeId = 10;

  @override
  ChannelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChannelModel(
      id: fields[0] as String?,
      name: fields[1] as String?,
      description: fields[2] as String?,
      createdAt: fields[3] as String?,
      updatedAt: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChannelModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CountModelAdapter extends TypeAdapter<CountModel> {
  @override
  final typeId = 11;

  @override
  CountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CountModel(
      total: (fields[0] as num?)?.toInt(),
      channel: (fields[1] as num?)?.toInt(),
      group: (fields[2] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CountModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.total)
      ..writeByte(1)
      ..write(obj.channel)
      ..writeByte(2)
      ..write(obj.group);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final typeId = 12;

  @override
  Group read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Group(
      id: fields[0] as String?,
      name: fields[1] as String?,
      description: fields[2] as String?,
      type: fields[3] as String?,
      createdAt: fields[4] as String?,
      updatedAt: fields[5] as String?,
      groupChannel: fields[6] as GroupChannel?,
    );
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.groupChannel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupChannelAdapter extends TypeAdapter<GroupChannel> {
  @override
  final typeId = 13;

  @override
  GroupChannel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupChannel(
      id: fields[0] as String?,
      groupId: fields[1] as String?,
      channelId: fields[2] as String?,
      createdAt: fields[3] as String?,
      updatedAt: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupChannel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.channelId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StationsAdapter extends TypeAdapter<Stations> {
  @override
  final typeId = 14;

  @override
  Stations read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stations(
      id: (fields[0] as num?)?.toInt(),
      storeNumber: (fields[1] as num?)?.toInt(),
      name: fields[2] as String?,
      address: fields[3] as String?,
      city: fields[4] as String?,
      state: fields[5] as String?,
      zipCode: fields[6] as String?,
      interstate: fields[7] as String?,
      latitude: (fields[8] as num?)?.toDouble(),
      longitude: (fields[9] as num?)?.toDouble(),
      phoneNumber: fields[10] as String?,
      parkingSpacesCount: (fields[11] as num?)?.toInt(),
      fuelLaneCount: (fields[12] as num?)?.toInt(),
      showerCount: (fields[13] as num?)?.toInt(),
      amenities: fields[14] as String?,
      restaurants: fields[15] as String?,
      fuelPrice: fields[16] as FuelPrice?,
      distanceFromRoute: (fields[18] as num?)?.toDouble(),
      isCheapestInState: fields[19] as bool?,
      distanceFromTruck: (fields[20] as num?)?.toDouble(),
      isRecommended: fields[17] as bool?,
      isBothNearestAndCheapest: fields[22] as bool?,
      isNearestStation: fields[21] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Stations obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storeNumber)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.zipCode)
      ..writeByte(7)
      ..write(obj.interstate)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.phoneNumber)
      ..writeByte(11)
      ..write(obj.parkingSpacesCount)
      ..writeByte(12)
      ..write(obj.fuelLaneCount)
      ..writeByte(13)
      ..write(obj.showerCount)
      ..writeByte(14)
      ..write(obj.amenities)
      ..writeByte(15)
      ..write(obj.restaurants)
      ..writeByte(16)
      ..write(obj.fuelPrice)
      ..writeByte(17)
      ..write(obj.isRecommended)
      ..writeByte(18)
      ..write(obj.distanceFromRoute)
      ..writeByte(19)
      ..write(obj.isCheapestInState)
      ..writeByte(20)
      ..write(obj.distanceFromTruck)
      ..writeByte(21)
      ..write(obj.isNearestStation)
      ..writeByte(22)
      ..write(obj.isBothNearestAndCheapest);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FuelPriceAdapter extends TypeAdapter<FuelPrice> {
  @override
  final typeId = 15;

  @override
  FuelPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelPrice(
      product: fields[0] as String?,
      yourPrice: fields[1] as String?,
      retailPrice: fields[2] as String?,
      savingsTotal: fields[3] as String?,
      effectiveDate: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FuelPrice obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.yourPrice)
      ..writeByte(2)
      ..write(obj.retailPrice)
      ..writeByte(3)
      ..write(obj.savingsTotal)
      ..writeByte(4)
      ..write(obj.effectiveDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VehicleGpsModelAdapter extends TypeAdapter<VehicleGpsModel> {
  @override
  final typeId = 16;

  @override
  VehicleGpsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleGpsModel(
      vehicleId: fields[0] as String,
      vehicleName: fields[1] as String,
      timestamp: fields[2] as DateTime,
      latitude: (fields[3] as num).toDouble(),
      longitude: (fields[4] as num).toDouble(),
      headingDegrees: (fields[5] as num?)?.toDouble(),
      speedMilesPerHour: (fields[6] as num?)?.toDouble(),
      formattedLocation: fields[7] as String?,
      fuelPercent: (fields[8] as num?)?.toInt(),
      fuelPercentTime: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleGpsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.vehicleId)
      ..writeByte(1)
      ..write(obj.vehicleName)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.headingDegrees)
      ..writeByte(6)
      ..write(obj.speedMilesPerHour)
      ..writeByte(7)
      ..write(obj.formattedLocation)
      ..writeByte(8)
      ..write(obj.fuelPercent)
      ..writeByte(9)
      ..write(obj.fuelPercentTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleGpsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RouteModelAdapter extends TypeAdapter<RouteModel> {
  @override
  final typeId = 17;

  @override
  RouteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RouteModel(
      id: (fields[0] as num?)?.toInt(),
      fromLocation: fields[1] as String?,
      toLocation: fields[2] as String?,
      distance: (fields[3] as num?)?.toInt(),
      createdAt: fields[4] as String?,
      updatedAt: fields[5] as String?,
      fromAddress: fields[6] as String?,
      fromCity: fields[7] as String?,
      fromState: fields[8] as String?,
      fromZip: fields[9] as String?,
      fromCountry: fields[10] as String?,
      fromLat: (fields[11] as num?)?.toDouble(),
      fromLng: (fields[12] as num?)?.toDouble(),
      toAddress: fields[13] as String?,
      toCity: fields[14] as String?,
      toState: fields[15] as String?,
      toZip: fields[16] as String?,
      toCountry: fields[17] as String?,
      toLat: (fields[18] as num?)?.toDouble(),
      toLng: (fields[19] as num?)?.toDouble(),
      trucks: (fields[21] as List?)?.cast<Trucks>(),
      stations: (fields[22] as List?)?.cast<Stations>(),
      isSwapped: fields[23] as bool?,
    )..truck = fields[20] as VehicleModel?;
  }

  @override
  void write(BinaryWriter writer, RouteModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromLocation)
      ..writeByte(2)
      ..write(obj.toLocation)
      ..writeByte(3)
      ..write(obj.distance)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.fromAddress)
      ..writeByte(7)
      ..write(obj.fromCity)
      ..writeByte(8)
      ..write(obj.fromState)
      ..writeByte(9)
      ..write(obj.fromZip)
      ..writeByte(10)
      ..write(obj.fromCountry)
      ..writeByte(11)
      ..write(obj.fromLat)
      ..writeByte(12)
      ..write(obj.fromLng)
      ..writeByte(13)
      ..write(obj.toAddress)
      ..writeByte(14)
      ..write(obj.toCity)
      ..writeByte(15)
      ..write(obj.toState)
      ..writeByte(16)
      ..write(obj.toZip)
      ..writeByte(17)
      ..write(obj.toCountry)
      ..writeByte(18)
      ..write(obj.toLat)
      ..writeByte(19)
      ..write(obj.toLng)
      ..writeByte(20)
      ..write(obj.truck)
      ..writeByte(21)
      ..write(obj.trucks)
      ..writeByte(22)
      ..write(obj.stations)
      ..writeByte(23)
      ..write(obj.isSwapped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrucksAdapter extends TypeAdapter<Trucks> {
  @override
  final typeId = 18;

  @override
  Trucks read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trucks(
      id: (fields[0] as num?)?.toInt(),
      number: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Trucks obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.number);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrucksAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VehicleModelAdapter extends TypeAdapter<VehicleModel> {
  @override
  final typeId = 19;

  @override
  VehicleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleModel(
      id: (fields[0] as num?)?.toInt(),
      samsara_vehicle_id: fields[2] as String?,
      number: fields[1] as String?,
      year: (fields[3] as num?)?.toInt(),
      make: fields[4] as String?,
      model: fields[5] as String?,
      vin: fields[6] as String?,
      licensePlateNumber: fields[7] as String?,
      state: fields[8] as String?,
      type: fields[9] as String?,
      currentPosition: fields[10] as String?,
      readyStatus: fields[11] as String?,
      documents: (fields[15] as List?)?.cast<Documents>(),
      pre_pass_id: fields[12] as String?,
      driver_fuel_id: fields[13] as String?,
      fuel_card_number: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.samsara_vehicle_id)
      ..writeByte(3)
      ..write(obj.year)
      ..writeByte(4)
      ..write(obj.make)
      ..writeByte(5)
      ..write(obj.model)
      ..writeByte(6)
      ..write(obj.vin)
      ..writeByte(7)
      ..write(obj.licensePlateNumber)
      ..writeByte(8)
      ..write(obj.state)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.currentPosition)
      ..writeByte(11)
      ..write(obj.readyStatus)
      ..writeByte(12)
      ..write(obj.pre_pass_id)
      ..writeByte(13)
      ..write(obj.driver_fuel_id)
      ..writeByte(14)
      ..write(obj.fuel_card_number)
      ..writeByte(15)
      ..write(obj.documents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
