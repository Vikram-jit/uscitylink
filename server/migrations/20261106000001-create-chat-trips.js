'use strict';

// Trips (loads) dispatch sends to drivers — server/src/services/trips. They live here; the yard only
// has each trip's Accountant → Route List row (driver_pay_details), which USCityLink creates and keeps
// in sync (routeListSync.ts) and links by chat_trips.driver_pay_details_id.
//   chat_trips:          the trip, who/what, status and times
//   chat_trip_stops:     pickups / drops / switches with local appointment and arrival times
//   chat_trip_events:    the record — every status change, tap, edit, problem (append-only)
//   chat_trip_problems:  delays, breakdowns, lumper / detention amounts
// Times are UTC. Tables are created only when missing.

module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = (await queryInterface.showAllTables()).map((t) => (typeof t === 'string' ? t : t.tableName));
    const id = { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true };
    const timestamps = {
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    };
    const tripRef = {
      type: Sequelize.BIGINT.UNSIGNED,
      allowNull: false,
      references: { model: 'chat_trips', key: 'id' },
      onDelete: 'CASCADE',
    };
    const str = (n = 255) => ({ type: Sequelize.STRING(n), allowNull: true });
    const date = { type: Sequelize.DATE, allowNull: true };

    if (!tables.includes('chat_trips')) {
      await queryInterface.createTable('chat_trips', {
        id,
        trip_no: str(),
        // scheduled → offered → planned → accepted → started → rolling → ended → paperwork →
        // completed → routed; on_hold / cancelled (lifecycle.ts)
        status: { type: Sequelize.STRING(20), allowNull: false, defaultValue: 'scheduled' },
        status_before_hold: str(20),
        source: { type: Sequelize.STRING(10), allowNull: false, defaultValue: 'form' }, // form | typed
        needs_review: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        review_notes: { type: Sequelize.TEXT, allowNull: true },
        driver_profile_id: str(64),
        channel_id: str(64),
        message_id: str(64),
        // Yard ids (drivers / trucks / trailers) for the Route List row
        driver_id_1: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true },
        driver_id_2: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true },
        truck_id: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true },
        trailer_ids: str(),
        truck_number: str(),
        trailer_numbers: str(),
        temperature: str(),
        loaded_trailer: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        notes: { type: Sequelize.TEXT, allowNull: true },
        planned_start_at: date,
        sent_at: date,
        started_at: date,
        ended_at: date,
        completed_at: date,
        completed_by_name: str(),
        total_mileage: { type: Sequelize.DECIMAL(10, 2), allowNull: true },
        // The yard Route List row (driver_pay_details.id)
        driver_pay_details_id: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true },
        created_by: str(64),
        created_by_name: str(),
        raw_text: { type: Sequelize.TEXT, allowNull: true },
        ...timestamps,
      });
      await queryInterface.addIndex('chat_trips', ['status']);
      await queryInterface.addIndex('chat_trips', ['driver_profile_id']);
      await queryInterface.addIndex('chat_trips', ['truck_id']);
      await queryInterface.addIndex('chat_trips', ['message_id']);
      await queryInterface.addIndex('chat_trips', ['driver_pay_details_id']);
    }

    if (!tables.includes('chat_trip_stops')) {
      await queryInterface.createTable('chat_trip_stops', {
        id,
        chat_trip_id: tripRef,
        seq: { type: Sequelize.SMALLINT.UNSIGNED, allowNull: false },
        type: { type: Sequelize.STRING(10), allowNull: false }, // pickup | drop | switch
        name: str(),
        street: str(),
        city: str(),
        state: str(2),
        zip: str(10),
        appointment_local: str(16), // "2026-11-06T03:15", the stop's own time
        appointment_at: date,
        timezone: str(40),
        arrived_at: date,
        departed_at: date,
        ref: str(),
        mileage: { type: Sequelize.DECIMAL(10, 2), allowNull: true }, // from the previous stop
        ...timestamps,
      });
    }

    if (!tables.includes('chat_trip_events')) {
      await queryInterface.createTable('chat_trip_events', {
        id,
        chat_trip_id: tripRef,
        type: { type: Sequelize.STRING(30), allowNull: false },
        from_status: str(20),
        to_status: str(20),
        stop_id: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true },
        actor_role: { type: Sequelize.STRING(20), allowNull: false }, // driver | dispatcher | accountant | ai | system
        actor_id: str(64),
        actor_name: str(),
        note: { type: Sequelize.TEXT, allowNull: true },
        data: { type: Sequelize.JSON, allowNull: true },
        lat: { type: Sequelize.DECIMAL(10, 7), allowNull: true },
        lng: { type: Sequelize.DECIMAL(10, 7), allowNull: true },
        message_id: str(64),
        happened_at: { type: Sequelize.DATE, allowNull: false }, // when it really happened (offline taps arrive later)
        created_at: timestamps.created_at,
      });
      await queryInterface.addIndex('chat_trip_events', ['chat_trip_id', 'happened_at']);
    }

    if (!tables.includes('chat_trip_problems')) {
      await queryInterface.createTable('chat_trip_problems', {
        id,
        chat_trip_id: tripRef,
        kind: { type: Sequelize.STRING(20), allowNull: false },
        note: { type: Sequelize.TEXT, allowNull: true },
        amount: { type: Sequelize.DECIMAL(10, 2), allowNull: true },
        opened_by: str(64),
        opened_by_name: str(),
        resolved_at: date,
        resolved_by_name: str(),
        ...timestamps,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('chat_trip_problems');
    await queryInterface.dropTable('chat_trip_events');
    await queryInterface.dropTable('chat_trip_stops');
    await queryInterface.dropTable('chat_trips');
  },
};
