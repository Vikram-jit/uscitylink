module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('user_channels', 'status', {
      type: Sequelize.STRING, 
      allowNull: false,
      defaultValue:"active" 
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('user_channels', 'status');
  }
};
