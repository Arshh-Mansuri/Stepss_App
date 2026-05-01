import Foundation
import SwiftData

enum ModelContainerFactory {
    static let storeFilename = "StrideTime.sqlite"

    static func makeShared() throws -> ModelContainer {
        let schema = Schema(AppSchemaV1.models)
        let url = AppGroup.containerURL.appendingPathComponent(storeFilename)
        let config = ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
