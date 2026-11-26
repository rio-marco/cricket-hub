import mongoose from 'mongoose';
import os from 'os';

import { connectDatabase } from '../../src/config/database';
import '../../src/models/User';
import '../../src/models/AdminAudit';
import '../../src/models/RefreshToken';
import '../../src/models/Team';
import '../../src/models/TeamMember';
import '../../src/models/TeamInvitation';
import '../../src/models/Player';
import '../../src/models/Tournament';
import '../../src/models/TournamentTeam';
import '../../src/models/Match';
import '../../src/models/Innings';
import '../../src/models/Delivery';
import '../../src/models/ScoringAudit';
import '../../src/models/Auction';
import '../../src/models/AuctionPlayer';
import '../../src/models/AuctionBid';
import '../../src/models/AuctionTeam';
import '../../src/models/AuctionAudit';
import '../../src/models/Notification';
import '../../src/models/NotificationDelivery';
import '../../src/models/NotificationPreference';
import '../../src/models/DeviceToken';

const SAFE_DATABASE_NAME = /^cricket_hub_(integration|test)(_[a-zA-Z0-9-]+)?$/;
const SAFE_HOSTNAMES = new Set(['localhost', '127.0.0.1', '[::1]', '::1']);

const resolveTestConnection = (): { uri: string; databaseName: string } => {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('Integration tests require MONGODB_URI_TEST to be configured.');
  }

  let parsed: URL;
  try {
    parsed = new URL(uri);
  } catch {
    throw new Error('Integration tests require a valid MongoDB connection URI.');
  }

  if (parsed.protocol !== 'mongodb:') {
    throw new Error('Integration tests only accept a mongodb:// URI.');
  }
  if (!SAFE_HOSTNAMES.has(parsed.hostname)) {
    throw new Error('Integration tests only accept a local MongoDB server.');
  }

  const databaseName = decodeURIComponent(parsed.pathname.replace(/^\//, ''));
  if (!SAFE_DATABASE_NAME.test(databaseName)) {
    throw new Error(
      `Refusing to run integration tests against database "${databaseName}". ` +
        'Use an isolated cricket_hub_integration_* database.'
    );
  }

  return { uri, databaseName };
};

beforeAll(async () => {
  const { uri, databaseName } = resolveTestConnection();
  const parsedUri = new URL(uri);
  console.info(
    `[Integration Test DB] Using isolated database: ${databaseName} at ${parsedUri.hostname}:${parsedUri.port || '27017'}`
  );

  await connectDatabase({
    serverSelectionTimeoutMS: 5000,
    runtimeAdapters: { os },
  } as any);
  await mongoose.connection.dropDatabase();

  await Promise.all(
    mongoose.modelNames().map((name) => mongoose.model(name).syncIndexes())
  );
});

afterAll(async () => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
});
