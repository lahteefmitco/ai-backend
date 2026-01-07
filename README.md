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