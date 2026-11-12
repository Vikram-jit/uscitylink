'use strict';

// Public tracking link per load (/track/<token>): a random token, unique; the page stops showing the
// load once it's completed / cancelled. Existing loads get theirs the first time dispatch opens them.

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_loads');
    if (!columns.track_token) {
      await queryInterface.addColumn('chat_loads', 'track_token', { type: Sequelize.STRING(40), allowNull: true, after: 'invoice_no' });
      await queryInterface.addIndex('chat_loads', ['track_token'], { unique: true, name: 'chat_loads_track_token' });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('chat_loads', 'chat_loads_track_token');
    await queryInterface.removeColumn('chat_loads', 'track_token');
  },
};
