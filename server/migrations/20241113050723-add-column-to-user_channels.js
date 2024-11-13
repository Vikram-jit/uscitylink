module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('user_channels', 'recieve_message_count', {
      type: Sequelize.INTEGER,  
      defaultValue: 0,       
    });
    await queryInterface.addColumn('user_channels', 'sent_message_count', {
      type: Sequelize.INTEGER,  
      defaultValue: 0,       
    });
    await queryInterface.addColumn('user_channels', 'last_message_utc', {
      type: Sequelize.DATE, // Use Sequelize.DATE for datetime fields
      allowNull: true, // Allow NULL since the field may not always be set initially
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('user_channels', 'recieve_message_count');
    await queryInterface.removeColumn('user_channels', 'send_message_count');
    await queryInterface.removeColumn('user_channels', 'last_message_utc');
  }
};
