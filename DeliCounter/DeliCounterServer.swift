//
//  DeliCounterServer.swift
//  DeliCounter
//
//  Created by Daniel Bolella on 3/26/25.
//

import Vapor

public struct DeliCounterServer : Sendable{
    public var addWS: @Sendable (WebSocket)->Void
    public var removeWS: @Sendable (WebSocket)->Void
    
    private func configure(_ app: Application) async throws {
        app.http.server.configuration.hostname = "0.0.0.0" // Bind to all interfaces
        app.http.server.configuration.port = 8080 // Or any preferred port
        try routes(app)
    }
    
    private func routes(_ app: Application) throws {
        app.get { _ -> Response in
            var headers = HTTPHeaders()
            headers.add(name: .contentType, value: "text/html")
            return Response(status: .ok, headers: headers, body: .init(string: htmlPage))
        }
        
        app.webSocket("deli-counter-socket") { req, ws in
            addWS(ws)
            
            ws.onClose.whenComplete { _ in
                removeWS(ws)
            }
        }
    }
    
    public func startAsync() async throws {
        let app = try await Application.make(.testing)
        
        do {
            try await configure(app)
            
            try await app.execute()
            try await app.asyncShutdown()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
    }
    
    // These come from Vapor and are here to simplify getting up and running
    private func sanitizeArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> [String] {
        var commandInput = CommandInput(arguments: arguments)
        sanitize(commandInput: &commandInput)
        return commandInput.executablePath + commandInput.arguments
    }
    
    private func sanitize(commandInput: inout CommandInput) {
        if commandInput.executable.hasSuffix("/usr/bin/xctest") {
            if commandInput.arguments.first?.lowercased() == "-xctest" && commandInput.arguments.count > 1 {
                commandInput.arguments.removeFirst(2)
            }
            if commandInput.arguments.first?.hasSuffix(".xctest") ?? false {
                commandInput.arguments.removeFirst()
            }
        }
    }
    
    // HTML does not need to be here, but for the sake of demo...    
    private let htmlPage = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Deli Now Serving:</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    background-color: white;
                    color: black;
                    text-align: center;
                    transition: background-color 0.3s, color 0.3s;
                }
                body.dark-mode {
                    background-color: #121212;
                    color: #E0E0E0;
                }
                #delicounter {
                    font-size: 24px;
                    margin: 20px;
                    padding: 10px;
                    border: 2px solid #555;
                    border-radius: 5px;
                    display: inline-block;
                    max-width: 90%;
                    text-align: center;
                    word-wrap: break-word;
                }
                .controls {
                    margin-top: 10px;
                }
                button {
                    margin: 5px;
                    padding: 10px 15px;
                    font-size: 16px;
                    cursor: pointer;
                    border-radius: 5px;
                    border: 1px solid #555;
                    background-color: #f0f0f0;
                    transition: background-color 0.2s;
                }
                button:focus {
                    outline: 3px solid #007BFF;
                }
                button:hover {
                    background-color: #ddd;
                }
                body.dark-mode button {
                    background-color: #333;
                    color: white;
                    border: 1px solid white;
                }
                body.dark-mode button:hover {
                    background-color: #555;
                }
                .toggle-switch {
                    display: inline-flex;
                    align-items: center;
                    cursor: pointer;
                    padding: 10px;
                }
                .switch-label {
                    margin-left: 8px;
                    font-size: 16px;
                }
            </style>
        </head>
        <body>
        
            <h1 id="page-title">Deli Now Serving</h1>
            
            <p id="delicounter" role="region" aria-live="polite" aria-atomic="true">
                Waiting for counter...
            </p>
        
            <div class="controls">
                <button id="increase-font" aria-label="Increase text size">Increase Text Size</button>
                <button id="decrease-font" aria-label="Decrease text size">Decrease Text Size</button>
                <button id="reset-settings" aria-label="Reset settings to default">Reset</button>
        
                <div class="toggle-switch" role="switch" tabindex="0" id="dark-mode-toggle">
                    <button id="toggle-dark" aria-label="Toggle dark mode">Toggle Dark Mode</button>
                </div>
            </div>
        
            <script>
                const ws = new WebSocket("ws://" + window.location.host + "/deli-counter-socket");
        
                ws.onmessage = (event) => {
                    document.getElementById("delicounter").innerText = event.data;
                };
        
                // Accessibility & UI Enhancements
                const delicounterElement = document.getElementById("delicounter");
                const increaseFontBtn = document.getElementById("increase-font");
                const decreaseFontBtn = document.getElementById("decrease-font");
                const resetBtn = document.getElementById("reset-settings");
                const toggleDarkBtn = document.getElementById("toggle-dark");
                const darkModeToggle = document.getElementById("dark-mode-toggle");
        
                let fontSize = parseInt(localStorage.getItem("fontSize")) || 24;
                let isDarkMode = localStorage.getItem("darkMode") === "true";
        
                delicounterElement.style.fontSize = fontSize + "px";
                if (isDarkMode) {
                    document.body.classList.add("dark-mode");
                }
        
                function changeFontSize(change) {
                    fontSize = Math.max(16, fontSize + change);
                    delicounterElement.style.fontSize = fontSize + "px";
                    localStorage.setItem("fontSize", fontSize);
                }
        
                function toggleDarkMode() {
                    isDarkMode = !document.body.classList.contains("dark-mode");
                    document.body.classList.toggle("dark-mode", isDarkMode);
                    localStorage.setItem("darkMode", isDarkMode);
                }
        
                function resetSettings() {
                    fontSize = 24;
                    delicounterElement.style.fontSize = fontSize + "px";
                    document.body.classList.remove("dark-mode");
                    localStorage.setItem("fontSize", fontSize);
                    localStorage.setItem("darkMode", "false");
                }
        
                increaseFontBtn.addEventListener("click", () => changeFontSize(2));
                decreaseFontBtn.addEventListener("click", () => changeFontSize(-2));
                toggleDarkBtn.addEventListener("click", toggleDarkMode);
                resetBtn.addEventListener("click", resetSettings);
        
                // Keyboard accessibility (Arrow Keys, Space, Enter)
                document.addEventListener("keydown", (event) => {
                    if (event.key === "ArrowUp") changeFontSize(2);
                    if (event.key === "ArrowDown") changeFontSize(-2);
                    if (event.key === "r") resetSettings();
                });
        
                darkModeToggle.addEventListener("keypress", (event) => {
                    if (event.key === "Enter" || event.key === " ") {
                        toggleDarkMode();
                    }
                });
            </script>
        
        </body>
        </html>
        
        """
}
