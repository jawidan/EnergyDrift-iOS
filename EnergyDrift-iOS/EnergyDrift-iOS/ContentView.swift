import SwiftUI

struct ContentView: View {
    private let scenarios: [any TestScenario] = [IdleBaselineScenario()] + BranchScenarios.all

    @State private var selectedIndex = 0
    @State private var iterationCountText = "30"
    @State private var isRunning = false
    @State private var completedIterations = 0
    @State private var totalIterations = 0
    @State private var savedFileName: String?
    @State private var errorMessage: String?

    @AppStorage("mockServerBaseURL") private var mockServerBaseURL = "http://192.168.1.100:5000"

    var body: some View {
        Form {
            Section("Scenario") {
                Picker("Scenario", selection: $selectedIndex) {
                    ForEach(scenarios.indices, id: \.self) { index in
                        Text(scenarios[index].scenarioName).tag(index)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Configuration") {
                TextField("Iterations", text: $iterationCountText)
                    .keyboardType(.numberPad)
                TextField("Mock server base URL", text: $mockServerBaseURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
            }

            Section("Run") {
                Button(isRunning ? "Running…" : "Run") {
                    startRun()
                }
                .disabled(isRunning || scenarios.isEmpty)

                if isRunning {
                    Text("\(completedIterations)/\(totalIterations)")
                }

                if let savedFileName {
                    Text("Done — CSV saved: \(savedFileName)")
                }

                if let errorMessage {
                    Text("Error: \(errorMessage)")
                }
            }
        }
    }

    private func startRun() {
        guard let iterations = Int(iterationCountText), iterations > 0 else {
            errorMessage = "Invalid iteration count"
            return
        }
        guard scenarios.indices.contains(selectedIndex) else { return }

        let scenario = scenarios[selectedIndex]
        savedFileName = nil
        errorMessage = nil
        completedIterations = 0
        totalIterations = iterations
        isRunning = true

        Task {
            do {
                let runner = TestRunner()
                let fileName = try await runner.run(scenario: scenario, iterations: iterations) { progress in
                    completedIterations = progress.completed
                    totalIterations = progress.total
                }
                savedFileName = fileName
            } catch {
                errorMessage = error.localizedDescription
            }
            isRunning = false
        }
    }
}

#Preview {
    ContentView()
}
