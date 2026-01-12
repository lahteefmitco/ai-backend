import 'package:ai_backend/mcp/resources/database_resources.dart';
import 'package:ai_backend/mcp/tools/database_tools.dart';
import 'package:ai_backend/mcp/tools/rag_tools.dart';
import 'package:ai_backend/util/log_functions.dart';
import 'package:mcp_dart/mcp_dart.dart';

/// Main MCP server implementation for the AI backend
class McpServerImpl {
  final DatabaseResources _dbResources = DatabaseResources();
  final RagTools _ragTools = RagTools();
  final DatabaseTools _dbTools = DatabaseTools();
  late McpServer _server;

  /// Initialize and start the MCP server
  Future<void> start() async {
    infoLog('Initializing MCP Server...');

    // Create server
    _server = McpServer(
      const Implementation(name: 'ai-backend-server', version: '1.0.0'),
      options: const McpServerOptions(
        capabilities: ServerCapabilities(
          resources: ServerCapabilitiesResources(),
          tools: ServerCapabilitiesTools(),
        ),
      ),
    );

    // Register all resources
    final resources = await _dbResources.getResources();
    for (final resource in resources) {
      _server.registerResource(
        resource.name,
        resource.uri,
        (description: resource.description, mimeType: resource.mimeType),
        (uri, _) async {
          infoLog('MCP: Reading resource: $uri');
          try {
            final contents = await _dbResources.readResource(uri.toString());
            return ReadResourceResult(contents: [contents]);
          } catch (e) {
            errorLog('MCP: Failed to read resource $uri: $e');
            rethrow;
          }
        },
      );
    }

    // Register all RAG tools
    final ragTools = _ragTools.getTools();
    for (final tool in ragTools) {
      _server.registerTool(
        tool.name,
        description: tool.description,
        inputSchema: ToolInputSchema.fromJson(tool.inputSchema.toJson()),
        callback: (args, _) => _ragTools.executeTool(tool.name, args),
      );
    }

    // Register all database tools
    final dbTools = _dbTools.getTools();
    for (final tool in dbTools) {
      _server.registerTool(
        tool.name,
        description: tool.description,
        inputSchema: ToolInputSchema.fromJson(tool.inputSchema.toJson()),
        callback: (args, _) => _dbTools.executeTool(tool.name, args),
      );
    }

    // Connect using stdio transport
    await _server.connect(StdioServerTransport());

    infoLog('MCP Server started and connected via stdio');
  }

  /// Get server info for HTTP endpoint
  Map<String, dynamic> getServerInfo() {
    return {
      'name': 'AI Backend MCP Server',
      'version': '1.0.0',
      'description':
          'MCP server providing access to student database and RAG system',
      'protocol_version': '2025-11-25',
      'capabilities': {
        'resources': true,
        'tools': true,
        'prompts': false,
      },
      'transport': 'stdio',
      'usage': {
        'standalone': 'dart run bin/mcp_server.dart',
        'claude_desktop': 'Add to Claude Desktop configuration',
      },
    };
  }

  /// Get list of available resources (for HTTP endpoint)
  Future<Map<String, dynamic>> getResourcesList() async {
    final resources = await _dbResources.getResources();
    return {
      'resources': resources
          .map((r) => {
                'uri': r.uri,
                'name': r.name,
                'description': r.description,
                'mimeType': r.mimeType,
              })
          .toList(),
      'count': resources.length,
    };
  }

  /// Get list of available tools (for HTTP endpoint)
  Map<String, dynamic> getToolsList() {
    final ragTools = _ragTools.getTools();
    final dbTools = _dbTools.getTools();
    final allTools = [...ragTools, ...dbTools];

    return {
      'tools': allTools
          .map((t) => {
                'name': t.name,
                'description': t.description,
                'inputSchema': t.inputSchema.toJson(),
              })
          .toList(),
      'count': allTools.length,
    };
  }
}
