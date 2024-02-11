//
//  OllamaKit+Chat.swift
//
//
//  Created by Kevin Hermawan on 02/01/24.
//

import Alamofire
import Combine
import Foundation

extension OllamaKit {
    /// Establishes a Combine publisher for streaming chat responses from the Ollama API, based on the provided data.
    ///
    /// This method sets up a streaming connection using the Combine framework, facilitating real-time data handling as chat responses are generated by the Ollama API.
    ///
    /// ```swift
    /// let ollamaKit = OllamaKit(baseURL: URL(string: "http://localhost:11434")!)
    /// let chatData = OKChatRequestData(/* parameters */)
    ///
    /// ollamaKit.chat(data: chatData)
    ///     .sink(receiveCompletion: { completion in
    ///         // Handle completion or error
    ///     }, receiveValue: { chatResponse in
    ///         // Handle each chat response
    ///     })
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// - Parameter data: The ``OKChatRequestData`` used to initiate the chat streaming from the Ollama API.
    /// - Returns: An `AnyPublisher<OKChatResponse, AFError>` emitting the live stream of chat responses from the Ollama API.
    public func chat(data: OKChatRequestData) -> AnyPublisher<OKChatResponse, AFError> {
        let subject = PassthroughSubject<OKChatResponse, AFError>()
        let request = AF.streamRequest(router.chat(data: data)).validate()
        
        request.responseStreamDecodable(of: OKChatResponse.self, using: decoder) { stream in
            switch stream.event {
            case .stream(let result):
                switch result {
                case .success(let response):
                    subject.send(response)
                case .failure(let error):
                    subject.send(completion: .failure(error))
                }
            case .complete(let completion):
                if completion.error != nil {
                    subject.send(completion: .failure(completion.error!))
                } else {
                    subject.send(completion: .finished)
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
}
