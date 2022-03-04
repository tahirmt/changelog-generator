//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-12-10.
//

import Foundation
import Quick
import Nimble

struct NoResultError: Error {}

/// Helper method to await on an `async` method.
/// - Throws: Any errors thrown by the async method
/// - Returns: Returns the output of the block
func awaitAsync<T>(file: FileString = #file, line: UInt = #line, timeout: DispatchTimeInterval = .seconds(5), _ function: @escaping () async throws -> T) throws -> T {
    func fetch(completion: @escaping (Result<T, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await function()))
            }
            catch {
                completion(.failure(error))
            }
        }
    }

    var outputs: [Result<T, Error>] = []

    waitUntil(timeout: timeout) { done in
        fetch { result in
            outputs.append(result)
            done()
        }
    }

    guard let output = outputs.first else {
        throw NoResultError()
    }

    return try output.get()
}

/// Helper method to `await` on an `async` method that does not throw
/// - Throws: An error if there was no result received. This can only happen if timed out
/// - Returns: The result of the function
func awaitAsync<T>(file: FileString = #file, line: UInt = #line, timeout: DispatchTimeInterval = .seconds(5), _ function: @escaping () async -> T) throws -> T {
    func fetch(completion: @escaping (T) -> Void) {
        Task {
            completion(await function())
        }
    }

    var outputs: [T] = []

    waitUntil(timeout: timeout) { done in
        fetch { result in
            outputs.append(result)
            done()
        }
    }

    guard let output = outputs.first else {
        throw NoResultError()
    }

    return output
}
