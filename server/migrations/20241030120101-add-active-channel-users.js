module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('user_profiles', 'channelId', {
      type: Sequelize.UUID,
      allowNull: true,
      references: {
        model: 'channels', // The table name
        key: 'id',        // The column name in the referenced table
      },
      onUpdate: 'CASCADE', // Optional: Update the user profile if the channel ID changes
      onDelete: 'CASCADE',  // Optional: Delete user profiles if the referenced channel is deleted
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('user_profiles', 'channelId');
  }
};
