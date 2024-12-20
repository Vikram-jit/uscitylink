module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('users', 'yard_id', {
      type: Sequelize.INTEGER, 
      allowNull: true
    });

    await queryInterface.addColumn('users', 'user_type', {
      type: Sequelize.STRING, 
      allowNull: true
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('users', 'yard_id');
    await queryInterface.removeColumn('users', 'user_type');
  }
};
