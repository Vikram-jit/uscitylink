import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/drawer/driver_custom_drawer.dart';
import 'package:uscitylink/views/driver/views/chats/channels_tab.dart';
import 'package:uscitylink/views/driver/views/group/groups_tab.dart';
import 'package:badges/badges.dart' as badges;

const double _kTabsCardOverflow = 20;

typedef ChatTargetSelected = void Function(
    String channelId, String? groupId, String name);

class ChatView extends StatefulWidget {
  final bool selectionMode;
  final ChatTargetSelected? onTargetSelected;

  const ChatView({
    super.key,
    this.selectionMode = false,
    this.onTargetSelected,
  });

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  SocketService socketService = Get.find<SocketService>();
  ChannelController channelController = Get.find<ChannelController>();
  GroupController groupController = Get.put(GroupController());
  DashboardController _dashboardController = Get.find<DashboardController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final NetworkService _networkService;
  late final HiveController _hiveController;
  late final MessageController _messageController;
  @override
  void initState() {
    if (Get.isRegistered<MessageController>()) {
      _messageController = Get.find<MessageController>();
      print('✅ _messageController found and assigned');
    } else {
      _messageController = Get.put(MessageController());
      print('🆕 _messageController registered and assigned');
    }
    if (Get.isRegistered<NetworkService>()) {
      _networkService = Get.find<NetworkService>();
      print('✅ NetworkService found and assigned');
    } else {
      _networkService = Get.put(NetworkService());
      print('🆕 NetworkService registered and assigned');
    }
    if (Get.isRegistered<HiveController>()) {
      _hiveController = Get.find<HiveController>();
      print('✅ NetworkService found and assigned');
    } else {
      _hiveController = Get.put(HiveController());
      print('🆕 NetworkService registered and assigned');
    }

    WidgetsBinding.instance.addObserver(this);

    // ever(_networkService.connected, (_) {
    //   print("Network changed: ${_networkService.connected.value}");
    //   if (_networkService.connected.value) {
    //     socketService.connectSocket();
    //   }
    // });
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes to refetch channels when the Channels tab is selected
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        channelController.getUserChannels();
      }
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        groupController.getUserGroups();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will run after the widget tree is built, avoiding the error
      channelController.getUserChannels();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        //   if (_hiveController.isProcessing.value == false) {
        socketService.socket.disconnect();
        //  }
      }
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
          //socketService.sendQueueMessage();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // if (channelController.initialized) {
    //   channelController.dispose();
    // }

    // groupController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        key: _scaffoldKey,
        body: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _Header(
                      connected: _networkService.connected,
                      onBack: () {
                        if (!socketService.isConnected.value) {
                          socketService.socket.connect();
                        }
                        Get.back();
                      },
                    ),
                    const SizedBox(height: _kTabsCardOverflow),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: _TabsCard(
                    tabController: _tabController,
                    channelController: channelController,
                    onTap: (index) => channelController.setInnerTabIndex(index),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: _kTabsCardOverflow - 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ChannelTab(
                    channelController: channelController,
                    selectionMode: widget.selectionMode,
                    onTargetSelected: widget.onTargetSelected,
                  ),
                  GroupTab(
                    groupController: groupController,
                    selectionMode: widget.selectionMode,
                    onTargetSelected: widget.onTargetSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
        drawer: DriverCustomDrawer(
          globalKey: _scaffoldKey,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final RxBool connected;
  final VoidCallback onBack;

  const _Header({required this.connected, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, topInset + 12, 20, 46),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TColors.navyHeader, TColors.navyHeaderDeep],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -50, right: -30, child: _orb(140, 0.06)),
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                ),
                Expanded(
                  child: Obx(() {
                    if (connected.value == false) {
                      return Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Waiting for network",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }
                    return const Text(
                      'Chats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TabsCard extends StatelessWidget {
  final TabController tabController;
  final ChannelController channelController;
  final ValueChanged<int> onTap;

  const _TabsCard({
    required this.tabController,
    required this.channelController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        height: 44,
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          indicator: BoxDecoration(
            color: TColors.navyHeader,
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          controller: tabController,
          tabs: [
            Obx(() {
              if (channelController.channelCount.value > 0) {
                return Tab(
                  child: badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -10, end: -14),
                    badgeContent: Text(
                      '${channelController.channelCount.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle:
                        const badges.BadgeStyle(badgeColor: Color(0xFFEF4444)),
                    child: const Text('Channels'),
                  ),
                );
              }
              return const Tab(text: 'Channels');
            }),
            Obx(() {
              if (channelController.groupCount.value > 0) {
                return Tab(
                  child: badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -10, end: -14),
                    badgeContent: Text(
                      '${channelController.groupCount.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle:
                        const badges.BadgeStyle(badgeColor: Color(0xFFEF4444)),
                    child: const Text('Groups'),
                  ),
                );
              }
              return const Tab(text: 'Groups');
            }),
          ],
        ),
      ),
    );
  }
}
