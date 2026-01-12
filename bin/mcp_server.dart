import 'package:ai_backend/mcp/mcp_server.dart';
import 'package:ai_backend/util/log_functions.dart';

/// Standalone MCP server executable
/// Run with: dart run bin/mcp_server.dart
Future<void> main() async {
  infoLog('Starting AI Backend MCP Server...');
  infoLog('Protocol: Model Context Protocol (MCP)');
  infoLog('Transport: stdio');
  infoLog('Press Ctrl+C to stop');

  try {
    final server = McpServerImpl();
    await server.start();
  } catch (e, stackTrace) {
    errorLog('Failed to start MCP server: $e');
    errorLog('Stack trace: $stackTrace');
    rethrow;
  }
}
