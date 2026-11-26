class NotificationPreferences {
  final bool pushEnabled;
  final bool teamInvitations;
  final bool joinRequests;
  final bool tournamentUpdates;
  final bool matchReminders;
  final bool matchResults;
  final bool liveScoreUpdates;
  final bool wicketAlerts;
  final bool overAlerts;
  final bool inningsAlerts;
  final bool auctionUpdates;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.teamInvitations = true,
    this.joinRequests = true,
    this.tournamentUpdates = true,
    this.matchReminders = true,
    this.matchResults = true,
    this.liveScoreUpdates = false,
    this.wicketAlerts = true,
    this.overAlerts = false,
    this.inningsAlerts = true,
    this.auctionUpdates = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: _bool(json['pushEnabled'], true),
      teamInvitations: _bool(json['teamInvitations'], true),
      joinRequests: _bool(json['joinRequests'], true),
      tournamentUpdates: _bool(json['tournamentUpdates'], true),
      matchReminders: _bool(json['matchReminders'], true),
      matchResults: _bool(json['matchResults'], true),
      liveScoreUpdates: _bool(json['liveScoreUpdates'], false),
      wicketAlerts: _bool(json['wicketAlerts'], true),
      overAlerts: _bool(json['overAlerts'], false),
      inningsAlerts: _bool(json['inningsAlerts'], true),
      auctionUpdates: _bool(json['auctionUpdates'], true),
      quietHoursEnabled: _bool(json['quietHoursEnabled'], false),
      quietHoursStart: _time(json['quietHoursStart'], '22:00'),
      quietHoursEnd: _time(json['quietHoursEnd'], '08:00'),
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? teamInvitations,
    bool? joinRequests,
    bool? tournamentUpdates,
    bool? matchReminders,
    bool? matchResults,
    bool? liveScoreUpdates,
    bool? wicketAlerts,
    bool? overAlerts,
    bool? inningsAlerts,
    bool? auctionUpdates,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      teamInvitations: teamInvitations ?? this.teamInvitations,
      joinRequests: joinRequests ?? this.joinRequests,
      tournamentUpdates: tournamentUpdates ?? this.tournamentUpdates,
      matchReminders: matchReminders ?? this.matchReminders,
      matchResults: matchResults ?? this.matchResults,
      liveScoreUpdates: liveScoreUpdates ?? this.liveScoreUpdates,
      wicketAlerts: wicketAlerts ?? this.wicketAlerts,
      overAlerts: overAlerts ?? this.overAlerts,
      inningsAlerts: inningsAlerts ?? this.inningsAlerts,
      auctionUpdates: auctionUpdates ?? this.auctionUpdates,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pushEnabled': pushEnabled,
        'teamInvitations': teamInvitations,
        'joinRequests': joinRequests,
        'tournamentUpdates': tournamentUpdates,
        'matchReminders': matchReminders,
        'matchResults': matchResults,
        'liveScoreUpdates': liveScoreUpdates,
        'wicketAlerts': wicketAlerts,
        'overAlerts': overAlerts,
        'inningsAlerts': inningsAlerts,
        'auctionUpdates': auctionUpdates,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
      };
}

bool _bool(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

String _time(dynamic value, String fallback) {
  final text = value?.toString() ?? '';
  return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(text)
      ? text
      : fallback;
}
