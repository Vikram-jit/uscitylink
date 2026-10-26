'use strict';

// Trailers start at the standard 53 ft; staff can change a trailer's length afterwards
module.exports = {
  up: async (queryInterface) => {
    await queryInterface.sequelize.query("UPDATE equipment_profiles SET length_ft = 53 WHERE kind = 'trailer' AND length_ft IS NULL");
  },

  down: async () => {
    // Previous lengths aren't kept; nothing to undo
  },
};
