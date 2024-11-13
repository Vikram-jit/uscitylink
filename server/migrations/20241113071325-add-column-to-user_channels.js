module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('user_channels', 'last_message_utc', {
      type: Sequelize.DATE, 
      allowNull: true, 
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('user_channels', 'last_message_utc');
  }
};
