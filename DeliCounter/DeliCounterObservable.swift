//
//  DeliCounterViewModel.swift
//  DeliCounter
//
//  Created by Daniel Bolella on 3/26/25.
//

import Observation
import Vapor

@Observable
class DeliCounterObservable {
    var currentCustomerServed: Int = 0
    
    @ObservationIgnored
    private var sockets: [WebSocket] = []
    
    @Sendable func addWS(_ ws: WebSocket) {
        sockets.append(ws)
        ws.send(String(currentCustomerServed))
    }
    
    @Sendable func removeWS(_ ws: WebSocket) {
        sockets.removeAll { $0 === ws }
    }
    
    private func broadcastToCustomers(text: String) {
        for client in sockets {
            client.send(text)
        }
    }
    
    func nextCustomer() {
        self.currentCustomerServed = self.currentCustomerServed + 1
        broadcastToCustomers(text: String(self.currentCustomerServed))
    }
    
    func previousCustomer() {
        self.currentCustomerServed = self.currentCustomerServed - 1
        broadcastToCustomers(text: String(self.currentCustomerServed))
    }
}
