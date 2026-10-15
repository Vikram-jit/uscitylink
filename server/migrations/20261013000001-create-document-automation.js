'use strict';

const { randomUUID } = require('crypto');

const timestamps = (Sequelize) => ({
  createdAt: {
    type: Sequelize.DATE,
    allowNull: false,
    defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
  },
  updatedAt: {
    type: Sequelize.DATE,
    allowNull: false,
    defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'),
  },
});

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // The server's startup sync() may already have created these tables from the models,
    // so every step here is skipped if it already exists.
    const tables = (await queryInterface.showAllTables()).map((t) => (typeof t === 'string' ? t : t.tableName));
    const createTable = async (name, columns) => {
      if (!tables.includes(name)) await queryInterface.createTable(name, columns);
    };
    const addIndex = async (table, fields, options) => {
      try {
        await queryInterface.addIndex(table, fields, options);
      } catch (err) {
        if (!/Duplicate key name|already exists/i.test(err.message)) throw err;
      }
    };
    const addColumn = async (table, column, definition) => {
      const existing = await queryInterface.describeTable(table);
      if (!existing[column]) await queryInterface.addColumn(table, column, definition);
    };

    await createTable('doc_types', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      key: { type: Sequelize.STRING(64), allowNull: false, unique: true },
      name: { type: Sequelize.STRING, allowNull: false },
      description: { type: Sequelize.TEXT, allowNull: true },
      identify_hints: { type: Sequelize.TEXT, allowNull: true },
      fields: { type: Sequelize.JSON, allowNull: false },
      active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
      version: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 1 },
      ...timestamps(Sequelize),
    });

    await createTable('doc_type_examples', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      doc_type_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'doc_types', key: 'id' },
        onDelete: 'CASCADE',
      },
      s3_key: { type: Sequelize.STRING, allowNull: false },
      expected_fields: { type: Sequelize.JSON, allowNull: false },
      source: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'upload' },
      active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
      created_by: { type: Sequelize.UUID, allowNull: true },
      ...timestamps(Sequelize),
    });

    await createTable('message_documents', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      message_id: { type: Sequelize.UUID, allowNull: false, unique: true },
      media_key: { type: Sequelize.STRING, allowNull: true },
      status: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'pending' },
      doc_type_key: { type: Sequelize.STRING(64), allowNull: true },
      confidence: { type: Sequelize.FLOAT, allowNull: true },
      image_quality: { type: Sequelize.STRING(16), allowNull: true },
      fields: { type: Sequelize.JSON, allowNull: true },
      notes: { type: Sequelize.TEXT, allowNull: true },
      tags: { type: Sequelize.JSON, allowNull: true },
      error: { type: Sequelize.TEXT, allowNull: true },
      model: { type: Sequelize.STRING(64), allowNull: true },
      input_tokens: { type: Sequelize.INTEGER, allowNull: true },
      output_tokens: { type: Sequelize.INTEGER, allowNull: true },
      latency_ms: { type: Sequelize.INTEGER, allowNull: true },
      corrected_by: { type: Sequelize.UUID, allowNull: true },
      corrected_doc_type: { type: Sequelize.STRING(64), allowNull: true },
      corrected_fields: { type: Sequelize.JSON, allowNull: true },
      ...timestamps(Sequelize),
    });
    await addIndex('message_documents', ['doc_type_key']);
    await addIndex('message_documents', ['status']);

    await createTable('flows', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      name: { type: Sequelize.STRING, allowNull: false },
      description: { type: Sequelize.TEXT, allowNull: true },
      trigger: { type: Sequelize.STRING(32), allowNull: false, defaultValue: 'document_analyzed' },
      priority: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 100 },
      active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      shadow_mode: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
      conditions: { type: Sequelize.JSON, allowNull: false },
      actions: { type: Sequelize.JSON, allowNull: false },
      else_actions: { type: Sequelize.JSON, allowNull: true },
      cooldown_minutes: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
      stop_on_match: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      created_by: { type: Sequelize.UUID, allowNull: true },
      updated_by: { type: Sequelize.UUID, allowNull: true },
      ...timestamps(Sequelize),
    });

    await createTable('flow_runs', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      flow_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'flows', key: 'id' },
        onDelete: 'CASCADE',
      },
      message_id: { type: Sequelize.UUID, allowNull: false },
      driver_id: { type: Sequelize.UUID, allowNull: true },
      doc_type_key: { type: Sequelize.STRING(64), allowNull: true },
      matched: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      shadow: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      skipped_reason: { type: Sequelize.STRING, allowNull: true },
      context_snapshot: { type: Sequelize.JSON, allowNull: true },
      condition_trace: { type: Sequelize.JSON, allowNull: true },
      action_results: { type: Sequelize.JSON, allowNull: true },
      error: { type: Sequelize.TEXT, allowNull: true },
      ...timestamps(Sequelize),
    });
    await addIndex('flow_runs', ['flow_id', 'message_id'], { unique: true });
    await addIndex('flow_runs', ['driver_id', 'flow_id', 'createdAt']);

    await addColumn('messages', 'is_automated', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    });
    await addColumn('messages', 'flow_run_id', {
      type: Sequelize.UUID,
      allowNull: true,
    });

    // admin role
    const [existingRole] = await queryInterface.sequelize.query(
      "SELECT id FROM roles WHERE name = 'admin' LIMIT 1",
    );
    if (!existingRole.length) {
      await queryInterface.bulkInsert('roles', [
        { id: randomUUID(), name: 'admin', createdAt: new Date(), updatedAt: new Date() },
      ]);
    }

    // Dispatch Bot user + staff profile used as the sender of automated messages
    const [existingBot] = await queryInterface.sequelize.query(
      "SELECT id FROM users WHERE driver_number = 'bot001' LIMIT 1",
    );
    if (!existingBot.length) {
      const [staffRole] = await queryInterface.sequelize.query(
        "SELECT id FROM roles WHERE name = 'staff' LIMIT 1",
      );
      const botUserId = randomUUID();
      await queryInterface.bulkInsert('users', [
        {
          id: botUserId,
          user_type: 'bot',
          driver_number: 'bot001',
          status: 'active',
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ]);
      await queryInterface.bulkInsert('user_profiles', [
        {
          id: randomUUID(),
          userId: botUserId,
          username: 'Dispatch Assistant',
          role_id: staffRole[0].id,
          isOnline: false,
          status: 'active',
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ]);
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('messages', 'flow_run_id');
    await queryInterface.removeColumn('messages', 'is_automated');
    await queryInterface.dropTable('flow_runs');
    await queryInterface.dropTable('flows');
    await queryInterface.dropTable('message_documents');
    await queryInterface.dropTable('doc_type_examples');
    await queryInterface.dropTable('doc_types');
    await queryInterface.sequelize.query("DELETE FROM roles WHERE name = 'admin'");
    const [bot] = await queryInterface.sequelize.query(
      "SELECT id FROM users WHERE driver_number = 'bot001' LIMIT 1",
    );
    if (bot.length) {
      await queryInterface.sequelize.query('DELETE FROM user_profiles WHERE userId = ?', {
        replacements: [bot[0].id],
      });
      await queryInterface.sequelize.query('DELETE FROM users WHERE id = ?', {
        replacements: [bot[0].id],
      });
    }
  },
};
