import 'package:flutter/material.dart';

/// Colors match the web dashboard's formatTrailerOption() exactly —
/// ENTRY_STATUS_COLOR / READY_STATUS_COLOR_DEFAULT in dashboard.blade.php.
const _kGoodStatusColor = Color(0xFF16A34A);
const _kDeadStatusColor = Color(0xFFDC2626);

class TrailerStatusBadge {
  final String label;
  final Color color;
  const TrailerStatusBadge(this.label, this.color);
}

class SecurityTrailerModel {
  int? id;
  String? number;
  String? licensePlateNumber;
  String? latestEntryStatus;
  String? latestReadyStatus;

  SecurityTrailerModel({
    this.id,
    this.number,
    this.licensePlateNumber,
    this.latestEntryStatus,
    this.latestReadyStatus,
  });

  SecurityTrailerModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    number = json['number']?.toString();
    licensePlateNumber = json['licensePlateNumber'];
    latestEntryStatus = json['latestEntryStatus'];
    latestReadyStatus = json['latestReadyStatus'];
  }

  /// e.g. "142 (In-Yard, Ready)" — mirrors the web's buildTrailerOption() label.
  String get displayLabel {
    final badges = <String>[];
    if (latestEntryStatus != null) {
      badges.add(latestEntryStatus == 'entry' ? 'In-Yard' : 'Departed');
    }
    if (latestReadyStatus != null) {
      badges.add(latestReadyStatus == 'ready'
          ? 'Ready'
          : latestReadyStatus!.replaceAll('-', ' '));
    }
    if (badges.isEmpty) return number ?? '';
    return '${number ?? ''} (${badges.join(', ')})';
  }

  /// Colored status badges for the dropdown — mirrors the web's
  /// formatTrailerOption(): In-Yard/Ready in green, Departed/not-ready in red.
  List<TrailerStatusBadge> get statusBadges {
    final badges = <TrailerStatusBadge>[];
    if (latestEntryStatus != null) {
      final isInYard = latestEntryStatus == 'entry';
      badges.add(TrailerStatusBadge(
        isInYard ? 'In-Yard' : 'Departed',
        isInYard ? _kGoodStatusColor : _kDeadStatusColor,
      ));
    }
    if (latestReadyStatus != null) {
      final isReady = latestReadyStatus == 'ready';
      final label = isReady
          ? 'Ready'
          : latestReadyStatus!
              .replaceAll('-', ' ')
              .split(' ')
              .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' ');
      badges.add(TrailerStatusBadge(
        label,
        isReady ? _kGoodStatusColor : _kDeadStatusColor,
      ));
    }
    return badges;
  }
}
