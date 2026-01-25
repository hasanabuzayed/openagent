use serde::{Deserialize, Serialize};

/// Configuration for Dynamic Context Pruning (DCP)
///
/// DCP is a mechanism to dynamically manage and optimize the context window
/// by removing redundant or unnecessary information during conversations.
/// This helps maintain relevant context while staying within token limits.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DynamicContextPruning {
    /// Master switch to enable or disable DCP functionality
    #[serde(default)]
    pub enabled: bool,

    /// Controls the verbosity of pruning notifications to the user
    /// Default: NotificationLevel::Detailed
    #[serde(default = "default_notification")]
    pub notification: NotificationLevel,

    /// Optional turn-based protection to prevent pruning of recent context
    /// When enabled, protects the most recent N turns from being pruned
    #[serde(skip_serializing_if = "Option::is_none")]
    pub turn_protection: Option<TurnProtection>,

    /// List of tool names that should be protected from pruning
    /// Tools in this list will always have their context preserved
    /// Default: task, todowrite, todoread, lsp_rename, session_read, session_write, session_search
    #[serde(default = "default_protected_tools")]
    pub protected_tools: Vec<String>,

    /// Collection of pruning strategies that can be applied
    /// Each strategy addresses different types of context optimization
    #[serde(skip_serializing_if = "Option::is_none")]
    pub strategies: Option<Strategies>,
}

/// Verbosity levels for DCP notification messages
///
/// Determines how much information is shown to the user about
/// what content is being pruned from the context.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum NotificationLevel {
    /// No notifications about pruning activities
    Off,
    /// Minimal notifications - only summary information
    Minimal,
    /// Detailed notifications - includes specific items being pruned
    Detailed,
}

/// Turn-based protection configuration
///
/// Protects recent conversation turns from being pruned to maintain
/// continuity and context for the most recent interactions.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TurnProtection {
    /// Enable or disable turn protection mechanism
    /// Default: true
    #[serde(default = "default_true")]
    pub enabled: bool,
    /// Number of recent turns to protect from pruning
    /// Default: 3 turns
    #[serde(default = "default_turns_3")]
    pub turns: u8,
}

/// Collection of context pruning strategies
///
/// Each strategy targets different types of context optimization
/// to effectively reduce the context window size while maintaining
/// the most relevant information.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Strategies {
    /// Strategy to remove duplicate context entries
    /// Eliminates redundant information that appears multiple times
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deduplication: Option<Deduplication>,

    /// Strategy to replace multiple similar writes with a single consolidated write
    /// Useful when the AI rewrites the same content multiple times
    #[serde(skip_serializing_if = "Option::is_none")]
    pub supersede_writes: Option<SupersedeWrites>,

    /// Strategy to purge context entries related to errors
    /// Removes failed operations and error messages after a certain number of turns
    #[serde(skip_serializing_if = "Option::is_none")]
    pub purge_errors: Option<PurgeErrors>,
}

/// Deduplication strategy configuration
///
/// Removes duplicate entries from the context to reduce token usage
/// when the same information is present multiple times.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Deduplication {
    /// Enable or disable deduplication strategy
    /// Default: true
    #[serde(default = "default_true")]
    pub enabled: bool,
}

/// Supersede writes strategy configuration
///
/// Replaces multiple consecutive or similar write operations
/// with a single, consolidated entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SupersedeWrites {
    /// Enable or disable supersede writes strategy
    /// Default: true
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Aggressive mode allows more aggressive consolidation of writes
    /// May remove more context but also saves more tokens
    /// Default: false
    #[serde(default)]
    pub aggressive: bool,
}

/// Purge errors strategy configuration
///
/// Removes context related to failed operations and errors
/// after they are no longer relevant.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PurgeErrors {
    /// Enable or disable purge errors strategy
    /// Default: true
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Number of turns to retain error context before purging
    /// Errors older than this threshold will be removed
    /// Default: 5 turns
    #[serde(default = "default_turns_5")]
    pub turns: u8,
}

fn default_true() -> bool {
    true
}

fn default_turns_3() -> u8 {
    3
}

fn default_turns_5() -> u8 {
    5
}

fn default_notification() -> NotificationLevel {
    NotificationLevel::Detailed
}

fn default_protected_tools() -> Vec<String> {
    vec![
        "task".into(),
        "todowrite".into(),
        "todoread".into(),
        "lsp_rename".into(),
        "session_read".into(),
        "session_write".into(),
        "session_search".into(),
    ]
}
