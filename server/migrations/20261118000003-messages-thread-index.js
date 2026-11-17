'use strict';

// Opening a driver's chat reads the latest messages of one driver in one channel, newest first.
// Without this index the database merges two single-column indexes and sorts every message of the
// driver on each click; with it the newest 10 are read straight off the index.

const NAME = 'messages_thread_idx';

module.exports = {
  async up(queryInterface) {
    const indexes = await queryInterface.showIndex('messages');
    if (indexes.some((i) => i.name === NAME)) return;
    await queryInterface.addIndex('messages', ['userProfileId', 'channelId', 'messageTimestampUtc'], { name: NAME });
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('messages', NAME);
  },
};
