import 'package:powersync/powersync.dart';

/// Defines the local SQLite schema used by PowerSync.
/// This must mirror the tables/columns you have in your backend database.
const schema = Schema([
  Table('users', [
    Column.text('first_name'),
    Column.text('created_at'),
    Column.text('user_id'),
  ]),
  Table('combined_user_data', [
    Column.text('first_name'),
    Column.text('created_at'),
    Column.text('user_id'),
    Column.text('favorite_color'),
  ]),
]);
