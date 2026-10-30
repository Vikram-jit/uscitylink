'use strict';

// Voice calls (WebRTC, app ↔ web):
//   calls              one row per call attempt (ringing → ongoing → ended), with quality stats
//   call_participants  everyone invited/joined; 1-to-1 today, models group calls later
//   messages.call_id   the "Missed voice call" / "Voice call · 3:42" bubble in the chat
//   user_profiles.voip_token  iOS PushKit token, to ring the phone when the app is closed
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('calls', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      channel_id: { type: Sequelize.UUID, allowNull: false },
      // The driver whose conversation this call belongs to (where the bubble goes)
      driver_id: { type: Sequelize.UUID, allowNull: false },
      initiator_id: { type: Sequelize.UUID, allowNull: false },
      answered_by: { type: Sequelize.UUID, allowNull: true },
      type: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'audio' },
      // ringing | ongoing | completed | missed | declined | cancelled | busy | failed
      status: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'ringing' },
      end_reason: { type: Sequelize.STRING(64), allowNull: true },
      started_at: { type: Sequelize.DATE, allowNull: false },
      answered_at: { type: Sequelize.DATE, allowNull: true },
      ended_at: { type: Sequelize.DATE, allowNull: true },
      duration_sec: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
      quality: { type: Sequelize.JSON, allowNull: true },
      message_id: { type: Sequelize.UUID, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('calls', ['driver_id', 'started_at']);
    await queryInterface.addIndex('calls', ['channel_id', 'started_at']);
    await queryInterface.addIndex('calls', ['status']);

    await queryInterface.createTable('call_participants', {
      id: { type: Sequelize.UUID, primaryKey: true, allowNull: false },
      call_id: { type: Sequelize.UUID, allowNull: false },
      user_profile_id: { type: Sequelize.UUID, allowNull: false },
      // caller | callee
      role: { type: Sequelize.STRING(16), allowNull: false },
      // invited | joined | declined | missed | left
      state: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'invited' },
      device: { type: Sequelize.STRING(32), allowNull: true },
      invited_at: { type: Sequelize.DATE, allowNull: false },
      joined_at: { type: Sequelize.DATE, allowNull: true },
      left_at: { type: Sequelize.DATE, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('call_participants', ['call_id']);
    await queryInterface.addIndex('call_participants', ['user_profile_id']);

    await queryInterface.addColumn('messages', 'call_id', { type: Sequelize.UUID, allowNull: true });
    await queryInterface.addColumn('user_profiles', 'voip_token', { type: Sequelize.STRING(255), allowNull: true });
  },

  down: async (queryInterface) => {
    await queryInterface.removeColumn('user_profiles', 'voip_token');
    await queryInterface.removeColumn('messages', 'call_id');
    await queryInterface.dropTable('call_participants');
    await queryInterface.dropTable('calls');
  },
};
