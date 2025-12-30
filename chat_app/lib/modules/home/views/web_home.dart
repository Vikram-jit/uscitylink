import 'package:chat_app/modules/home/views/MessageBubble.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class WebHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Channels
          Container(
            width: 250,
            color: AppColors.primary,
            child: _buildLeftSidebar(),
          ),
          // Chat area
          Expanded(
            child: Container(
              color: AppColors.bg,
              child: Center(
                child: Text(
                  "Web Main Chat Area",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 70,
      color: const Color(0xFF3F0E40),
      child: Column(
        children: [
          // Top App Icons
          Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.circle, color: Colors.white, size: 30),
              onPressed: () {},
            ),
          ),

          // Main Navigation Icons
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sidebarIcon(Icons.home_filled, 'Home', isActive: true),
                _sidebarIcon(Icons.search, 'Search'),
                _sidebarIcon(Icons.add, 'Create'),
                _sidebarIcon(Icons.group, 'Teams'),
                _sidebarIcon(Icons.notifications, 'Notifications'),
                const SizedBox(height: 20),
                _sidebarIcon(Icons.help_outline, 'Help'),
                _sidebarIcon(Icons.more_vert, 'More'),
              ],
            ),
          ),

          // Bottom User Profile
          Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: IconButton(
              icon: const CircleAvatar(
                radius: 15,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=1',
                ),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, String tooltip, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
          size: 24,
        ),
        tooltip: tooltip,
        onPressed: () {},
      ),
    );
  }

  Widget _buildChannelSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF4A154B),
      child: Column(
        children: [
          // Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Flutter Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.expand_more, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Channels List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 16),
              children: [
                // Threads Section
                _buildSectionHeader('Threads', Icons.chat_bubble_outline),

                // Channels Section
                _buildSectionHeader('Channels', Icons.expand_more),
                _buildChannelItem('#', 'general'),
                _buildChannelItem('#', 'random'),
                _buildChannelItem('#', 'flutter-help'),
                _buildChannelItem('#', 'design'),
                _buildChannelItem('#', 'announcements'),

                // Add Channel
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Add channels',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Direct Messages Section
                _buildSectionHeader('Direct Messages', Icons.expand_more),
                _buildDirectMessageItem('John Doe', true),
                _buildDirectMessageItem('Jane Smith', false),
                _buildDirectMessageItem('Bob Johnson', true),
                _buildDirectMessageItem('Alice Brown', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(Icons.add, color: Colors.white54, size: 18),
        ],
      ),
    );
  }

  Widget _buildChannelItem(
    String prefix,
    String name, {
    bool isSelected = false,
  }) {
    return Container(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.transparent,
      child: ListTile(
        leading: Text(
          prefix,
          style: TextStyle(color: Colors.white54, fontSize: 20),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.more_horiz, color: Colors.white54, size: 18)
            : null,
        onTap: () {},
      ),
    );
  }

  Widget _buildDirectMessageItem(String name, bool isOnline) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?img=${name.hashCode % 70}',
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A154B), width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _buildMessageArea() {
    return Expanded(
      child: Column(
        children: [
          // Channel Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Text(
                  '# ss',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.people_outline, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: const [
                  MessageBubble(
                    name: "John",
                    time: "2:30 PM",
                    message: "Hello team! How is the project going?",
                    isMe: false,
                  ),
                  MessageBubble(
                    name: "John",
                    time: "2:30 PM",
                    message: "Hello team! How is the project going?",
                    isMe: false,
                  ),
                  MessageBubble(
                    name: "John",
                    time: "2:30 PM",
                    message: "Hello team! How is the project going?",
                    isMe: false,
                  ),
                  MessageBubble(
                    name: "John",
                    time: "2:30 PM",
                    message: "Hello team! How is the project going?",
                    isMe: false,
                  ),
                ],
              ),
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Message #}',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.attach_file,
                                color: Colors.grey,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _sendMessage(value);
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    // Implement message sending logic
    print('Sending message: $text');
  }
}
