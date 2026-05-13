import Foundation
import SwiftData

enum ModelContainerFactory {
    static let storeFilename = "StepLock.sqlite"

    /// Currently dormant — SwiftData isn't wired up. When it is, this will
    /// place the store in the App Group container if the capability is on,
    /// otherwise in the app's own Documents directory (single-process-only).
    static func makeShared() throws -> ModelContainer {
        let schema = Schema(AppSchemaV1.models)
        let baseURL = AppGroup.containerURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = baseURL.appendingPathComponent(storeFilename)
        let config = ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
