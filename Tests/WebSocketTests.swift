//
//  WebSocketTests.swift
//  Alamofire
//
//  Created by Jon Shier on 1/17/21.
//  Copyright © 2021 Alamofire. All rights reserved.
//

#if canImport(Darwin) && !canImport(FoundationNetworking)

import Alamofire
import Foundation
import XCTest

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
final class WebSocketTests: BaseTestCase {
//    override var skipVersion: SkipVersion { .twenty }

    func testThatWebSocketsCanReceiveMessageEvents() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())

        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket()).streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, didComplete],
             timeout: timeout,
             enforceOrder: false)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketsCanReceiveAMessage() {
        // Given
        let didReceiveMessage = expectation(description: "didReceiveMessage")

        let session = stored(Session())

        var receivedMessage: URLSessionWebSocketTask.Message?

        // When
        session.websocketRequest(.websocket()).streamMessages { message in
            receivedMessage = message
            didReceiveMessage.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(receivedMessage)
        XCTAssertNotNil(receivedMessage?.data)
    }

    func testThatWebSocketsCanReceiveADecodableMessage() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())

        var connectedProtocol: String?
        var message: TestResponse?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocketCount(1)).streamDecodableEvents(TestResponse.self) { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
            case let .serializerFailed(error):
                XCTFail("websocket message serialization failed with error: \(error)")
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, didComplete],
             timeout: timeout,
             enforceOrder: false)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketsCanReceiveADecodableValue() {
        // Given
        let didReceiveValue = expectation(description: "didReceiveMessage")

        let session = stored(Session())

        var receivedValue: TestResponse?

        // When
        session.websocketRequest(.websocket()).streamDecodable(TestResponse.self) { value in
            receivedValue = value
            didReceiveValue.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(receivedValue)
    }

    func testThatWebSocketsCanReceiveAMessageWithAProtocol() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())

        let `protocol` = "protocol"
        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket(), protocol: `protocol`).streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, didComplete],
             timeout: timeout,
             enforceOrder: true)

        // Then
        XCTAssertEqual(connectedProtocol, `protocol`)
        XCTAssertNotNil(message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketsCanReceiveMultipleMessages() {
        // Given
        let count = 5
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        didReceiveMessage.expectedFulfillmentCount = count
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")

        let session = stored(Session())

        var connectedProtocol: String?
        var messages: [URLSessionWebSocketTask.Message] = []
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocketCount(count)).streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                messages.append(receivedMessage)
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, didComplete], timeout: timeout, enforceOrder: true)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertEqual(messages.count, count)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketsCanSendAndReceiveMessages() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didSend = expectation(description: "didSend")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())
        let sentMessage = URLSessionWebSocketTask.Message.string("Echo")

        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        let request = session.websocketRequest(.websocketEcho)
        request.streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
                request.send(sentMessage) { _ in didSend.fulfill() }
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                event.close(sending: .normalClosure)
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didSend, didReceiveMessage, didDisconnect, didComplete],
             timeout: timeout,
             enforceOrder: true)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(sentMessage, message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketsCanBeCancelled() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())

        var connectedProtocol: String?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        let request = session.websocketRequest(.websocketEcho)
        request.streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
                request.cancel()
            case let .receivedMessage(receivedMessage):
                XCTFail("cancelled socket received message: \(receivedMessage)")
            case .disconnected:
                XCTFail("cancelled socket shouldn't receive disconnected event")
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didComplete], timeout: timeout, enforceOrder: true)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertTrue(receivedCompletion?.error?.isExplicitlyCancelledError == true)
        XCTAssertTrue(request.error?.isExplicitlyCancelledError == true)
    }

    func testOnePingOnly() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didSend = expectation(description: "didSend")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didReceivePong = expectation(description: "didReceivePong")
        didReceivePong.expectedFulfillmentCount = 100
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())
        let sentMessage = URLSessionWebSocketTask.Message.string("Echo")

        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var receivedPong: WebSocketRequest.PingResponse.Pong?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        let request = session.websocketRequest(.websocketEcho)
        request.streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
                request.send(sentMessage) { _ in didSend.fulfill() }
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
                for count in 0..<100 {
                    request.sendPing { response in
                        switch response {
                        case let .pong(pong):
                            receivedPong = pong
                        default:
                            break
                        }
                        didReceivePong.fulfill()
                        if count == 99 {
                            request.close(sending: .normalClosure)
                        }
                    }
                }
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didSend, didReceiveMessage, didReceivePong, didDisconnect, didComplete],
             timeout: timeout,
             enforceOrder: true)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(sentMessage, message)
        XCTAssertEqual(closeCode, .normalClosure)
        XCTAssertNil(closeReason)
        XCTAssertNotNil(receivedCompletion)
//        XCTAssertNil(receivedCompletion?.error)
        XCTAssertNotNil(receivedPong)
    }

    func testThatTimePingsOccur() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())

        var connectedProtocol: String?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        let request = session.websocketRequest(.websocketPings(), pingInterval: 0.01)
        request.streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case .receivedMessage:
                break
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didDisconnect, didComplete], timeout: timeout, enforceOrder: true)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertEqual(closeCode, .goingAway) // Default Vapor close() code.
        XCTAssertNil(closeReason)
        XCTAssertNotNil(receivedCompletion)
        XCTAssertNil(receivedCompletion?.error)
    }

    func testThatWebSocketFailsWithTooSmallMaximumMessageSize() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())

        var connectedProtocol: String?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket(), maximumMessageSize: 1).streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case .receivedMessage, .disconnected:
                break
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didComplete], timeout: timeout, enforceOrder: false)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(receivedCompletion?.error)
    }

    func testThatWebSocketsFinishAfterNonNormalResponseCode() {
        // Given
        let didConnect = expectation(description: "didConnect")
        let didReceiveMessage = expectation(description: "didReceiveMessage")
        let didDisconnect = expectation(description: "didDisconnect")
        let didComplete = expectation(description: "didComplete")
        let session = stored(Session())

        var connectedProtocol: String?
        var message: URLSessionWebSocketTask.Message?
        var closeCode: URLSessionWebSocketTask.CloseCode?
        var closeReason: Data?
        var receivedCompletion: WebSocketRequest.Completion?

        // When
        session.websocketRequest(.websocket(closeCode: .goingAway)).streamMessageEvents { event in
            switch event.kind {
            case let .connected(`protocol`):
                connectedProtocol = `protocol`
                didConnect.fulfill()
            case let .receivedMessage(receivedMessage):
                message = receivedMessage
                didReceiveMessage.fulfill()
            case let .disconnected(code, reason):
                closeCode = code
                closeReason = reason
                didDisconnect.fulfill()
            case let .completed(completion):
                receivedCompletion = completion
                didComplete.fulfill()
            }
        }

        wait(for: [didConnect, didReceiveMessage, didDisconnect, didComplete],
             timeout: timeout,
             enforceOrder: false)

        // Then
        XCTAssertNil(connectedProtocol)
        XCTAssertNotNil(message)
        XCTAssertEqual(closeCode, .goingAway)
        XCTAssertNil(closeReason)
        XCTAssertNil(receivedCompletion?.error)
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension URLSessionWebSocketTask.Message: Equatable {
    public static func ==(lhs: URLSessionWebSocketTask.Message, rhs: URLSessionWebSocketTask.Message) -> Bool {
        switch (lhs, rhs) {
        case let (.string(left), .string(right)):
            return left == right
        case let (.data(left), .data(right)):
            return left == right
        default:
            return false
        }
    }

    var string: String? {
        guard case let .string(string) = self else { return nil }

        return string
    }

    var data: Data? {
        guard case let .data(data) = self else { return nil }

        return data
    }
}

#endif
