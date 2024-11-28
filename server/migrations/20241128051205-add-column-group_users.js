module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('group_users', 'status', {
      type: Sequelize.ENUM('active', 'inactive'),  
      allowNull: false, 
      defaultValue: 'active'
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('group_users', 'status');
  
    await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_groups_type"');
  }
};
