import 'package:chat_app/modules/home/controllers/template_controller.dart';

import 'package:chat_app/modules/home/models/template_model.dart';
import 'package:chat_app/widgets/container_header.dart';
import 'package:chat_app/widgets/data_table.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateScreen extends StatelessWidget {
  TemplateScreen({super.key});
  final TemplateController _templateController = Get.put(TemplateController());

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6.0),
          bottomRight: Radius.circular(6.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ContainerHeader(
              title: "Templates",
              subtitle: "Manage and monitor all templates",

              showActionButton: true,
              actionButtonText: "New Template",
              actionButtonIcon: Icons.add,
              onActionPressed: () {},
            ),

            const SizedBox(height: 24),

            // Table Container
            Expanded(
              child: FutureBuilder(
                future: _templateController.getTemplates(page: 1),
                builder: (context, snapshot) {
                  if (!snapshot.hasData &&
                      _templateController.isLoading.isTrue) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  return ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.81,

                        child: Obx(() {
                          final templates = _templateController.templates.value;

                          return TableContainer<Template>(
                            data: templates,

                            config: DataTableConfig<Template>(
                              isScrollable: true,
                              title: "Templates",
                              columns: [
                                DataColumn(
                                  label: Text(
                                    "TITLE",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "BODY",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),

                                DataColumn(
                                  label: Text(
                                    "ATTACHMENT",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),

                                DataColumn(
                                  label: Text(
                                    "ACTION",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                              buildRows: (data) => data.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final template = entry.value;
                                final isAlternate = index % 2 == 1;

                                return DataRow(
                                  color:
                                      MaterialStateProperty.resolveWith<Color?>(
                                        (Set<MaterialState> states) =>
                                            isAlternate
                                            ? Colors.grey.shade50
                                            : null,
                                      ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        template.name ?? "-",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        template.body ?? "-",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    DataCell(
                                      SizedBox(
                                        width: 200,
                                        child: (template.url ?? "").isNotEmpty
                                            ? MediaComponent(
                                                url:
                                                    "https://ciity-sms.s3.us-west-1.amazonaws.com/${template.url}",
                                              )
                                            : Text("-"),
                                      ),
                                    ),

                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Tooltip(
                                              message: "DEACTIVATE",
                                              textStyle: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                              child: IconButton(
                                                onPressed: () {},
                                                icon: Icon(Icons.edit),
                                              ),
                                            ),
                                            Tooltip(
                                              message: "REMOVE",
                                              textStyle: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                              child: IconButton(
                                                onPressed: () {},
                                                icon: Icon(Icons.delete),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              totalItems: _templateController
                                  .totalItems, // Total items in database
                              currentPage:
                                  _templateController.currentPage.value,
                              itemsPerPage: _templateController.itemsPerPage,
                              onPageChanged: (page) {
                                _templateController.currentPage.value = page;
                                _templateController.getTemplates(page: page);
                              },

                              showHeader: false,
                              showPagination: true,
                              showActions: true,
                              primaryColor: const Color(0xFF4A154B),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
