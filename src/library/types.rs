//! Types for the configuration library.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// MCP server definition from mcp/servers.json.
/// Matches the existing format in the skills repo.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "lowercase")]
pub enum McpServer {
    Stdio {
        command: String,
        #[serde(default)]
        args: Vec<String>,
        #[serde(default)]
        env: HashMap<String, String>,
    },
    Http {
        url: String,
    },
}

/// Skill summary for listing (without full content).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillSummary {
    /// Skill name (folder name, e.g., "frontend-development")
    pub name: String,
    /// Description from SKILL.md frontmatter
    pub description: Option<String>,
    /// Path relative to library root (e.g., "skills/frontend-development")
    pub path: String,
}

/// Full skill with content.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Skill {
    /// Skill name (folder name)
    pub name: String,
    /// Description from SKILL.md frontmatter
    pub description: Option<String>,
    /// Path relative to library root
    pub path: String,
    /// Full SKILL.md content
    pub content: String,
    /// List of reference files in references/ folder
    pub references: Vec<String>,
}

/// Command summary for listing.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommandSummary {
    /// Command name (filename without .md, e.g., "review-pr")
    pub name: String,
    /// Description from frontmatter
    pub description: Option<String>,
    /// Path relative to library root (e.g., "commands/review-pr.md")
    pub path: String,
}

/// Full command with content.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Command {
    /// Command name
    pub name: String,
    /// Description from frontmatter
    pub description: Option<String>,
    /// Path relative to library root
    pub path: String,
    /// Full markdown content
    pub content: String,
}

/// Git status for the library repository.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryStatus {
    /// Absolute path to the library
    pub path: String,
    /// Git remote URL if configured
    pub remote: Option<String>,
    /// Current branch name
    pub branch: String,
    /// True if working directory is clean
    pub clean: bool,
    /// Number of commits ahead of remote
    pub ahead: u32,
    /// Number of commits behind remote
    pub behind: u32,
    /// List of modified/untracked files
    pub modified_files: Vec<String>,
}

/// Parse YAML frontmatter from markdown content.
/// Returns (frontmatter, body) where frontmatter is the parsed YAML.
pub fn parse_frontmatter(content: &str) -> (Option<serde_yaml::Value>, &str) {
    if !content.starts_with("---") {
        return (None, content);
    }

    let rest = &content[3..];
    if let Some(end_pos) = rest.find("\n---") {
        let yaml_str = &rest[..end_pos];
        let body = &rest[end_pos + 4..].trim_start();

        match serde_yaml::from_str(yaml_str) {
            Ok(value) => (Some(value), body),
            Err(_) => (None, content),
        }
    } else {
        (None, content)
    }
}

/// Extract description from YAML frontmatter.
pub fn extract_description(frontmatter: &Option<serde_yaml::Value>) -> Option<String> {
    frontmatter.as_ref().and_then(|fm| {
        fm.get("description")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string())
    })
}

/// Extract name from YAML frontmatter (optional, usually from filename).
pub fn extract_name(frontmatter: &Option<serde_yaml::Value>) -> Option<String> {
    frontmatter.as_ref().and_then(|fm| {
        fm.get("name")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string())
    })
}
