import '../../../../core/errors/failures.dart';
import '../models/auction_json.dart';

class AuctionRealtimeEvent {
  final String name;
  final String? eventId;
  final String? auctionId;
  final String? action;
  final int? stateVersion;
  final Map<String, dynamic> data;

  const AuctionRealtimeEvent({
    required this.name,
    required this.data,
    this.eventId,
    this.auctionId,
    this.action,
    this.stateVersion,
  });

  factory AuctionRealtimeEvent.from(String name, dynamic value) {
    final data = normalizeAuctionMap(value);
    return AuctionRealtimeEvent(
      name: name,
      data: data,
      eventId: auctionString(data['eventId']),
      auctionId: auctionString(data['auctionId']),
      action: auctionString(data['action']),
      stateVersion: data['stateVersion'] == null
          ? null
          : auctionInt(data['stateVersion']),
    );
  }

  Map<String, dynamic>? get state => normalizeAuctionMapOrNull(data['state']);

  Map<String, dynamic>? get error => normalizeAuctionMapOrNull(data['error']);

  Object? get errorCode => error?['code'] ?? data['code'];

  String? get errorMessage {
    final message = auctionString(error?['message']) ?? auctionString(data['message']);
    return message;
  }

  bool get hasState => state != null;
}

AuctionRealtimeEvent errorEvent(String auctionId, Object error) {
  return AuctionRealtimeEvent.from('auction:error', {
    'auctionId': auctionId,
    'error': {
      'code': 'REALTIME_ERROR',
      'message': error.toString(),
    },
  });
}

Failure failureFromRealtimeEvent(AuctionRealtimeEvent event) {
  return ServerFailure(message: event.errorMessage ?? 'Auction action was rejected.');
}
