import 'package:powersync/powersync.dart';

/// Defines the local SQLite schema used by PowerSync.
/// This must mirror the tables/columns you have in your backend database.
const schema = Schema([
  Table('users', [
    Column.text('user_email'),
    Column.text('created_at'),
    Column.text('user_id'),
  ]),
  Table('combined_user_and_repair', [
    Column.text('user_email'),
    Column.text('created_at'),
    Column.text('user_id'),
    Column.text('description'),
    Column.text('status'),
  ]),
  Table('repair_request', [
    Column.text('user_id'),
    Column.text('description'),
    Column.text('status'),
    Column.text('created_at'),
  ]),
]);
