'use strict';

// All trailers are 53 ft; the app and web now show the length as fixed
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.sequelize.query("UPDATE equipment_profiles SET length_ft = 53 WHERE kind = 'trailer'");
  },

  down: async () => {
    // Previous lengths aren't kept; nothing to undo
  },
};
