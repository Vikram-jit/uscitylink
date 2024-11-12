module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('user_channels', 'last_message_id', {
      type: Sequelize.UUID,
      allowNull: true,
      references: {
        model: 'messages', 
        key: 'id',        
      },
      onUpdate: 'CASCADE', 
      onDelete: 'CASCADE',  
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('user_channels', 'last_message_id');
  }
};
