import 'admin_json.dart';

class AdminReportEntry {
  final String id;
  final String type;
  final String reason;
  final String status;
  final String reporterName;
  final String targetLabel;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  const AdminReportEntry({
    required this.id,
    this.type = '',
    this.reason = '',
    this.status = '',
    this.reporterName = '',
    this.targetLabel = '',
    this.createdAt,
    this.raw = const <String, dynamic>{},
  });

  factory AdminReportEntry.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['report']);
    final reporter = AdminJson.map(data['reporter'] ?? data['user']);
    final target = AdminJson.map(
      data['target'] ?? data['reportedUser'] ?? data['reportedEntity'],
    );
    return AdminReportEntry(
      id: AdminJson.entityId(data),
      type: AdminJson.string(data['type'] ?? data['category'], 'Report'),
      reason: AdminJson.string(data['reason'] ?? data['description']),
      status: AdminJson.string(data['status']),
      reporterName: AdminJson.string(reporter['name'] ?? data['reporterName']),
      targetLabel: AdminJson.string(
        target['name'] ?? target['title'] ?? data['targetLabel'],
      ),
      createdAt: AdminJson.date(data['createdAt'] ?? data['created_at']),
      raw: AdminJson.map(data),
    );
  }
}
