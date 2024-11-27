module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('groups', 'type', {
      type: Sequelize.ENUM('group', 'truck'),  // Enum with valid values
      allowNull: false, // Ensure the field cannot be null
      defaultValue: 'group' // Set default value
    });
  },

  down: async (queryInterface, Sequelize) => {
    // Remove the 'type' column from 'groups' table
    await queryInterface.removeColumn('groups', 'type');
    // Drop the ENUM type (if you want to clean up after removing the column)
    await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_groups_type"');
  }
};
