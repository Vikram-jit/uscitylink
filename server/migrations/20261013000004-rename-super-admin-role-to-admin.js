'use strict';

const { randomUUID } = require('crypto');

/**
 * The automation module's management role is called "admin" (it was briefly "super_admin").
 * Renames the role on databases that already ran the earlier version of the migration.
 * Safe on databases that never had super_admin.
 */
module.exports = {
  async up(queryInterface) {
    const q = (sql, replacements) => queryInterface.sequelize.query(sql, { replacements });
    const [[legacy]] = await q("SELECT id FROM roles WHERE name = 'super_admin' LIMIT 1");
    const [[admin]] = await q("SELECT id FROM roles WHERE name = 'admin' LIMIT 1");

    if (legacy && !admin) {
      await q("UPDATE roles SET name = 'admin' WHERE id = ?", [legacy.id]);
    } else if (legacy && admin) {
      // Move anyone on the old role over to the existing admin role, then drop the old one
      await q('UPDATE user_profiles SET role_id = ? WHERE role_id = ?', [admin.id, legacy.id]);
      await q('DELETE FROM roles WHERE id = ?', [legacy.id]);
    } else if (!admin) {
      await queryInterface.bulkInsert('roles', [
        { id: randomUUID(), name: 'admin', createdAt: new Date(), updatedAt: new Date() },
      ]);
    }
  },

  async down() {
    // Intentionally a no-op: we cannot tell which "admin" rows used to be super_admin.
  },
};
