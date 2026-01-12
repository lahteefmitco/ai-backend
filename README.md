# ai_backend

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

An example application built with dart_frog

[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT

## Configuration

The application requires an `env/.env` file to be configured. The following variables are supported:

### AI Provider Setup

You can switch between different AI providers by setting the `AI_PROVIDER` variable.

- **Values**: `OLLAMA` (default), `MISTRAL`, `GEMINI`

```env
AI_PROVIDER=GEMINI
```

### API Keys
Depending on the selected provider, you must provide the corresponding API key:

- **Gemini**: `GEMINI_API_KEY=your_gemini_api_key`
- **Mistral**: `MISTRAL_API_KEY=your_mistral_api_key`
- **Ollama**: No API key required (defaults to localhost).

### Database Configuration
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=password
```

## Model Context Protocol (MCP) Integration

This backend includes a full Model Context Protocol (MCP) server implementation, allowing AI assistants to access the database and RAG system through a standardized protocol.

### Starting the MCP Server

**Standalone Mode** (for Claude Desktop or other MCP clients):
```bash
dart run bin/mcp_server.dart
```

**HTTP API** (to view server capabilities):
```bash
dart_frog dev
curl http://localhost:8080/mcp
```

### Connecting from Claude Desktop

Add the following to your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`  
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "ai-backend": {
      "command": "dart",
      "args": ["run", "bin/mcp_server.dart"],
      "cwd": "/path/to/ai-backend"
    }
  }
}
```

### Available MCP Resources

The MCP server exposes the following database resources:

- `database://students` - List of all students
- `database://subjects` - List of all subjects  
- `database://marks` - Student marks with context
- `database://embeddings` - Vector embeddings (limited to 100)
- `database://divisions` - List of divisions

### Available MCP Tools

**RAG Tools:**
- `ask_question` - Ask questions using the RAG system
- `semantic_search` - Perform vector similarity search
- `query_students` - Query students with filters

**Database Tools:**
- `get_student_info` - Get detailed student information
- `get_student_marks` - Get all marks for a student
- `search_students` - Search students by name or division

### Example Usage

Once connected to Claude Desktop, you can ask:
- "Show me all students in the database"
- "What is the average marks of students?"
- "Search for students named John"
- "Get detailed information for student ID 5"