import Testing
import Foundation
@testable import PecanShared

/// Smoke tests for key proto message construction and field access.
/// These verify the generated Swift code is correct and that field name
/// conventions (camelCase from snake_case) are what the rest of the
/// codebase expects.
@Suite("ProtoMessages")
struct ProtoMessageTests {

    // MARK: - ClientMessage

    @Test("StartTaskRequest fields are settable")
    func startTaskRequest() {
        let req = Pecan_StartTaskRequest.with {
            $0.initialPrompt = "Hello"
            $0.projectName = "pecan"
            $0.teamName = "core"
            $0.persistent = true
        }
        #expect(req.initialPrompt == "Hello")
        #expect(req.projectName == "pecan")
        #expect(req.teamName == "core")
        #expect(req.persistent == true)
        #expect(req.forkSessionID.isEmpty)
    }

    @Test("ClientMessage wraps StartTaskRequest")
    func clientMessageStartTask() {
        var msg = Pecan_ClientMessage()
        msg.startTask = Pecan_StartTaskRequest.with { $0.initialPrompt = "Go" }
        if case .startTask(let req) = msg.payload {
            #expect(req.initialPrompt == "Go")
        } else {
            Issue.record("Expected .startTask payload")
        }
    }

    @Test("ClientMessage wraps DetachSession")
    func clientMessageDetach() {
        var msg = Pecan_ClientMessage()
        msg.detachSession = Pecan_DetachSession.with { $0.sessionID = "abc-123" }
        if case .detachSession(let d) = msg.payload {
            #expect(d.sessionID == "abc-123")
        } else {
            Issue.record("Expected .detachSession payload")
        }
    }

    @Test("ClientMessage wraps ReattachRequest")
    func clientMessageReattach() {
        var msg = Pecan_ClientMessage()
        msg.reattach = Pecan_ReattachRequest.with { $0.sessionID = "xyz" }
        if case .reattach(let r) = msg.payload {
            #expect(r.sessionID == "xyz")
        } else {
            Issue.record("Expected .reattach payload")
        }
    }

    // MARK: - ServerMessage

    @Test("SessionStarted fields are set correctly")
    func sessionStarted() {
        let started = Pecan_SessionStarted.with {
            $0.sessionID = "sess-1"
            $0.agentName = "gort"
            $0.projectName = "proj"
            $0.teamName = "team"
        }
        #expect(started.sessionID == "sess-1")
        #expect(started.agentName == "gort")
    }

    @Test("SessionInfo fields")
    func sessionInfo() {
        let info = Pecan_SessionInfo.with {
            $0.sessionID = "s1"
            $0.agentName = "tron"
            $0.isBusy = true
            $0.startedAt = "2026-01-01T00:00:00Z"
        }
        #expect(info.isBusy)
        #expect(info.startedAt == "2026-01-01T00:00:00Z")
    }

    @Test("SessionList holds multiple sessions")
    func sessionList() {
        var list = Pecan_SessionList()
        list.sessions = [
            Pecan_SessionInfo.with { $0.sessionID = "a"; $0.agentName = "clu" },
            Pecan_SessionInfo.with { $0.sessionID = "b"; $0.agentName = "flynn" },
        ]
        #expect(list.sessions.count == 2)
        #expect(list.sessions[0].agentName == "clu")
    }

    @Test("AgentOutput fields")
    func agentOutput() {
        let out = Pecan_AgentOutput.with {
            $0.sessionID = "s1"
            $0.text = "Hello from agent"
        }
        #expect(out.text == "Hello from agent")
    }

    @Test("ToolApprovalRequest fields")
    func toolApprovalRequest() {
        let req = Pecan_ToolApprovalRequest.with {
            $0.sessionID = "s1"
            $0.toolCallID = "call_abc"
            $0.toolName = "bash"
            $0.argumentsJson = "{\"command\":\"ls\"}"
        }
        #expect(req.toolName == "bash")
        #expect(req.argumentsJson.contains("ls"))
    }

    // MARK: - AgentEvent

    @Test("AgentRegistration fields")
    func agentRegistration() {
        let reg = Pecan_AgentRegistration.with {
            $0.agentID = "agent-uuid"
            $0.sessionID = "session-uuid"
        }
        #expect(reg.agentID == "agent-uuid")
        #expect(reg.sessionID == "session-uuid")
    }

    @Test("LLMCompletionRequest fields")
    func llmCompletionRequest() {
        let req = Pecan_LLMCompletionRequest.with {
            $0.requestID = "req-1"
            $0.modelKey = "default"
            $0.paramsJson = "{\"temperature\":0.7}"
        }
        #expect(req.requestID == "req-1")
        #expect(req.modelKey == "default")
        #expect(req.paramsJson.contains("temperature"))
    }

    @Test("ToolExecutionRequest fields")
    func toolExecutionRequest() {
        let req = Pecan_ToolExecutionRequest.with {
            $0.requestID = "t-1"
            $0.toolName = "read_file"
            $0.argumentsJson = "{\"path\":\"/project/main.swift\"}"
        }
        #expect(req.toolName == "read_file")
        #expect(req.argumentsJson.contains("main.swift"))
    }

    // MARK: - HostCommand

    @Test("RegistrationResponse success flag")
    func registrationResponse() {
        let resp = Pecan_RegistrationResponse.with {
            $0.success = true
            $0.projectName = "pecan"
            $0.projectDirectory = "/Users/user/pecan"
        }
        #expect(resp.success)
        #expect(resp.projectDirectory == "/Users/user/pecan")
    }

    @Test("LLMCompletionResponse fields")
    func llmCompletionResponse() {
        let resp = Pecan_LLMCompletionResponse.with {
            $0.requestID = "req-1"
            $0.responseJson = "{\"choices\":[]}"
        }
        #expect(resp.requestID == "req-1")
        #expect(resp.errorMessage.isEmpty)
    }

    @Test("ShutdownCommand carries reason")
    func shutdownCommand() {
        let cmd = Pecan_ShutdownCommand.with { $0.reason = "server restart" }
        #expect(cmd.reason == "server restart")
    }

    // MARK: - HttpProxy

    @Test("HttpProxyRequest fields")
    func httpProxyRequest() {
        let req = Pecan_HttpProxyRequest.with {
            $0.requestID = "http-1"
            $0.method = "GET"
            $0.url = "https://example.com/api"
            $0.requiresApproval = false
        }
        #expect(req.method == "GET")
        #expect(req.url == "https://example.com/api")
        #expect(!req.requiresApproval)
    }

    @Test("HttpHeader name/value")
    func httpHeader() {
        let h = Pecan_HttpHeader.with { $0.name = "Content-Type"; $0.value = "application/json" }
        #expect(h.name == "Content-Type")
        #expect(h.value == "application/json")
    }

    // MARK: - Memory and Skills

    @Test("MemoryCommand fields")
    func memoryCommand() {
        let cmd = Pecan_MemoryCommand.with {
            $0.requestID = "m-1"
            $0.action = "read_tag"
            $0.scope = "project"
            $0.tag = "CORE"
        }
        #expect(cmd.action == "read_tag")
        #expect(cmd.scope == "project")
        #expect(cmd.tag == "CORE")
    }

    @Test("TaskCommand fields")
    func taskCommand() {
        let cmd = Pecan_TaskCommand.with {
            $0.requestID = "tc-1"
            $0.action = "create"
            $0.payloadJson = "{\"title\":\"Fix bug\"}"
            $0.scope = "agent"
        }
        #expect(cmd.action == "create")
        #expect(cmd.payloadJson.contains("Fix bug"))
    }
}
