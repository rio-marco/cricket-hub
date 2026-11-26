import 'admin_json.dart';

class AdminAuditLog {
  final String id;
  final String action;
  final String actorName;
  final String entity;
  final String entityId;
  final String severity;
  final String reason;
  final DateTime? createdAt;
  final Map<String, dynamic> details;
  final Map<String, dynamic> raw;

  const AdminAuditLog({
    required this.id,
    this.action = '',
    this.actorName = '',
    this.entity = '',
    this.entityId = '',
    this.severity = '',
    this.reason = '',
    this.createdAt,
    this.details = const <String, dynamic>{},
    this.raw = const <String, dynamic>{},
  });

  factory AdminAuditLog.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['audit', 'log']);
    final actor = AdminJson.map(data['actor'] ?? data['admin'] ?? data['user']);
    final target = AdminJson.map(
      data['target'] ?? data['entity'] ?? data['resource'],
    );
    return AdminAuditLog(
      id: AdminJson.entityId(data),
      action: AdminJson.string(
        data['action'] ?? data['event'] ?? data['operation'],
        'Unknown action',
      ),
      actorName: AdminJson.string(
        actor['name'] ?? data['actorName'] ?? data['performedBy'],
      ),
      entity: AdminJson.string(
        target['type'] ??
            target['kind'] ??
            data['entityType'] ??
            data['resourceType'],
      ),
      entityId: AdminJson.entityId(target).isEmpty
          ? AdminJson.string(data['entityId'] ?? data['resourceId'])
          : AdminJson.entityId(target),
      severity: AdminJson.string(data['severity'] ?? data['level']),
      reason: AdminJson.string(data['reason'] ?? data['description']),
      createdAt: AdminJson.date(
        data['createdAt'] ?? data['timestamp'] ?? data['at'],
      ),
      details: AdminJson.details(
        data['details'] ?? data['changes'] ?? data['metadata'],
      ),
      raw: AdminJson.map(data),
    );
  }
}
