import 'package:ai_backend/util/log_functions.dart';
import 'package:mcp_dart/mcp_dart.dart';

/// MCP Client Service for connecting to external MCP servers
/// This allows the backend to act as an MCP client and connect to other MCP servers
class McpClientService {
  McpClient? _client;
  bool _isConnected = false;

  /// Connect to an external MCP server
  Future<void> connect({
    required String command,
    required List<String> args,
    String? workingDirectory,
  }) async {
    if (_isConnected) {
      warningLog('MCP Client already connected');
      return;
    }

    try {
      infoLog('MCP Client: Connecting to server: $command ${args.join(" ")}');

      // Create client
      _client = McpClient(
        const Implementation(
          name: 'ai-backend-client',
          version: '1.0.0',
        ),
      );

      // Connect to the server via stdio
      await _client!.connect(StdioClientTransport(
        StdioServerParameters(
          command: command,
          args: args,
          workingDirectory: workingDirectory,
        ),
      ));

      _isConnected = true;
      infoLog('MCP Client: Connected successfully');
    } catch (e) {
      errorLog('MCP Client: Failed to connect: $e');
      rethrow;
    }
  }

  /// List available resources from the connected MCP server
  Future<List<Resource>> listResources() async {
    if (!_isConnected || _client == null) {
      throw Exception('MCP Client not connected');
    }

    try {
      final result = await _client!.listResources();
      return result.resources;
    } catch (e) {
      errorLog('MCP Client: Failed to list resources: $e');
      rethrow;
    }
  }

  /// Read a resource from the connected MCP server
  Future<ResourceContents> readResource(String uri) async {
    if (!_isConnected || _client == null) {
      throw Exception('MCP Client not connected');
    }

    try {
      final result = await _client!.readResource(
        ReadResourceRequest(uri: uri),
      );
      // Return first content item or throw if empty
      if (result.contents.isEmpty) {
        throw Exception('No contents returned for resource: $uri');
      }
      return result.contents.first;
    } catch (e) {
      errorLog('MCP Client: Failed to read resource $uri: $e');
      rethrow;
    }
  }

  /// List available tools from the connected MCP server
  Future<List<Tool>> listTools() async {
    if (!_isConnected || _client == null) {
      throw Exception('MCP Client not connected');
    }

    try {
      final result = await _client!.listTools();
      return result.tools;
    } catch (e) {
      errorLog('MCP Client: Failed to list tools: $e');
      rethrow;
    }
  }

  /// Call a tool on the connected MCP server
  Future<CallToolResult> callTool(
      String name, Map<String, dynamic> arguments) async {
    if (!_isConnected || _client == null) {
      throw Exception('MCP Client not connected');
    }

    try {
      final result = await _client!.callTool(
        CallToolRequest(
          name: name,
          arguments: arguments,
        ),
      );
      return result;
    } catch (e) {
      errorLog('MCP Client: Failed to call tool $name: $e');
      rethrow;
    }
  }

  /// Disconnect from the MCP server
  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    try {
      await _client?.close();
      _isConnected = false;
      _client = null;
      infoLog('MCP Client: Disconnected');
    } catch (e) {
      errorLog('MCP Client: Error during disconnect: $e');
    }
  }

  /// Check if client is connected
  bool get isConnected => _isConnected;
}
