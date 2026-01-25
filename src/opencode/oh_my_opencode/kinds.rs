//! Configuration kinds for oh-my-opencode plugin.
//!
//! This module defines enums used for configuring the oh-my-opencode agent system,
//! including agent types, skills, hooks, and commands. These are serialized
//! to/from JSON for configuration files.

use serde::{Deserialize, Serialize};

/// Agent types available in the oh-my-opencode system.
///
/// Different agent personalities with specialized behaviors and capabilities.
/// Agents define the core behavior and approach to task execution.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "kebab-case")]
pub enum AgentKind {
    Sisyphus,
    Prometheus,
    Oracle,
    Librarian,
    Explore,
    MultimodalLooker,
    Metis,
    Momus,
    Atlas,

    /// Custom agent type not in the predefined list
    #[serde(untagged)]
    Custom(String),
}

/// Skill types available for agent specialization.
///
/// Skills enhance agent capabilities in specific domains. Agents can be
/// configured with zero or more skills to augment their abilities.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "kebab-case")]
pub enum SkillKind {
    /// Browser automation and testing capabilities via Playwright
    Playwright,
    /// Frontend UI/UX design and implementation expertise
    FrontendUiUx,
    /// Git operations and version control mastery
    GitMaster,

    /// Custom skill type not in the predefined list
    #[serde(untagged)]
    Custom(String),
}

/// Hook types that can be triggered during agent execution.
///
/// Hooks provide extensibility points for injecting custom behavior
/// at specific points in the agent lifecycle. Hooks can modify responses,
/// monitor state, inject context, or handle errors.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "kebab-case")]
pub enum HookKind {
    /// Enforces TODO continuation in agent responses to track incomplete work
    TodoContinuationEnforcer,
    /// Monitors and manages context window usage to prevent overflow
    ContextWindowMonitor,
    /// Handles session state recovery after interruptions
    SessionRecovery,
    /// Sends session notifications to keep users informed
    SessionNotification,
    /// Validates comments in agent responses for correctness
    CommentChecker,
    /// Truncates grep command output to prevent excessive token usage
    GrepOutputTruncator,
    /// Truncates tool execution output to fit within limits
    ToolOutputTruncator,
    /// Injects directory-specific agent configurations
    DirectoryAgentsInjector,
    /// Injects directory README information into context
    DirectoryReadmeInjector,
    /// Detects empty task responses that need attention
    EmptyTaskResponseDetector,
    /// Enables thinking mode for agent reasoning visibility
    ThinkMode,
    /// Recovers from Anthropic context window limit errors
    AnthropicContextWindowLimitRecovery,
    /// Injects project rules into the agent's context
    RulesInjector,
    /// Handles background notifications for async events
    BackgroundNotification,
    /// Checks for oh-my-opencode updates automatically
    AutoUpdateChecker,
    /// Shows startup toast notifications to the user
    StartupToast,
    /// Detects specific keywords in responses for triggering actions
    KeywordDetector,
    /// Reminds users about agent usage patterns or limits
    AgentUsageReminder,
    /// Handles non-interactive environment execution
    NonInteractiveEnv,
    /// Manages interactive bash sessions for command execution
    InteractiveBashSession,
    /// Validates thinking block formatting for proper structure
    ThinkingBlockValidator,
    /// Ralph loop hook for specific execution patterns
    RalphLoop,
    /// Injects compaction context for memory optimization
    CompactionContextInjector,
    /// Claude Code specific hooks and integrations
    ClaudeCodeHooks,
    /// Automatic slash command handling and routing
    AutoSlashCommand,
    /// Recovers from edit errors with retry logic
    EditErrorRecovery,
    /// Retries delegated tasks on failure with backoff
    DelegateTaskRetry,
    /// Markdown-only mode restriction for Prometheus agent
    PrometheusMdOnly,
    /// Start work hook for initialization
    StartWork,
    /// Atlas agent specific hook
    Atlas,

    /// Custom hook type not in the predefined list
    #[serde(untagged)]
    Custom(String),
}

/// Command types available for direct execution.
///
/// Commands represent high-level actions that can be invoked
/// on the oh-my-opencode system to perform specific tasks.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "kebab-case")]
pub enum CommandKind {
    /// Initialize deep project analysis and understanding
    InitDeep,
    /// Start work command to begin task execution
    StartWork,

    /// Custom command type not in the predefined list
    #[serde(untagged)]
    Custom(String),
}

/// Agent execution modes determining how agents operate.
///
/// Controls which agents are active and how they interact during task execution.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum AgentMode {
    /// Agent operates as a subagent under a primary agent
    Subagent,
    /// Agent operates as the primary agent directing other agents
    Primary,
    /// All agents are active and can participate in task execution
    All,
}

/// Permission categories for agent actions.
///
/// Defines different types of operations that require permission checks
/// before execution. Each permission type controls access to specific
/// capabilities in the system.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "snake_case")]
pub enum PermissionKind {
    /// Permission to edit files and modify code
    Edit,
    /// Permission to execute bash commands and shell operations
    Bash,
    /// Permission to fetch content from web URLs
    Webfetch,
    /// Permission to detect and prevent infinite loops
    DoomLoop,
    /// Permission to access and modify files outside the project directory
    ExternalDirectory,
}

/// Permission policy controlling how permission requests are handled.
///
/// Determines the behavior when an agent attempts to perform an action
/// that requires permission. Policies can be configured globally or
/// per permission type.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PermissionPolicy {
    /// Always ask the user for permission before executing
    Ask,
    /// Automatically allow the operation without asking
    Allow,
    /// Automatically deny the operation without asking
    Deny,
}

/// Thinking mode configuration for agent reasoning visibility.
///
/// Controls whether and how agents expose their internal reasoning process.
/// This affects transparency into how agents arrive at decisions.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ThinkingMode {
    /// Thinking blocks are visible in agent responses
    Enabled,
    /// Thinking blocks are hidden from agent responses
    Disabled,
}

/// Reasoning effort levels for agent cognitive processing.
///
/// Determines how much computational effort the agent expends on reasoning.
/// Higher levels may produce more thorough analysis but consume more tokens.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ReasoningEffort {
    /// Minimal reasoning effort, faster responses
    Low,
    /// Balanced reasoning effort, standard analysis depth
    Medium,
    /// Maximum reasoning effort, most thorough analysis
    High,
}

/// Text verbosity levels for agent communication.
///
/// Controls how detailed and verbose the agent's responses are.
/// Higher verbosity provides more explanations and context.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum TextVerbosity {
    /// Minimal text, concise responses only
    Low,
    /// Balanced verbosity, standard communication
    Medium,
    /// Maximum verbosity, detailed explanations and context
    High,
}

/// Experimental features available for testing and development.
///
/// Experimental features are unstable or under development and may change
/// without notice. Enable with caution as they may affect stability.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "snake_case")]
pub enum Experiment {
    /// Aggressive context truncation to fit within limits
    AggressiveTruncation,
    /// Automatic session resume after interruptions
    AutoResume,
    /// Truncate all tool outputs, not just excessive ones
    TrucateAllToolOutputs,
    /// Dynamic context pruning to optimize context window usage
    DynamicContextPruning,
}

/// Background task configuration parameters.
///
/// Controls concurrency and timeout settings for background
/// asynchronous operations in the agent system.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "camelCase")]
pub enum BackgroundTaskKind {
    /// Maximum concurrency for default background tasks
    DefaultConcurrency,
    /// Maximum concurrency for provider-specific tasks
    ProviderConcurrency,
    /// Maximum concurrency for model-specific tasks
    ModelConcurrency,
    /// Timeout in milliseconds before considering a task stale
    StaleTimeoutMs,
}
