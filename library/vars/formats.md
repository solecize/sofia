+++
type = "vars"
namespace = "formats"
+++

# Vars: formats

Supported input formats and detection hints.

```toml
# Supported extensions for auto-detection
html_extensions = [".html", ".htm"]
markdown_extensions = [".md", ".markdown", ".mdown"]
document_extensions = [".docx", ".doc", ".rtf", ".odt"]
text_extensions = [".txt"]

# Default output format
output_format = "md"

# ChatGPT export patterns (for special handling)
chatgpt_indicators = ["ChatGPT", "openai", "conversation", "assistant"]
```
