//
//  SendCodeIntegrationTests.swift
//  chakchatTests
//
//  Created by Кирилл Исаев on 16.01.2025.
//

import XCTest
import OSLog

// MARK: - SendCodeIntegrationTests
@testable import chakchat
final class SendCodeIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    var mockSender: MockSender?
    var mockSendCodeService: MockIdentityService<SuccessModels.SendCodeSignupData>?
    var mockSendCodeWorker: MockWorker?
    var mockSendCodePresenter: MockSendCodePresenter?
    var mockErrorHandler: MockErrorHandler?
    var interactor: SendCodeInteractor?

    // MARK: - Override Methods
    override func setUpWithError() throws {
        mockSender = MockSender()
        mockSendCodeService = MockIdentityService()
        mockSendCodeWorker = MockWorker()
        mockSendCodePresenter = MockSendCodePresenter()
        mockErrorHandler = MockErrorHandler()
        
        let sendCodeInteractor: SendCodeInteractor? = {
            guard let presenter = mockSendCodePresenter,
                  let worker = mockSendCodeWorker,
                  let errorHandler = mockErrorHandler else {
                fatalError("Dependencies are not set")
            }
            return SendCodeInteractor(
                presenter: presenter,
                errorHandler: errorHandler, 
                logger: OSLog(subsystem: "con.chakchat.tests", category: "TestsLog")
            )
        }()
        interactor = sendCodeInteractor
    }

    override func tearDownWithError() throws {
        mockSender = nil
        mockSendCodeService = nil
        mockSendCodeWorker = nil
        mockSendCodePresenter = nil
        interactor = nil
    }

    // MARK: - Tests
    func testSuccess() throws {
        let uuid = UUID()
        mockSender?.result = .success(Data("{\"signupKey\": \"\(uuid)\"}".utf8))
        mockSendCodeService?.result = .success(SuccessModels.SendCodeSignupData(signupKey: uuid))
        mockSendCodeWorker?.result = .success(SignupState.signin)
        
        let expectation = self.expectation(description: "Test success called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.mockSendCodePresenter?.isErrorShown == true, "Error should not be shown")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testInternalError() throws {
        mockSender?.result = .failure(
            APIErrorResponse(
                errorType: ApiErrorType.internalError.rawValue,
                errorMessage: "",
                errorDetails: nil)
        )
        mockSendCodeService?.result = .failure(
            APIErrorResponse(
                errorType: ApiErrorType.internalError.rawValue,
                errorMessage: "",
                errorDetails: nil)
        )
        mockSendCodeWorker?.result = .failure(
            APIErrorResponse(
                errorType: ApiErrorType.internalError.rawValue,
                errorMessage: "",
                errorDetails: nil)
        )
        
        let expectation = self.expectation(description: "Test failure called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.mockSendCodePresenter?.isErrorShown == true, "Error should be shown")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testInvalidURL() throws {
        mockSender?.result = .failure(APIError.invalidURL)
        mockSendCodeService?.result = .failure(APIError.invalidURL)
        mockSendCodeWorker?.result = .failure(APIError.invalidURL)
        
        let expectation = self.expectation(description: "Test invalid url called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? APIError else {
                XCTFail("handledError is not of type APIError")
                return
            }
            
            XCTAssertEqual(APIError.invalidURL, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
    }
    
    func testInvalidRequest() throws {
        mockSender?.result = .failure(APIError.invalidRequest)
        mockSendCodeService?.result = .failure(APIError.invalidRequest)
        mockSendCodeWorker?.result = .failure(APIError.invalidRequest)
        
        let expectation = self.expectation(description: "Test invalid request called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? APIError else {
                XCTFail("handledError is not of type APIError")
                return
            }
            XCTAssertEqual(APIError.invalidRequest, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testNoData() throws {
        mockSender?.result = .failure(APIError.noData)
        mockSendCodeService?.result = .failure(APIError.noData)
        mockSendCodeWorker?.result = .failure(APIError.noData)
        
        let expectation = self.expectation(description: "Test no data called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? APIError else {
                XCTFail("handledError is not of type APIError")
                return
            }
            XCTAssertEqual(APIError.noData, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testInvalidJson() throws {
        mockSender?.result = .failure(ApiErrorType.invalidJson)
        mockSendCodeService?.result = .failure(ApiErrorType.invalidJson)
        mockSendCodeWorker?.result = .failure(ApiErrorType.invalidJson)
        
        let expectation = self.expectation(description: "Test invalid json called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? ApiErrorType else {
                XCTFail("handledError is not of type APIError")
                return
            }
            XCTAssertEqual(ApiErrorType.invalidJson, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testValidationError() throws {
        mockSender?.result = .failure(ApiErrorType.validationFailed)
        mockSendCodeService?.result = .failure(ApiErrorType.validationFailed)
        mockSendCodeWorker?.result = .failure(ApiErrorType.validationFailed)
        
        let expectation = self.expectation(description: "Test validation failed called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? ApiErrorType else {
                XCTFail("handledError is not of type ApiErrorType")
                return
            }
            XCTAssertEqual(ApiErrorType.validationFailed, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testKeychaingSaveError() throws {
        let uuid = UUID()
        mockSender?.result = .success(Data("{\"signupKey\": \"\(uuid)\"}".utf8))
        mockSendCodeService?.result = .success(SuccessModels.SendCodeSignupData(signupKey: uuid))
        mockSendCodeWorker?.result = .failure(Keychain.KeychainError.saveError)
        
        let expectation = self.expectation(description: "Test keychain save error called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? Keychain.KeychainError else {
                XCTFail("handledError is not of type KeychainError")
                return
            }
            XCTAssertEqual(Keychain.KeychainError.saveError, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testUserAlreadyExists() throws {
        mockSender?.result = .failure(ApiErrorType.userAlreadyExists)
        mockSendCodeService?.result = .failure(ApiErrorType.userAlreadyExists)
        mockSendCodeWorker?.result = .failure(ApiErrorType.userAlreadyExists)
        
        let expectation = self.expectation(description: "Test user already exists called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? ApiErrorType else {
                XCTFail("handledError is not of type ApiErrorType")
                return
            }
            XCTAssertEqual(ApiErrorType.userAlreadyExists, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendCodeFreqExceeded() throws {
        mockSender?.result = .failure(ApiErrorType.sendCodeFreqExceeded)
        mockSendCodeService?.result = .failure(ApiErrorType.sendCodeFreqExceeded)
        mockSendCodeWorker?.result = .failure(ApiErrorType.sendCodeFreqExceeded)
        
        let expectation = self.expectation(description: "Test send code freq exceeded called")
        
        interactor?.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let handledError = self.mockErrorHandler?.handledError as? ApiErrorType else {
                XCTFail("handledError is not of type ApiErrorType")
                return
            }
            XCTAssertEqual(ApiErrorType.sendCodeFreqExceeded, handledError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}
