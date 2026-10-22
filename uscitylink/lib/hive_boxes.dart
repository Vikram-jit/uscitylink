class HiveBoxes {
  static const String driverDashboard = 'driver_dashboard_box';
  static const String userChannel = 'user_channel_box';
  static const String channelMessages = 'channel_messages_box';
  static const String queueMessageBox = 'queue_message_box';
  static const String mediaQueueBox = 'media_queue_box';
  static const String truckLocationBox = 'truck_location_box';
  static const String stationsBox = 'stations_box';
  static const String lastUpdatedBox = 'last_updated_box';

  // Cached chat pages ('<channelId>_<page>' -> messages) used by MessageController. Not the same
  // box as channelMessages above: it holds the actual conversations.
  static const String channelMessagesCache = 'channelMessages';

  // Fuel-stations / route data (RouteController)
  static const String routeMetadata = 'metadata_box';
  static const String truckFallback = 'truck_fallback';
  static const String stationsFallback = 'stations_fallback';
  static const String lastUpdatedFallback = 'last_updated_fallback';
  static const String metadataFallback = 'metadata_fallback';

  // Every box the app opens. Logout deletes all of them (see clearAllHiveData), so a box added
  // above must be added here too — test/hive_cleaner_test.dart checks the two stay in sync.
  static const List<String> all = [
    driverDashboard,
    userChannel,
    channelMessages,
    queueMessageBox,
    mediaQueueBox,
    truckLocationBox,
    stationsBox,
    lastUpdatedBox,
    channelMessagesCache,
    routeMetadata,
    truckFallback,
    stationsFallback,
    lastUpdatedFallback,
    metadataFallback,
  ];
}
