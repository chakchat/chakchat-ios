//
//  SendCodeIntegrationTests.swift
//  chakchatTests
//
//  Created by Кирилл Исаев on 16.01.2025.
//

import XCTest

@testable import chakchat
final class SendCodeIntegrationTests: XCTestCase {
    
    var mockSender: MockSender!
    var mockSendCodeService: MockSendCodeService!
    var mockSendCodeWorker: MockWorker!
    var mockSendCodePresenter: MockSendCodePresenter!
    var mockErrorHandler: MockErrorHandler!
    var interactor: SendCodeInteractor!

    override func setUpWithError() throws {
        mockSender = MockSender()
        mockSendCodeService = MockSendCodeService()
        mockSendCodeWorker = MockWorker()
        mockSendCodePresenter = MockSendCodePresenter()
        mockErrorHandler = MockErrorHandler()
        
        interactor = SendCodeInteractor(presenter: mockSendCodePresenter,
                                        worker: mockSendCodeWorker,
                                        state: AppState.sendPhoneCode,
                                        errorHandler: mockErrorHandler)
    }

    override func tearDownWithError() throws {
        mockSender = nil
        mockSendCodeService = nil
        mockSendCodeWorker = nil
        mockSendCodePresenter = nil
        interactor = nil
    }

    func testSuccess() throws {
        let uuid = UUID()
        mockSender.result = .success(Data("{\"signupKey\": \"\(uuid)\"}".utf8))
        mockSendCodeService.result = .success(SuccessModels.SendCodeSignupData(signupKey: uuid))
        mockSendCodeWorker.result = .success(AppState.signin)
        
        let expectation = self.expectation(description: "Test success called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.mockSendCodePresenter.isErrorShown, "Error should not be shown")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testInternalError() throws {
        mockSender.result = .failure(
            APIErrorResponse(
                errorType: ApiErrorType.internalError.rawValue,
                errorMessage: "",
                errorDetails: nil)
        )
        mockSendCodeService.result = .failure(
            APIErrorResponse(
                errorType: ApiErrorType.internalError.rawValue,
                errorMessage: "",
                errorDetails: nil)
        )
        mockSendCodeWorker.result = .failure(
            APIErrorResponse(
                errorType: ApiErrorType.internalError.rawValue,
                errorMessage: "",
                errorDetails: nil)
        )
        
        let expectation = self.expectation(description: "Test failure called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.mockSendCodePresenter.isErrorShown, "Error should be shown")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testInvalidURL() throws {
        mockSender.result = .failure(APIError.invalidURL)
        mockSendCodeService.result = .failure(APIError.invalidURL)
        mockSendCodeWorker.result = .failure(APIError.invalidURL)
        
        let expectation = self.expectation(description: "Test invalid url called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(APIError.invalidURL, self.mockErrorHandler.handledError as! APIError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
    }
    
    func testInvalidRequest() throws {
        mockSender.result = .failure(APIError.invalidRequest)
        mockSendCodeService.result = .failure(APIError.invalidRequest)
        mockSendCodeWorker.result = .failure(APIError.invalidRequest)
        
        let expectation = self.expectation(description: "Test invalid request called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(APIError.invalidRequest, self.mockErrorHandler.handledError as! APIError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testNoData() throws {
        mockSender.result = .failure(APIError.noData)
        mockSendCodeService.result = .failure(APIError.noData)
        mockSendCodeWorker.result = .failure(APIError.noData)
        
        let expectation = self.expectation(description: "Test no data called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(APIError.noData, self.mockErrorHandler.handledError as! APIError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testInvalidJson() throws {
        mockSender.result = .failure(ApiErrorType.invalidJson)
        mockSendCodeService.result = .failure(ApiErrorType.invalidJson)
        mockSendCodeWorker.result = .failure(ApiErrorType.invalidJson)
        
        let expectation = self.expectation(description: "Test invalid json called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(ApiErrorType.invalidJson, self.mockErrorHandler.handledError as! ApiErrorType)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testValidationError() throws {
        mockSender.result = .failure(ApiErrorType.validationFailed)
        mockSendCodeService.result = .failure(ApiErrorType.validationFailed)
        mockSendCodeWorker.result = .failure(ApiErrorType.validationFailed)
        
        let expectation = self.expectation(description: "Test validation failed called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(ApiErrorType.validationFailed, self.mockErrorHandler.handledError as! ApiErrorType)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testKeychaingSaveError() throws {
        var uuid = UUID()
        mockSender.result = .success(Data("{\"signupKey\": \"\(uuid)\"}".utf8))
        mockSendCodeService.result = .success(SuccessModels.SendCodeSignupData(signupKey: uuid))
        mockSendCodeWorker.result = .failure(Keychain.KeychainError.saveError)
        
        let expectation = self.expectation(description: "Test keychain save error called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(Keychain.KeychainError.saveError, self.mockErrorHandler.handledError as! Keychain.KeychainError)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testUserAlreadyExists() throws {
        mockSender.result = .failure(ApiErrorType.userAlreadyExists)
        mockSendCodeService.result = .failure(ApiErrorType.userAlreadyExists)
        mockSendCodeWorker.result = .failure(ApiErrorType.userAlreadyExists)
        
        let expectation = self.expectation(description: "Test user already exists called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(ApiErrorType.userAlreadyExists, self.mockErrorHandler.handledError as! ApiErrorType)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSendCodeFreqExceeded() throws {
        mockSender.result = .failure(ApiErrorType.sendCodeFreqExceeded)
        mockSendCodeService.result = .failure(ApiErrorType.sendCodeFreqExceeded)
        mockSendCodeWorker.result = .failure(ApiErrorType.sendCodeFreqExceeded)
        
        let expectation = self.expectation(description: "Test send code freq exceeded called")
        
        interactor.sendCodeRequest(SendCodeModels.SendCodeRequest(phone: "79776002210"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(ApiErrorType.sendCodeFreqExceeded, self.mockErrorHandler.handledError as! ApiErrorType)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}
