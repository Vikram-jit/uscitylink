'use strict';

// A short tracking code per load (6 letters/digits, no look-alikes) — typed into the app's
// "Track a load" screen; same view as the /track/<token> link and expires the same way (completed).

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_loads');
    if (!columns.track_code) {
      await queryInterface.addColumn('chat_loads', 'track_code', { type: Sequelize.STRING(8), allowNull: true, after: 'track_token' });
      await queryInterface.addIndex('chat_loads', ['track_code'], { unique: true, name: 'chat_loads_track_code' });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('chat_loads', 'chat_loads_track_code');
    await queryInterface.removeColumn('chat_loads', 'track_code');
  },
};
