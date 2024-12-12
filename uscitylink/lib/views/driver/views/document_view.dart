import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class DocumentView extends StatelessWidget {
  DocumentView({super.key});
  final TruckController _controller = Get.put(TruckController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
            110), // Increased height for AppBar and search
        child: Column(
          children: [
            AppBar(
              backgroundColor: TColors.primary,
              title: Text(
                "Documents",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Logic for triggering the search field can go here
                    print("Search button pressed");
                  },
                ),
              ],
            ),
            Container(
              height: 50.0, // Height for the search bar
              color: TColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search Documents...",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.all(0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        // Show loading spinner if data is being fetched
        if (_controller.isLoading.value && _controller.trucks.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          controller: ScrollController()
            ..addListener(() {
              // Load more trucks when scrolled to the bottom
              if (_controller.isLoading.value)
                return; // Avoid triggering load if already loading
              if (_controller.currentPage.value <
                      _controller.totalPages.value &&
                  _controller.isLoading.value == false) {
                // When scrolled to the bottom, load next page
                if (_controller.trucks.isNotEmpty &&
                    _controller.trucks.last ==
                        _controller.trucks[_controller.trucks.length - 1]) {
                  _controller.fetchTrucks(
                      page: _controller.currentPage.value + 1);
                }
              }
            }),
          itemCount: _controller.trucks.length +
              1, // Add 1 for the loading spinner at the bottom
          itemBuilder: (context, index) {
            if (index == _controller.trucks.length) {
              // Show loading spinner at the bottom while fetching more trucks
              if (_controller.currentPage.value <
                  _controller.totalPages.value) {
                return Center(child: CircularProgressIndicator());
              } else {
                return SizedBox(); // No more pages
              }
            }

            final truck = _controller.trucks[index];
            return Card(
              elevation:
                  2.0, // You can adjust the elevation value here for more/less shadow
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(0), // Optional: For rounded corners
              ),
              margin: EdgeInsets.symmetric(
                vertical: 5.0,
              ), // Optional: For spacing around the card
              child: ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('${truck.number}'),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                trailing: Icon(Icons.arrow_right), // Add padding if needed
              ),
            );
          },
        );
      }),
    );
  }
}
