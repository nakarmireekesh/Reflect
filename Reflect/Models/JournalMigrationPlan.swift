import SwiftData

/// No migrations yet — there's only one schema version. When a future
/// change needs one, add the new version to `schemas` and describe how to
/// get from the previous one to it in `stages`.
enum JournalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [JournalSchemaV1.self]
    static var stages: [MigrationStage] = []
}
