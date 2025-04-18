import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

class VehicleDetails extends StatefulWidget {
  final int id;
  final String type;
  const VehicleDetails({super.key, required this.id, required this.type});

  @override
  State<VehicleDetails> createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> {
  TruckController _truckController = Get.put(TruckController());

  @override
  void initState() {
    super.initState();

    _callApi();
  }

  void _callApi() {
    // Fetch vehicle by ID
    _truckController.fetchVehicleById(
      type: widget.type,
      id: widget.id.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: TColors.primary,
          centerTitle: true,
          title: Text(
            widget.type == 'truck' ? 'Truck Details' : 'Trailer Details',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Obx(() {
          if (_truckController.detailLoader.value)
            return Center(
              child: CircularProgressIndicator(),
            );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Background Container (fixed height)
              Container(
                color: TColors.primary,
                height: TDeviceUtils.getScreenHeight() *
                    0.2, // This is the height of the container
              ),
              // Use a Container to give Stack a bounded space (to avoid infinite space issues)
              Container(
                width: double.infinity,
                height: TDeviceUtils.getScreenHeight() * 0.10,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -160,
                      left: 5,
                      right: 5,
                      child: Card(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: TColors.white,
                        child: SizedBox(
                          height: TDeviceUtils.getScreenHeight() * 0.35,
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                height: 40,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 10.0),
                                      child: Row(
                                        children: [
                                          Icon(widget.type == "truck"
                                              ? Icons.local_shipping
                                              : Icons.rv_hookup),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                              "Number: ${_truckController.details?.value?.number}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 10.0),
                                      child: Container(
                                          width: 70,
                                          height: 25,
                                          decoration: BoxDecoration(
                                              color: TColors.success,
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: Center(
                                              child: Text(
                                            "${_truckController.details?.value?.currentPosition}",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600),
                                          ))),
                                    )
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: TColors.grey,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                      width: 1,
                                                      color: Colors
                                                          .grey.shade400)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.model_training),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Model",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.model}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                      width: 1,
                                                      color: Colors
                                                          .grey.shade400)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.calendar_month),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Make",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.make}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                      width: 1,
                                                      color: Colors
                                                          .grey.shade400)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.schedule),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Year",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.year}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Vin Number",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.vin}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Type",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.type == null ? '-' : _truckController.details?.value?.type}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "State",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.state}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, left: 16, right: 16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "License Plate Number",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.licensePlateNumber}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Pre Pass Id",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.pre_pass_id ?? "-"}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, left: 16, right: 16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Fuel Id",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.driver_fuel_id ?? "-"}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Fuel Card Number",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        width: 50,
                                                        color: Colors.amber,
                                                      ),
                                                      Text(
                                                          "${_truckController.details?.value?.fuel_card_number ?? "-"}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey))
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 80,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Documents",
                        style: Theme.of(context).textTheme.headlineMedium),
                    Container(
                      decoration: BoxDecoration(
                          color: TColors.primary,
                          borderRadius: BorderRadius.circular(2)),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            "${_truckController.details?.value.documents?.length ?? 0}",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Divider(
                height: 1,
              ),
              if (_truckController.details?.value?.documents?.length == 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text("No Document Found.")),
                ),

              Expanded(
                  child: ListView.builder(
                      itemCount:
                          _truckController.details?.value?.documents?.length ??
                              0,
                      itemBuilder: (context, index) {
                        final document =
                            _truckController.details?.value?.documents?[index];

                        return InkWell(
                          onTap: () {
                            final file = document?.docType == "server"
                                ? "https://msyard.s3.us-west-1.amazonaws.com/images/${document?.file}"
                                : "http://52.9.12.189/images/${document?.file}";

                            Get.to(() => DocumentDownload(file: file));
                          },
                          child: Card(
                            color: Colors.white,
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 2.0),
                            child: ListTile(
                              leading: Icon(Icons.remove_red_eye),
                              title: Text('${document?.title}'),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16.0),
                              trailing: Icon(Icons.arrow_right),
                            ),
                          ),
                        );
                      }))
            ],
          );
        }));
  }
}
