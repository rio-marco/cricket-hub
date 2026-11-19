/// Generic paginated response wrapper for paginated API endpoints.
class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const PaginatedResponse({
    required this.items,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
    this.hasNextPage = false,
    this.hasPrevPage = false,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    // Determine where list items are located
    List<dynamic> rawItems = [];
    if (json['data'] is List) {
      rawItems = json['data'] as List<dynamic>;
    } else if (json['items'] is List) {
      rawItems = json['items'] as List<dynamic>;
    } else if (json['teams'] is List) {
      rawItems = json['teams'] as List<dynamic>;
    } else if (json['players'] is List) {
      rawItems = json['players'] as List<dynamic>;
    } else if (json['results'] is List) {
      rawItems = json['results'] as List<dynamic>;
    } else if (json['data'] is Map && (json['data'] as Map)['items'] is List) {
      rawItems = (json['data'] as Map)['items'] as List<dynamic>;
    }

    final items = rawItems.map((e) => fromJsonT(e)).toList();

    // Check pagination metadata
    final pagination = json['pagination'] is Map<String, dynamic>
        ? json['pagination'] as Map<String, dynamic>
        : (json['data'] is Map && (json['data'] as Map)['pagination'] is Map<String, dynamic>
            ? (json['data'] as Map)['pagination'] as Map<String, dynamic>
            : null);

    final page = pagination?['page'] as int? ?? json['page'] as int? ?? 1;
    final limit = pagination?['limit'] as int? ?? json['limit'] as int? ?? 20;
    final total = pagination?['total'] as int? ?? json['total'] as int? ?? items.length;
    final totalPages = pagination?['totalPages'] as int? ??
        json['totalPages'] as int? ??
        (total > 0 && limit > 0 ? (total / limit).ceil() : 1);
    final hasNextPage = pagination?['hasNextPage'] as bool? ?? (page < totalPages);
    final hasPrevPage = pagination?['hasPrevPage'] as bool? ?? (page > 1);

    return PaginatedResponse<T>(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPrevPage: hasPrevPage,
    );
  }

  factory PaginatedResponse.empty() {
    return const PaginatedResponse(
      items: [],
      page: 1,
      limit: 20,
      total: 0,
      totalPages: 1,
      hasNextPage: false,
      hasPrevPage: false,
    );
  }

  PaginatedResponse<T> copyWith({
    List<T>? items,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPrevPage,
  }) {
    return PaginatedResponse<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPrevPage: hasPrevPage ?? this.hasPrevPage,
    );
  }
}
