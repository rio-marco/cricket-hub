const { createDefaultPreset } = require("ts-jest");

const tsJestTransformCfg = createDefaultPreset().transform;

/** @type {import("jest").Config} */
module.exports = {
  testEnvironment: "node",
  transform: {
    ...tsJestTransformCfg,
  },
  testMatch: ["<rootDir>/tests/integration/**/*.test.ts"],
  setupFiles: ["<rootDir>/tests/integration/env.ts"],
  setupFilesAfterEnv: ["<rootDir>/tests/integration/setup.ts"],
  maxWorkers: 1,
  testTimeout: 45000,
};
