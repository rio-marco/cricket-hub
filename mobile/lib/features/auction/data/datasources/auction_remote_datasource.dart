import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/models/paginated_response.dart';
import '../../domain/entities/auction.dart';
import '../../domain/entities/auction_bid.dart';
import '../../domain/entities/auction_player.dart';
import '../../domain/entities/auction_state.dart';
import '../../domain/entities/auction_team.dart';
import '../models/auction_bid_model.dart';
import '../models/auction_json.dart';
import '../models/auction_model.dart';
import '../models/auction_player_model.dart';
import '../models/auction_state_model.dart';
import '../models/auction_team_model.dart';

abstract class AuctionRemoteDataSource {
  Future<PaginatedResponse<Auction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  });

  Future<AuctionStateSnapshot> getState(String auctionId);

  Future<PaginatedResponse<AuctionPlayer>> getPlayers(
    String auctionId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    bool? available,
    String? search,
  });

  Future<List<AuctionBid>> getBidHistory(
    String auctionId, {
    int limit = 100,
    String? decision,
  });

  Future<AuctionResults> getResults(String auctionId);

  Future<AuctionTeam> getTeamPurse(String auctionId, String teamId);

  Future<AuctionStateSnapshot> createAuction({
    required String name,
    required List<String> teams,
    required double purseAmount,
    String? tournamentId,
    double? basePrice,
    int? minBidIncrement,
    int? maxSquadSize,
    int? minSquadSize,
    List<String>? playerCategories,
    String? status,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> updateAuction(
    String auctionId, {
    String? name,
    String? tournamentId,
    List<String>? teams,
    double? purseAmount,
    double? basePrice,
    int? minBidIncrement,
    int? maxSquadSize,
    int? minSquadSize,
    List<String>? playerCategories,
    String? status,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<void> deleteAuction(String auctionId);

  Future<AuctionStateSnapshot> registerPlayers(
    String auctionId, {
    required List<Map<String, dynamic>> players,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> removePlayer(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> setPlayerAvailability(
    String auctionId,
    String auctionPlayerId, {
    required bool available,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> bringPlayerForward(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> addTeam(
    String auctionId, {
    required String teamId,
  });

  Future<AuctionStateSnapshot> removeTeam(
    String auctionId,
    String teamId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> startAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> pauseAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> resumeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> completeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> placeBid(
    String auctionId, {
    required String teamId,
    double? amount,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> decideBid(
    String auctionId,
    String bidId, {
    required bool accept,
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> markSold(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> markUnsold(
    String auctionId, {
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> nextPlayer(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });
}

class AuctionRemoteDataSourceImpl implements AuctionRemoteDataSource {
  final Dio _dio;

  const AuctionRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<Auction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final envelope = await _getEnvelope(ApiEndpoints.auctions, queryParameters: query);
    return PaginatedResponse<Auction>.fromJson(
      envelope,
      (item) => AuctionModel.fromJson(normalizeAuctionMap(item)),
    );
  }

  @override
  Future<AuctionStateSnapshot> getState(String auctionId) async {
    return _readState(() => _dio.get<dynamic>(
          ApiEndpoints.auctionState(auctionId),
          queryParameters: const {'limit': 50},
        ));
  }

  @override
  Future<PaginatedResponse<AuctionPlayer>> getPlayers(
    String auctionId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    bool? available,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty && status != 'ALL')
        'status': status,
      if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      if (available != null) 'available': available,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final envelope = await _getEnvelope(
      ApiEndpoints.auctionPlayers(auctionId),
      queryParameters: query,
    );
    return PaginatedResponse<AuctionPlayer>.fromJson(
      envelope,
      (item) => AuctionPlayerModel.fromJson(normalizeAuctionMap(item)),
    );
  }

  @override
  Future<List<AuctionBid>> getBidHistory(
    String auctionId, {
    int limit = 100,
    String? decision,
  }) async {
    final envelope = await _getEnvelope(
      ApiEndpoints.auctionHistory(auctionId),
      queryParameters: <String, dynamic>{
        'limit': limit,
        if (decision != null && decision.isNotEmpty) 'decision': decision,
      },
    );
    return normalizeAuctionList(envelope['data']).map((item) {
      return AuctionBidModel.fromJson(normalizeAuctionMap(item));
    }).toList(growable: false);
  }

  @override
  Future<AuctionResults> getResults(String auctionId) async {
    final data = await _readData(() =>
        _dio.get<dynamic>(ApiEndpoints.auctionResults(auctionId)));
    return AuctionResults(
      sold: normalizeAuctionList(data['sold'])
          .map((item) => AuctionPlayerModel.fromJson(normalizeAuctionMap(item)))
          .toList(growable: false),
      unsold: normalizeAuctionList(data['unsold'])
          .map((item) => AuctionPlayerModel.fromJson(normalizeAuctionMap(item)))
          .toList(growable: false),
      teams: normalizeAuctionList(data['teams'])
          .map((item) => AuctionTeamModel.fromJson(normalizeAuctionMap(item)))
          .toList(growable: false),
    );
  }

  @override
  Future<AuctionTeam> getTeamPurse(String auctionId, String teamId) async {
    final data = await _readData(() => _dio.get<dynamic>(
          ApiEndpoints.auctionTeamPurse(auctionId, teamId),
        ));
    return AuctionTeamModel.fromJson(data);
  }

  @override
  Future<AuctionStateSnapshot> createAuction({
    required String name,
    required List<String> teams,
    required double purseAmount,
    String? tournamentId,
    double? basePrice,
    int? minBidIncrement,
    int? maxSquadSize,
    int? minSquadSize,
    List<String>? playerCategories,
    String? status,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      'name': name,
      'teams': teams,
      'purseAmount': purseAmount,
      'basePrice': basePrice ?? 0,
      'minBidIncrement': minBidIncrement ?? 100000,
      'maxSquadSize': maxSquadSize ?? 25,
      'minSquadSize': minSquadSize ?? 11,
      'playerCategories': playerCategories ?? const <String>[],
      'status': status ?? 'DRAFT',
      if (tournamentId != null && tournamentId.isNotEmpty)
        'tournament': tournamentId,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.post<dynamic>(
          ApiEndpoints.auctions,
          data: data,
        ));
  }

  @override
  Future<AuctionStateSnapshot> updateAuction(
    String auctionId, {
    String? name,
    String? tournamentId,
    List<String>? teams,
    double? purseAmount,
    double? basePrice,
    int? minBidIncrement,
    int? maxSquadSize,
    int? minSquadSize,
    List<String>? playerCategories,
    String? status,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (tournamentId != null) 'tournament': tournamentId,
      if (teams != null) 'teams': teams,
      if (purseAmount != null) 'purseAmount': purseAmount,
      if (basePrice != null) 'basePrice': basePrice,
      if (minBidIncrement != null) 'minBidIncrement': minBidIncrement,
      if (maxSquadSize != null) 'maxSquadSize': maxSquadSize,
      if (minSquadSize != null) 'minSquadSize': minSquadSize,
      if (playerCategories != null) 'playerCategories': playerCategories,
      if (status != null) 'status': status,
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.put<dynamic>(
          ApiEndpoints.auctionById(auctionId),
          data: data,
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<void> deleteAuction(String auctionId) async {
    await _run(() => _dio.delete<dynamic>(ApiEndpoints.auctionById(auctionId)));
  }

  @override
  Future<AuctionStateSnapshot> registerPlayers(
    String auctionId, {
    required List<Map<String, dynamic>> players,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      'players': players,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.post<dynamic>(
          ApiEndpoints.auctionPlayers(auctionId),
          data: data,
        ));
  }

  @override
  Future<AuctionStateSnapshot> removePlayer(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _writeState(() => _dio.delete<dynamic>(
          ApiEndpoints.auctionPlayerById(auctionId, auctionPlayerId),
          data: const <String, dynamic>{},
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<AuctionStateSnapshot> setPlayerAvailability(
    String auctionId,
    String auctionPlayerId, {
    required bool available,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      'available': available,
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.patch<dynamic>(
          ApiEndpoints.auctionPlayerAvailability(auctionId, auctionPlayerId),
          data: data,
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<AuctionStateSnapshot> bringPlayerForward(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.post<dynamic>(
          ApiEndpoints.auctionPlayerForward(auctionId, auctionPlayerId),
          data: data,
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<AuctionStateSnapshot> addTeam(
    String auctionId, {
    required String teamId,
  }) {
    return _writeState(() => _dio.post<dynamic>(
          ApiEndpoints.auctionTeams(auctionId),
          data: <String, dynamic>{'teamId': teamId},
        ));
  }

  @override
  Future<AuctionStateSnapshot> removeTeam(
    String auctionId,
    String teamId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _writeState(() => _dio.delete<dynamic>(
          ApiEndpoints.auctionTeamById(auctionId, teamId),
          data: const <String, dynamic>{},
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<AuctionStateSnapshot> startAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _postAction(
      ApiEndpoints.auctionStart(auctionId),
      expectedVersion: expectedVersion,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<AuctionStateSnapshot> pauseAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _postAction(
      ApiEndpoints.auctionPause(auctionId),
      expectedVersion: expectedVersion,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<AuctionStateSnapshot> resumeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _postAction(
      ApiEndpoints.auctionResume(auctionId),
      expectedVersion: expectedVersion,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<AuctionStateSnapshot> completeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _postAction(
      ApiEndpoints.auctionComplete(auctionId),
      expectedVersion: expectedVersion,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<AuctionStateSnapshot> placeBid(
    String auctionId, {
    required String teamId,
    double? amount,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      'team': teamId,
      if (amount != null) 'amount': amount,
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.post<dynamic>(
          ApiEndpoints.auctionBid(auctionId),
          data: data,
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<AuctionStateSnapshot> decideBid(
    String auctionId,
    String bidId, {
    required bool accept,
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      'accept': accept,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.post<dynamic>(
          ApiEndpoints.auctionBidDecision(auctionId, bidId),
          data: data,
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<AuctionStateSnapshot> markSold(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _postAction(
      ApiEndpoints.auctionSold(auctionId),
      expectedVersion: expectedVersion,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<AuctionStateSnapshot> markUnsold(
    String auctionId, {
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.post<dynamic>(
          ApiEndpoints.auctionUnsold(auctionId),
          data: data,
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  @override
  Future<AuctionStateSnapshot> nextPlayer(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _postAction(
      ApiEndpoints.auctionNext(auctionId),
      expectedVersion: expectedVersion,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<AuctionStateSnapshot> _postAction(
    String path, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final data = <String, dynamic>{
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    };
    return _writeState(() => _dio.post<dynamic>(
          path,
          data: data,
          options: _actionOptions(
            expectedVersion: expectedVersion,
            idempotencyKey: idempotencyKey,
          ),
        ));
  }

  Future<AuctionStateSnapshot> _readState(
    Future<Response<dynamic>> Function() call,
  ) async {
    final data = await _readData(call);
    return AuctionStateModel.fromJson(data);
  }

  Future<AuctionStateSnapshot> _writeState(
    Future<Response<dynamic>> Function() call,
  ) async {
    final data = await _readData(call);
    return AuctionStateModel.fromJson(data);
  }

  Future<Map<String, dynamic>> _getEnvelope(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _run(() => _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
        ));
    return normalizeAuctionMap(response.data);
  }

  Future<Map<String, dynamic>> _readData(
    Future<Response<dynamic>> Function() call,
  ) async {
    final response = await _run(call);
    return auctionResponseData(response.data);
  }

  Future<Response<dynamic>> _run(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on AppException {
      rethrow;
    } catch (error) {
      throw ServerException(message: error.toString());
    }
  }

  Options _actionOptions({
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    final headers = <String, dynamic>{};
    if (expectedVersion != null) {
      headers['If-Match'] = '"$expectedVersion"';
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return Options(headers: headers);
  }
}
