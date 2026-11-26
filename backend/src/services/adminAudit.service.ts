import { Request } from 'express';
import { AdminAction, ADMIN_SENSITIVE_ACTIONS } from '../constants/admin';
import AdminAudit, { AdminAuditDocument, redactSensitive } from '../models/AdminAudit';
import AuctionAudit from '../models/AuctionAudit';
import ScoringAudit from '../models/ScoringAudit';
import { ApiError } from '../utils/apiError';
import { getPaginationParams } from '../utils/pagination';

export interface AdminAuditTarget {
  type: string;
  id?: string;
}

export interface AdminAuditListResult {
  audits: Record<string, unknown>[];
  pagination: ReturnType<typeof getPaginationParams> & { total?: number };
}

const DEFAULT_SORT_FIELDS = ['createdAt', 'action', 'adminId', 'targetType'];

export const resolveSort = (
  query: Record<string, any> = {},
  allowedFields: string[] = DEFAULT_SORT_FIELDS,
  defaultField: string = 'createdAt'
): Record<string, 1 | -1> => {
  const raw = typeof query.sort === 'string' && query.sort.trim() ? query.sort.trim() : `-${defaultField}`;
  const descending = raw.startsWith('-');
  const requestedField = descending ? raw.slice(1) : raw;
  const field = allowedFields.includes(requestedField) ? requestedField : defaultField;
  const direction = query.order ? (query.order === 'asc' ? 1 : -1) : descending ? -1 : 1;
  return { [field]: direction };
};

export const serializeAdminAudit = (audit: any): Record<string, unknown> => {
  const value = audit?.toObject ? audit.toObject() : audit;
  return {
    id: String(value?._id || value?.id || ''),
    adminId: value?.adminId ? String(value.adminId) : undefined,
    adminRole: value?.adminRole,
    action: value?.action,
    targetType: value?.targetType,
    targetId: value?.targetId ? String(value.targetId) : undefined,
    before: redactSensitive(value?.before),
    after: redactSensitive(value?.after),
    reason: value?.reason,
    metadata: redactSensitive(value?.metadata),
    ipAddress: value?.ipAddress,
    createdAt: value?.createdAt,
    updatedAt: value?.updatedAt,
  };
};

export class AdminAuditService {
  async recordAdminAction(
    req: Request | Partial<Request>,
    action: AdminAction,
    target: string | AdminAuditTarget,
    before?: unknown,
    after?: unknown,
    reason?: string,
    metadata?: Record<string, unknown>
  ): Promise<Record<string, unknown>> {
    if (ADMIN_SENSITIVE_ACTIONS.has(action) && (!reason || reason.trim().length < 3)) {
      throw ApiError.badRequest('A reason of at least 3 characters is required for this administrative action.');
    }

    const targetInfo: AdminAuditTarget =
      typeof target === 'string' ? { type: target, id: undefined } : target;
    const adminId = req.user?._id?.toString() || req.user?.id;
    const adminRole = req.user?.role;
    const ipAddress =
      req.ip || req.socket?.remoteAddress || (req.headers?.['x-forwarded-for'] as string) || undefined;
    const userAgent = (req.headers?.['user-agent'] as string) || undefined;

    const created = await AdminAudit.create({
      adminId: adminId && /^[0-9a-fA-F]{24}$/.test(adminId) ? adminId : undefined,
      adminRole,
      action,
      targetType: targetInfo.type,
      targetId: targetInfo.id ? String(targetInfo.id) : undefined,
      before: redactSensitive(before),
      after: redactSensitive(after),
      reason: reason?.trim(),
      metadata: redactSensitive({
        ...(metadata || {}),
        method: req.method,
        path: req.originalUrl || req.url,
      }),
      ipAddress,
      userAgent,
    });

    return serializeAdminAudit(created as AdminAuditDocument);
  }

  async listAdminActions(query: Record<string, any> = {}): Promise<AdminAuditListResult> {
    const { page, limit, skip } = getPaginationParams(query, 20, 100, '-createdAt');
    const filter: Record<string, any> = {};

    if (query.adminId) filter.adminId = query.adminId;
    if (query.action) filter.action = query.action;
    if (query.targetType) filter.targetType = query.targetType;
    if (query.targetId) filter.targetId = String(query.targetId);
    if (query.from || query.to) {
      filter.createdAt = {};
      if (query.from) filter.createdAt.$gte = new Date(query.from);
      if (query.to) filter.createdAt.$lte = new Date(query.to);
    }

    const [audits, total] = await Promise.all([
      AdminAudit.find(filter).sort(resolveSort(query) as any).skip(skip).limit(limit).lean(),
      AdminAudit.countDocuments(filter),
    ]);

    return {
      audits: audits.map(serializeAdminAudit),
      pagination: { page, limit, skip, sort: resolveSort(query), total },
    };
  }

  async listScoringActions(query: Record<string, any> = {}): Promise<AdminAuditListResult> {
    const { page, limit, skip } = getPaginationParams(query, 20, 100, '-createdAt');
    const filter: Record<string, any> = {};
    if (query.action) filter.action = query.action;
    if (query.match) filter.match = query.match;
    if (query.actor) filter.actor = query.actor;
    if (query.from || query.to) {
      filter.createdAt = {};
      if (query.from) filter.createdAt.$gte = new Date(query.from);
      if (query.to) filter.createdAt.$lte = new Date(query.to);
    }

    const [audits, total] = await Promise.all([
      ScoringAudit.find(filter)
        .sort(resolveSort(query, ['createdAt', 'action', 'match', 'stateVersion']) as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      ScoringAudit.countDocuments(filter),
    ]);

    return {
      audits: audits.map((audit: any) => ({
        id: String(audit._id),
        match: String(audit.match),
        innings: String(audit.innings),
        action: audit.action,
        actor: String(audit.actor),
        sequenceNumber: audit.sequenceNumber,
        stateVersion: audit.stateVersion,
        payload: redactSensitive(audit.payload),
        result: redactSensitive(audit.result),
        createdAt: audit.createdAt,
      })),
      pagination: { page, limit, skip, sort: resolveSort(query), total },
    };
  }

  async listAuctionActions(query: Record<string, any> = {}): Promise<AdminAuditListResult> {
    const { page, limit, skip } = getPaginationParams(query, 20, 100, '-createdAt');
    const filter: Record<string, any> = {};
    if (query.action) filter.action = query.action;
    if (query.auction) filter.auction = query.auction;
    if (query.actor) filter.actor = query.actor;
    if (query.from || query.to) {
      filter.createdAt = {};
      if (query.from) filter.createdAt.$gte = new Date(query.from);
      if (query.to) filter.createdAt.$lte = new Date(query.to);
    }

    const [audits, total] = await Promise.all([
      AuctionAudit.find(filter)
        .sort(resolveSort(query, ['createdAt', 'action', 'auction', 'stateVersion']) as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      AuctionAudit.countDocuments(filter),
    ]);

    return {
      audits: audits.map((audit: any) => ({
        id: String(audit._id),
        auction: String(audit.auction),
        auctionPlayer: audit.auctionPlayer ? String(audit.auctionPlayer) : undefined,
        action: audit.action,
        actor: String(audit.actor),
        requestKey: audit.requestKey,
        sequenceNumber: audit.sequenceNumber,
        stateVersion: audit.stateVersion,
        payload: redactSensitive(audit.payload),
        result: redactSensitive(audit.result),
        createdAt: audit.createdAt,
      })),
      pagination: { page, limit, skip, sort: resolveSort(query), total },
    };
  }
}

export const adminAuditService = new AdminAuditService();
export default adminAuditService;
