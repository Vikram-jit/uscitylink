import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/group_members_model.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class MemberSearch extends StatefulWidget {
  final String groupId;
  final List<GroupMembers> groupMembers;

  MemberSearch({super.key, required this.groupId, required this.groupMembers});

  @override
  State<MemberSearch> createState() => _MemberSearchState();
}

class _MemberSearchState extends State<MemberSearch> {
  List<GroupMembers> filteredMembers = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredMembers = widget.groupMembers;
    _searchController.addListener(_filterMembers);
  }

  void _filterMembers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredMembers = widget.groupMembers.where((member) {
        return member.userProfile?.username?.toLowerCase().contains(query) ??
            false;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMembers);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort group members by username
    filteredMembers.sort((a, b) =>
        a.userProfile?.username?.compareTo(b.userProfile?.username ?? '') ?? 0);

    // Step 2: Group members by first letter of username
    Map<String, List<GroupMembers>> groupedMembers = {};
    for (var member in filteredMembers) {
      String firstLetter = member.userProfile?.username?[0].toUpperCase() ?? '';
      if (groupedMembers[firstLetter] == null) {
        groupedMembers[firstLetter] = [];
      }
      groupedMembers[firstLetter]?.add(member);
    }

    // Step 3: Get the list of sections (A, B, C...)
    List<String> sections = groupedMembers.keys.toList();

    return Container(
      height: Get.height * 0.90, // Take 90% of the screen height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
              SizedBox(
                width: TDeviceUtils.getScreenWidth(context) * 0.18,
              ),
              Text(
                'Search members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(
            height: TDeviceUtils.getScreenHeight() * 0.02,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                fillColor: Colors.grey.shade300,
                filled: true,
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.black,
                  size: 18,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 1.0),
                constraints: BoxConstraints(minHeight: 30, maxHeight: 30),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sections.length,
              itemBuilder: (context, sectionIndex) {
                String section = sections[sectionIndex];
                List<GroupMembers> members = groupedMembers[section]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        section, // Display the section header (e.g., A, B, C)
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    // Step 4: Display members for that section
                    for (var member in members) ...[
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 5),
                        leading: CircleAvatar(
                          child: Text(
                            "${member.userProfile?.username?[0]}",
                            style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.grey.shade400,
                        ),
                        title: Text("${member.userProfile?.username}"),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: SizedBox(
                          width: TDeviceUtils.getScreenWidth(context) * 0.75,
                          child: Divider(
                            color: Colors.grey.shade300,
                            height: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
