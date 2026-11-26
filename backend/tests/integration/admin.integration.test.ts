import { Types } from 'mongoose';
import { AdminAction } from '../../src/constants/admin';
import { UserRole } from '../../src/constants/roles';
import AdminAudit from '../../src/models/AdminAudit';
import {
  api,
  bearer,
  createVerifiedUserInDb,
  uniqueValue,
} from './helpers';

const ADMIN_PASSWORD = 'StrongPass123!';

describe('admin module', () => {
  let adminToken: string;

  beforeAll(async () => {
    const admin = await createVerifiedUserInDb('integration-admin', UserRole.ADMIN);

    const response = await api()
      .post('/api/v1/admin/auth/login')
      .send({ email: admin.email, password: ADMIN_PASSWORD })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.tokens.accessToken).toEqual(expect.any(String));
    adminToken = response.body.data.tokens.accessToken;
  });

  it('rejects admin login for non-admin users', async () => {
    const player = await createVerifiedUserInDb('integration-player', UserRole.PLAYER);
    await api()
      .post('/api/v1/admin/auth/login')
      .send({ email: player.email, password: ADMIN_PASSWORD })
      .expect(403);
  });

  it('serves the admin dashboard only to admins', async () => {
    const response = await api()
      .get('/api/v1/admin/dashboard')
      .set('Authorization', bearer(adminToken))
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data).toHaveProperty('users.total');
  });

  it('keeps legacy user admin routes and records audited updates', async () => {
    const target = await createVerifiedUserInDb(`legacy-${uniqueValue()}`);
    const newName = `Renamed ${uniqueValue()}`;

    const response = await api()
      .put(`/api/v1/users/${target._id}`)
      .set('Authorization', bearer(adminToken))
      .send({ name: newName })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.name).toBe(newName);

    const audit = await AdminAudit.findOne({ action: AdminAction.USER_UPDATED }).lean();
    expect(audit).not.toBeNull();
  });

  it('rejects scoring corrections without a reason', async () => {
    const matchId = new Types.ObjectId().toHexString();
    const deliveryId = new Types.ObjectId().toHexString();

    await api()
      .post(`/api/v1/admin/matches/${matchId}/corrections`)
      .set('Authorization', bearer(adminToken))
      .send({ deliveryId })
      .expect(400);
  });

  it('exposes auction monitoring as read-only', async () => {
    const response = await api()
      .get('/api/v1/admin/auctions')
      .set('Authorization', bearer(adminToken))
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data).toEqual(expect.any(Array));
  });

  it('does not expose Firebase credentials in audit records', async () => {
    const audits = await api()
      .get('/api/v1/admin/audits')
      .set('Authorization', bearer(adminToken))
      .expect(200);

    expect(JSON.stringify(audits.body)).not.toMatch(/private_key|refreshToken|password/);
  });
});
