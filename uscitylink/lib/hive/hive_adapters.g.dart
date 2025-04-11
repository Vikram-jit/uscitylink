// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class DashboardModelAdapter extends TypeAdapter<DashboardModel> {
  @override
  final int typeId = 0;

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
    );
  }

  @override
  void write(BinaryWriter writer, DashboardModel obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.latestGroupMessage);
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
  final int typeId = 1;

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
  final int typeId = 2;

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
  final int typeId = 3;

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
  final int typeId = 4;

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
  final int typeId = 5;

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
  final int typeId = 6;

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
  final int typeId = 7;

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
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(22)
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
      ..write(obj.r_message);
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
  final int typeId = 8;

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
  final int typeId = 9;

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
  final int typeId = 10;

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
  final int typeId = 11;

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
  final int typeId = 12;

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
  final int typeId = 13;

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
