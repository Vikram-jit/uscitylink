import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/model/vehicle_model.dart';
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
    _truckController.fetchVehicleById(
      type: widget.type,
      id: widget.id.toString(),
    );
  }

  Widget _buildInfoItem(String title, String value, {IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: TColors.primary.withOpacity(0.8)),
                SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'inactive':
        statusColor = Colors.red;
        break;
      case 'maintenance':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: statusColor.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDocumentCard(Documents? document) {
    // Parse dates if available
    DateTime? issueDate;
    DateTime? expiryDate;

    try {
      if (document?.issueDate != null && document!.issueDate!.isNotEmpty) {
        issueDate = DateTime.tryParse(document.issueDate!);
      }
      if (document?.expireDate != null && document!.expireDate!.isNotEmpty) {
        expiryDate = DateTime.tryParse(document.expireDate!);
      }
    } catch (e) {
      print('Error parsing dates: $e');
    }

    // Check if document is expired
    bool isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

    // Format date for display
    String formatDate(DateTime? date) {
      if (date == null) return 'N/A';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    // Get status color
    Color getStatusColor() {
      if (isExpired) return Colors.red.withOpacity(0.9);
      if (expiryDate == null) return Colors.blueGrey.withOpacity(0.9);

      // Check if expiring soon (within 30 days)
      final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 30) return Colors.orange.withOpacity(0.9);

      return Colors.green.withOpacity(0.9);
    }

    // Get status text
    String getStatusText() {
      if (isExpired) return 'EXPIRED';
      if (expiryDate == null) return 'NO EXPIRY';

      final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 30) return 'EXPIRING SOON';

      return 'VALID';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final file = document?.docType == "server"
              ? "https://msyard.s3.us-west-1.amazonaws.com/images/${document?.file}"
              : "http://52.9.12.189/images/${document?.file}";
          Get.to(() => DocumentDownload(file: file));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Document Icon with Status Indicator
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insert_drive_file,
                      color: TColors.primary,
                      size: 22,
                    ),
                  ),
                  // Status Dot
                  if (expiryDate != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: getStatusColor(),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16),

              // Document Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            document?.title ?? 'Untitled Document',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            getStatusText(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Date Information
                    Row(
                      children: [
                        // Issue Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Issued',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                formatDate(issueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                          margin: EdgeInsets.symmetric(horizontal: 12),
                        ),

                        // Expiry Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expires',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                formatDate(expiryDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isExpired
                                      ? Colors.red.shade700
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Days Counter (if expiring soon)
                        if (expiryDate != null && !isExpired)
                          Container(
                            margin: EdgeInsets.only(left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Days Left',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${expiryDate.difference(DateTime.now()).inDays}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: expiryDate
                                                .difference(DateTime.now())
                                                .inDays <=
                                            30
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8),

              // Chevron Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary,
        elevation: 1,
        centerTitle: true,
        title: Text(
          widget.type == 'truck' ? 'Truck Details' : 'Trailer Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        if (_truckController.detailLoader.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: TColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading vehicle details...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final details = _truckController.details?.value;
        final documents = details?.documents ?? [];

        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Header Card
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TColors.primary.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: TColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.type == "truck"
                            ? Icons.local_shipping
                            : Icons.rv_hookup,
                        size: 34,
                        color: TColors.primary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  details?.number ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              _buildStatusChip(
                                  details?.currentPosition ?? 'Unknown'),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Vehicle ID: ${widget.id}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: TColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${details?.model ?? '-'} • ${details?.make ?? '-'} • ${details?.year ?? '-'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: TColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Basic Information Section
              _buildSectionHeader('Basic Information',
                  'Essential vehicle details and specifications'),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoItem('VIN Number', details?.vin ?? '-',
                        icon: Icons.confirmation_number),
                    _buildInfoItem('Model', details?.model ?? '-',
                        icon: Icons.model_training),
                    _buildInfoItem('Make', details?.make ?? '-',
                        icon: Icons.build),
                    _buildInfoItem('Year', details?.year?.toString() ?? '-',
                        icon: Icons.date_range),
                    _buildInfoItem(
                        'License Plate', details?.licensePlateNumber ?? '-',
                        icon: Icons.credit_card),
                    _buildInfoItem('State', details?.state ?? '-',
                        icon: Icons.location_on),
                    _buildInfoItem('Type', details?.type ?? '-',
                        icon: Icons.category),
                    _buildInfoItem('Pre Pass ID', details?.pre_pass_id ?? '-',
                        icon: Icons.badge),
                  ],
                ),
              ),

              // Fuel Information Section
              SizedBox(height: 20),
              _buildSectionHeader(
                  'Fuel Information', 'Fuel card and related information'),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoItem('Fuel ID', details?.driver_fuel_id ?? '-',
                        icon: Icons.local_gas_station),
                    _buildInfoItem(
                        'Fuel Card Number', details?.fuel_card_number ?? '-',
                        icon: Icons.credit_card),
                  ],
                ),
              ),

              // Documents Section
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${documents.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),

              if (documents.isEmpty)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No documents available',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...documents.map((doc) => _buildDocumentCard(doc)).toList(),

              // Footer Spacing
              SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }
}
