import 'dart:io';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/template_controller.dart';
import 'package:uscitylink/model/template_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class TemplateDetailsView extends StatefulWidget {
  Template template;
  TemplateDetailsView({super.key, required this.template});

  @override
  State<TemplateDetailsView> createState() => _TemplateDetailsViewState();
}

class _TemplateDetailsViewState extends State<TemplateDetailsView> {
  File? pickedImage;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();
  String url = "";
  TemplateController _templateController = Get.find<TemplateController>();
  @override
  void initState() {
    // TODO: implement initState
    if (widget.template != null) {
      _nameController.text = widget.template.name ?? "";
      _bodyController.text = widget.template.body ?? "";
      setState(() {
        url = widget.template.url ?? "";
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        onPressed: () {
          _templateController.templateAction({
            "id": widget?.template?.id,
            "name": _nameController.text,
            "body": _bodyController.text,
            "url": url,
            "action": widget?.template?.id == null ? "add" : "update",
          }, pickedImage);
        },
        label: Row(
          children: [
            Text(
                "${widget.template?.name != null ? "Update Template" : "Submit"} ",
                style: TextStyle(color: Colors.white))
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
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
                "${widget?.template?.name ?? "Add New Template"}",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              actions: [
                if (widget.template?.id != null)
                  IconButton(
                    onPressed: () {
                      Get.defaultDialog(
                        backgroundColor: Colors.white,
                        title: "Delete Item",

                        titleStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        middleText:
                            "Are you sure you want to delete \"${widget?.template?.name}\"? This action cannot be undone.",
                        middleTextStyle: TextStyle(fontSize: 16),
                        onCancel: () {
                          //Get.back(); // Close the dialog when the user presses cancel
                        },
                        onConfirm: () {
                          _templateController.templateAction({
                            "id": widget?.template?.id,
                            "name": _nameController.text,
                            "body": _bodyController.text,
                            "url": url,
                            "action": "delete",
                          }, pickedImage);
                        },
                        textCancel: "Cancel",
                        textConfirm: "Delete",
                        confirmTextColor: Colors.white,
                        buttonColor:
                            Colors.red, // Button color for confirmation
                        cancelTextColor: Colors.black, // Cancel button color
                        radius: 5.0, // Border radius of the dialog
                      );
                    },
                    icon: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Name",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: 6,
              ),
              Container(
                height: 40,
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Enter template name",
                    hintStyle: TextStyle(color: Colors.black45),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                          color: Colors.black,
                          width: 2), // Set your desired color and width
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: Colors.grey.shade500, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: TColors.primaryStaff, width: 2),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
              SizedBox(
                height: 6,
              ),
              Text(
                "Body",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: 6,
              ),
              TextField(
                controller: _bodyController,
                minLines: 5,
                maxLines: null, // Allows infinite number of lines
                keyboardType: TextInputType
                    .multiline, // Make the keyboard support multiline
                decoration: InputDecoration(
                  hintText: "Enter template body",
                  hintStyle: TextStyle(color: Colors.black45),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                        color: Colors.black,
                        width: 2), // Set border color and width
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                        BorderSide(color: Colors.grey.shade500, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                        BorderSide(color: TColors.primaryStaff, width: 2),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
              SizedBox(
                height: 6,
              ),
              Row(
                children: [
                  Text(
                    "Attachment",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    onPressed: () {
                      _pickerOption();
                    },
                    icon: Icon(
                      Icons.add,
                    ),
                  ),
                  if (url.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          url = "";
                        });
                      },
                      icon: Icon(
                        Icons.close,
                      ),
                    )
                ],
              ),
              if (pickedImage != null)
                Container(
                  width: double.infinity,
                  child: Image.file(
                    pickedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              if (pickedImage == null && url.isNotEmpty)
                Container(
                  width: double.infinity,
                  child: Image.network(
                    "${Constant.aws}/$url",
                    fit: BoxFit.contain,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        // Image has finished loading
                        return child;
                      } else {
                        // Show a loading indicator while the image is loading
                        return Center(
                          child: CircularProgressIndicator(
                            color: TColors.primaryStaff,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      }
                    },
                  ),
                ),
              SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }

  _pickerOption() {
    showAdaptiveActionSheet(
      context: context,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: const Text(
            'Camera',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          onPressed: (_) {
            Navigator.of(context).pop();
            _pickImage(ImageSource.camera);
          },
        ),
        BottomSheetAction(
          title: const Text(
            'Gallery',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          onPressed: (_) {
            Navigator.of(context).pop();
            _pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  _pickImage(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);

      if (photo == null) return;

      final tempImage = File(photo.path);

      setState(() {
        pickedImage = tempImage;
      });
    } catch (e) {
      return ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
