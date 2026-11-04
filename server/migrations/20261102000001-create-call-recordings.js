'use strict';

// Recording of each answered call (both voices mixed into one file on S3) — proof of what was said
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('call_recordings', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      call_id: { type: Sequelize.UUID, allowNull: false },
      // recording → processing (mixing/uploading) → ready | failed
      status: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'recording' },
      s3_key: { type: Sequelize.STRING(512), allowNull: true },
      mime: { type: Sequelize.STRING(64), allowNull: true },
      duration_sec: { type: Sequelize.INTEGER, allowNull: true },
      size_bytes: { type: Sequelize.BIGINT, allowNull: true },
      // SHA-256 of the stored file: shows the recording wasn't changed after the call
      sha256: { type: Sequelize.STRING(64), allowNull: true },
      // Whose audio is in it: [{ userId, segments, startedOffsetMs }]
      tracks: { type: Sequelize.JSON, allowNull: true },
      error: { type: Sequelize.TEXT, allowNull: true },
      started_at: { type: Sequelize.DATE, allowNull: true },
      completed_at: { type: Sequelize.DATE, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false },
      updatedAt: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('call_recordings', ['call_id']);
    await queryInterface.addIndex('call_recordings', ['status']);
  },
  down: async (queryInterface) => {
    await queryInterface.dropTable('call_recordings');
  },
};
