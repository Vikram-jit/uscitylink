module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('messages', 'reply_message_id', {
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
    
    await queryInterface.removeColumn('messages', 'reply_message_id');

   
    
  }
};
