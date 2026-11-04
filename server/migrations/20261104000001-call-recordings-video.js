'use strict';

// Video calls with "Record video" on: the camera grid is stored next to the audio recording
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('call_recordings', 'video_s3_key', { type: Sequelize.STRING(512), allowNull: true });
    await queryInterface.addColumn('call_recordings', 'video_size_bytes', { type: Sequelize.BIGINT, allowNull: true });
    await queryInterface.addColumn('call_recordings', 'video_sha256', { type: Sequelize.STRING(64), allowNull: true });
  },
  down: async (queryInterface) => {
    await queryInterface.removeColumn('call_recordings', 'video_sha256');
    await queryInterface.removeColumn('call_recordings', 'video_size_bytes');
    await queryInterface.removeColumn('call_recordings', 'video_s3_key');
  },
};
