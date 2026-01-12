import 'dart:convert';
import 'package:ai_backend/mcp/mcp_server.dart';
import 'package:dart_frog/dart_frog.dart';

/// HTTP endpoint to get MCP server information and capabilities
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed. Use GET.'},
    );
  }

  try {
    final server = McpServerImpl();

    // Get server info, resources, and tools
    final info = server.getServerInfo();
    final resources = await server.getResourcesList();
    final tools = server.getToolsList();

    return Response.json(
      body: {
        'server': info,
        'resources': resources,
        'tools': tools,
        'documentation': {
          'connect_claude_desktop':
              'Add this server to your Claude Desktop configuration file',
          'standalone_usage': 'Run: dart run bin/mcp_server.dart',
          'example_config': {
            'mcpServers': {
              'ai-backend': {
                'command': 'dart',
                'args': ['run', 'bin/mcp_server.dart'],
                'cwd': '/path/to/ai-backend',
              },
            },
          },
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'error': 'Failed to get server info',
        'message': e.toString(),
      },
    );
  }
}
