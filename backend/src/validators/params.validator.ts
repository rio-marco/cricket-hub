import Joi from 'joi';

const objectIdPattern = /^[0-9a-fA-F]{24}$/;
const oid = (label: string) =>
  Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.pattern.base': `${label} must be a valid ObjectId`,
    'any.required': `${label} is required`,
    'string.empty': `${label} is required`,
  });

export const idParamSchema = Joi.object({ id: oid('id') });
export const teamIdParamSchema = Joi.object({ teamId: oid('teamId') });
export const playerIdParamSchema = Joi.object({ playerId: oid('playerId') });
export const matchIdParamSchema = Joi.object({ matchId: oid('matchId') });
export const auctionIdParamSchema = Joi.object({ auctionId: oid('auctionId') });
export const idTeamIdParamSchema = Joi.object({ id: oid('id'), teamId: oid('teamId') });
export const idPlayerIdParamSchema = Joi.object({ id: oid('id'), playerId: oid('playerId') });
export const idAuctionPlayerIdParamSchema = Joi.object({ id: oid('id'), auctionPlayerId: oid('auctionPlayerId') });
export const idBidIdParamSchema = Joi.object({ id: oid('id'), bidId: oid('bidId') });
export const idUserIdParamSchema = Joi.object({ id: oid('id'), userId: oid('userId') });
export const tournamentIdParamSchema = Joi.object({ tournamentId: oid('tournamentId') });


export const invitationIdParamSchema = Joi.object({ invitationId: oid('invitationId') });
export const idMemberIdParamSchema = Joi.object({ id: oid('id'), memberId: oid('memberId') });
export const idTournamentTeamIdParamSchema = Joi.object({ id: oid('id'), tournamentTeamId: oid('tournamentTeamId') });
export const idInvitationIdParamSchema = Joi.object({ id: oid('id'), invitationId: oid('invitationId') });
export const idDeliveryIdParamSchema = Joi.object({ matchId: oid('matchId'), deliveryId: oid('deliveryId') });

export default {
  idParamSchema,
  teamIdParamSchema,
  playerIdParamSchema,
  matchIdParamSchema,
  auctionIdParamSchema,
  idTeamIdParamSchema,
  idPlayerIdParamSchema,
  idAuctionPlayerIdParamSchema,
  idBidIdParamSchema,
  idUserIdParamSchema,
  tournamentIdParamSchema,
  invitationIdParamSchema,
  idMemberIdParamSchema,
  idTournamentTeamIdParamSchema,
  idInvitationIdParamSchema,
  idDeliveryIdParamSchema,
};
