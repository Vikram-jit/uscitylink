module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('user_profiles', 'isAdmin', {
      type: Sequelize.INTEGER, 
      defaultValue: 0,       
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('user_profiles', 'isAdmin');
  }
};
