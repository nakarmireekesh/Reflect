/// `JournalEntry` lives inside `JournalSchemaV1` so a future schema
/// version can introduce its own shape alongside a migration stage. See
/// `JournalSchemaV1` and `JournalMigrationPlan`.
typealias JournalEntry = JournalSchemaV1.JournalEntry
