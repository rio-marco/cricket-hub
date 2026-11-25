process.env.NODE_ENV = 'test';
process.env.MONGODB_URI =
  process.env.MONGODB_URI_TEST ||
  'mongodb://127.0.0.1:27019/cricket_hub_integration_test';
