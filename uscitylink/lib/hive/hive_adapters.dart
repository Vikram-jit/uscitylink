import 'package:hive_ce/hive.dart';
import 'package:uscitylink/model/channel_model.dart';
import 'package:uscitylink/model/dashboard_model.dart';
import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/sender_model.dart';
import 'package:uscitylink/model/user_channel_model.dart';
import 'package:uscitylink/model/user_model.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<DashboardModel>(),
  AdapterSpec<Channel>(),
  AdapterSpec<LatestMessage>(),
  AdapterSpec<LatestGroupMessage>(),
  AdapterSpec<GroupDashboard>(),
  AdapterSpec<SenderModel>(),
  AdapterSpec<UserChannelModel>(),
  AdapterSpec<MessageModel>(),
  AdapterSpec<Group>(),
  AdapterSpec<GroupChannel>(),
  AdapterSpec<GroupModel>(),
  AdapterSpec<UserModel>(),
  AdapterSpec<ChannelModel>(),
  AdapterSpec<CountModel>(),
])
class HiveAdapters {}
