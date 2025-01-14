import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/template_controller.dart';
import 'package:uscitylink/model/template_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/staff/view/template/template_details_view.dart';

class StaffTemplatesView extends StatelessWidget {
  StaffTemplatesView({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TemplateController _templateController = Get.put(TemplateController());
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _templateController.getTemplates(_templateController.currentPage.value);
    });
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        onPressed: () {
          Get.to(() => TemplateDetailsView(template: Template()));
        },
        label: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
            Text("Add Template", style: TextStyle(color: Colors.white))
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              ),
              backgroundColor: TColors.primaryStaff,
              title: Text(
                "Templates",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Container(
              height: 60.0,
              color: TColors.primaryStaff,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search templates...",
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
                  ),
                  SizedBox(width: 10),
                  // ElevatedButton(
                  //   onPressed: () {},
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.amber,
                  //     shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(5)),
                  //     padding: EdgeInsets.zero,
                  //   ),
                  //   child: Text(
                  //     "Add",
                  //     style: TextStyle(color: Colors.white, fontSize: 16),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        return ListView.builder(
          controller: ScrollController()
            ..addListener(() {
              // Don't load more if data is already loading
              if (_templateController.loading.value) return;

              // Check if there are more pages and trigger data fetch if necessary
              if (_templateController.currentPage.value <
                  _templateController.totalPages.value) {
                if (_templateController.templates.isNotEmpty &&
                    _templateController.templates.last ==
                        _templateController.templates[
                            _templateController.templates.length - 1]) {
                  _templateController
                      .getTemplates(_templateController.currentPage.value + 1);
                }
              }
            }),
          itemCount: _templateController.templates?.length,
          itemBuilder: (context, index) {
            var template = _templateController.templates?[index];
            return ListTile(
              onTap: () {
                Get.to(() => TemplateDetailsView(template: template!));
              },
              trailing: Icon(Icons.arrow_right),
              title: Text("${template?.name} "),
              subtitle: Text(
                "${template?.body}",
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        );
      }),
    );
  }
}
