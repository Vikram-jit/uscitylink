import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/controller/template_controller.dart';
import 'package:uscitylink/model/template_model.dart';

class TemplateDialog {
  static void showDriverBottomSheet(
      BuildContext context,
      TemplateController _templateController,
      StaffchatController _staffchatController) {
    _showFullPageBottomSheet(
        context, _templateController, _staffchatController);
  }

  static void showGroupTemplateBottomSheet(
      BuildContext context,
      TemplateController _templateController,
      TextEditingController _controller,
      GroupController _groupController) {
    _showFullGroupPageBottomSheet(
        context, _templateController, _controller, _groupController);
  }

  static void _showFullGroupPageBottomSheet(
      BuildContext context,
      TemplateController _templateController,
      TextEditingController _controller,
      GroupController _groupController) {
    // Ensure you're in the right context
    if (context != null) {
      _templateController.getTemplates(_templateController.currentPage.value,
          _templateController.searchController.text);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Choose template",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 40,
                    child: TextField(
                      controller: _templateController.searchController,
                      onChanged: (query) {
                        _templateController.onSearchChanged(query);
                      },
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
                  SizedBox(
                    height: 15,
                  ),
                  Expanded(
                    child: Obx(
                      () {
                        return ListView.builder(
                          controller: ScrollController()
                            ..addListener(() {
                              if (_templateController.loading.value) return;

                              if (_templateController.currentPage.value <
                                  _templateController.totalPages.value) {
                                if (_templateController.templates.isNotEmpty &&
                                    _templateController.templates.last ==
                                        _templateController.templates[
                                            _templateController
                                                    .templates.length -
                                                1]) {
                                  _templateController.getTemplates(
                                      _templateController.currentPage.value + 1,
                                      _templateController
                                          .searchController.text);
                                }
                              }
                            }),
                          itemBuilder: (context, index) {
                            Template template =
                                _templateController.templates[index];
                            if (_templateController.templates.length == 0) {
                              return Center(
                                child: Text("No Driver Found"),
                              );
                            }
                            return ListTile(
                              onTap: () {
                                _controller.text = template?.body ?? "";
                                _groupController.templateurl.value =
                                    template?.url ?? "";
                                Get.back();
                                Get.back();
                              },
                              title: Text("${template?.name}"),
                              subtitle: Text(
                                "${template?.body}",
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(Icons.arrow_right),
                            );
                          },
                          itemCount: _templateController.templates.length,
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 40,
                          child: TextButton(
                            onPressed: () {
                              _templateController.templates.clear();
                              Get.back();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
          );
        },
      );
    } else {
      print("Context is not available for the bottom sheet.");
    }
  }

  static void _showFullPageBottomSheet(
      BuildContext context,
      TemplateController _templateController,
      StaffchatController _staffchatController) {
    // Ensure you're in the right context
    if (context != null) {
      _templateController.getTemplates(_templateController.currentPage.value,
          _templateController.searchController.text);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Choose template",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 40,
                    child: TextField(
                      controller: _templateController.searchController,
                      onChanged: (query) {
                        _templateController.onSearchChanged(query);
                      },
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
                  SizedBox(
                    height: 15,
                  ),
                  Expanded(
                    child: Obx(
                      () {
                        return ListView.builder(
                          controller: ScrollController()
                            ..addListener(() {
                              if (_templateController.loading.value) return;

                              if (_templateController.currentPage.value <
                                  _templateController.totalPages.value) {
                                if (_templateController.templates.isNotEmpty &&
                                    _templateController.templates.last ==
                                        _templateController.templates[
                                            _templateController
                                                    .templates.length -
                                                1]) {
                                  _templateController.getTemplates(
                                      _templateController.currentPage.value + 1,
                                      _templateController
                                          .searchController.text);
                                }
                              }
                            }),
                          itemBuilder: (context, index) {
                            Template template =
                                _templateController.templates[index];
                            if (_templateController.templates.length == 0) {
                              return Center(
                                child: Text("No Driver Found"),
                              );
                            }
                            return ListTile(
                              onTap: () {
                                _staffchatController.messageController.text =
                                    template?.body ?? "";
                                _staffchatController.templateUrl.value =
                                    template?.url ?? "";
                                Get.back();
                                Get.back();
                              },
                              title: Text("${template?.name}"),
                              subtitle: Text(
                                "${template?.body}",
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(Icons.arrow_right),
                            );
                          },
                          itemCount: _templateController.templates.length,
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 40,
                          child: TextButton(
                            onPressed: () {
                              _templateController.templates.clear();
                              Get.back();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
          );
        },
      );
    } else {
      print("Context is not available for the bottom sheet.");
    }
  }
}
