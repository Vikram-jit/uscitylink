import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/pay_controller.dart';
import 'package:uscitylink/services/document_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

const double _kSearchCardOverflow = 20;

class DriverPayView extends StatelessWidget {
  DriverPayView({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PayController _payController = Get.put(PayController());

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _payController.fetchTrucks(page: _payController.currentPage.value);
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        key: _scaffoldKey,
        body: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _Header(
                        onRefresh: () => _payController.fetchTrucks(page: 1)),
                    const SizedBox(height: _kSearchCardOverflow),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: _SearchCard(controller: _payController),
                ),
              ],
            ),
            const SizedBox(height: _kSearchCardOverflow + 16),
            Expanded(
              child: Obx(() {
                if (_payController.isLoading.value) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: TColors.navyHeader));
                }
                return RefreshIndicator(
                  color: TColors.navyHeader,
                  onRefresh: () => _payController.fetchTrucks(page: 1),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          controller: ScrollController()
                            ..addListener(() {
                              if (_payController.isLoading.value) return;
                              if (_payController.currentPage.value <
                                  _payController.totalPages.value) {
                                if (_payController.pays.isNotEmpty &&
                                    _payController.pays.last ==
                                        _payController.pays[
                                            _payController.pays.length - 1]) {
                                  _payController.fetchTrucks(
                                      page: _payController.currentPage.value +
                                          1);
                                }
                              }
                            }),
                          itemCount: _payController.pays.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PayTripCard(pay: _payController.pays[index]),
                            );
                          },
                        ),
                      ),
                      _SummaryFooter(controller: _payController),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;

  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, topInset + 12, 12, 46),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TColors.navyHeader, TColors.navyHeaderDeep],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -50, right: -30, child: _orb(140, 0.06)),
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Pay Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 20, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final PayController controller;

  const _SearchCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: "Search trip...",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F6FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  final PayController controller;

  const _SummaryFooter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Trips',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(
                '${controller.totalItems}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Pay',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(
                '\$${controller.totalAmount}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TColors.navyHeader),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayTripCard extends StatelessWidget {
  final Pay pay;

  const _PayTripCard({required this.pay});

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = pay.payment_status == "paid";
    final statusColor =
        isPaid ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final startDate = _formatDate(_parseDate(pay.startDate));
    final endDate = _formatDate(_parseDate(pay.endDate));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TColors.navyHeader.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 18, color: TColors.navyHeader),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Trip #${pay.tripId}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pay.payment_status?.toUpperCase() ?? 'N/A',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8, left: 48),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('$startDate — $endDate',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F1F4)),
            const SizedBox(height: 14),
            _sectionLabel('Basic Details'),
            const SizedBox(height: 10),
            _kv('Pay Rate (cents)', "${pay.pay_rate ?? 0}.00"),
            const SizedBox(height: 8),
            _kv('Layover', "+${pay.layover ?? 0.00}",
                valueColor: const Color(0xFF16A34A)),
            const SizedBox(height: 8),
            _kv(
              'Adjustment',
              "${pay.adjustment_sign ?? ""}${pay.adjustment ?? 0.00}",
              valueColor: pay.adjustment_sign == "-"
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A),
            ),
            const SizedBox(height: 8),
            _kv('Other Pay', "+${pay.other_pay ?? 0.00}",
                valueColor: const Color(0xFF16A34A)),
            const SizedBox(height: 8),
            _kv('Driver Advance', "-${pay.driver_addv ?? 0.00}",
                valueColor: const Color(0xFFDC2626)),
            const SizedBox(height: 18),
            _sectionLabel('Route Summary'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: _routeHeader('Pickup', TextAlign.start)),
                      Expanded(
                          flex: 2, child: _routeHeader('Drop', TextAlign.start)),
                      Expanded(child: _routeHeader('Mileage', TextAlign.end)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  if (pay.locations != null && pay.locations!.isNotEmpty)
                    ...pay.locations!.map((location) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${location.pickupLocation}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800),
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${location.deliveryLocation}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${location.mileage}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                        ))
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text('-',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500))),
                          Expanded(
                              flex: 2,
                              child: Text('-',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500))),
                          Expanded(
                              child: Text('0.0',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _kv('Total Mileage', "${pay.mileage ?? 0.00}"),
            if ((pay.note ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              _sectionLabel('Note'),
              const SizedBox(height: 8),
              Text(
                "${pay.note}",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: TColors.navyHeader.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800),
                  ),
                  Text(
                    "\$${pay.amount}",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: TColors.navyHeader),
                  ),
                ],
              ),
            ),
            if (pay.document != null) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Get.to(() => DocumentDownload(
                        file:
                            "https://msyard.s3.us-west-1.amazonaws.com/images/${pay.document}",
                      ));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E5BFF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.description_rounded,
                          size: 18, color: Color(0xFF2E5BFF)),
                      SizedBox(width: 8),
                      Text(
                        'View Document',
                        style: TextStyle(
                            color: Color(0xFF2E5BFF),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade800),
    );
  }

  Widget _routeHeader(String text, TextAlign align) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500),
    );
  }

  Widget _kv(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.grey.shade900),
        ),
      ],
    );
  }
}
