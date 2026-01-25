//! Configuration types for the oh-my-opencode plugin.
//!
//! This module defines the core configuration structures used by the oh-my-opencode
//! system. The main configuration is typically stored in `oh-my-opencode.json` and
//! controls agent behavior, model settings, permissions, hooks, and various
//! experimental features. All types are serializable to/from JSON for easy
//! configuration management.

use super::dcp::DynamicContextPruning;
use super::kinds::*;
use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;
use std::collections::HashMap;

/// Root configuration structure for oh-my-opencode.
///
/// This is the top-level configuration entry point that controls the entire
/// oh-my-opencode system. It manages agent definitions, permissions, hooks,
/// experimental features, and integration with Claude Code.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OhMyOpencode {
    /// JSON schema reference for configuration validation
    #[serde(
        rename = "$schema",
        default = "default_schema",
        skip_serializing_if = "Option::is_none"
    )]
    pub schema: Option<String>,

    /// List of MCP (Model Context Protocol) servers to disable
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub disabled_mcps: Vec<String>,

    /// List of agent types that should be disabled
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub disabled_agents: Vec<AgentKind>,

    /// List of skills that should be disabled
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub disabled_skills: Vec<SkillKind>,

    /// List of hooks that should be disabled
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub disabled_hooks: Vec<HookKind>,

    /// List of commands that should be disabled
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub disabled_commands: Vec<CommandKind>,

    /// Map of agent types to their specific configurations
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub agents: HashMap<AgentKind, Agent>,

    /// Map of category names to their configurations
    /// Categories provide shared settings for groups of agents
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub categories: HashMap<String, Category>,

    /// Claude Code integration settings
    #[serde(skip_serializing_if = "Option::is_none")]
    pub claude_code: Option<ClaudeCode>,

    /// Sisyphus agent specific configuration for task planning
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sisyphus_agent: Option<SisyphusAgent>,

    /// Comment checker configuration for validating response comments
    #[serde(skip_serializing_if = "Option::is_none")]
    pub comment_checker: Option<CommentChecker>,

    /// Experimental features configuration
    #[serde(skip_serializing_if = "Option::is_none")]
    pub experimental: Option<Experimental>,

    /// Automatic update check toggle
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto_update: Option<bool>,

    /// Skills configuration for agent enhancement
    #[serde(skip_serializing_if = "Option::is_none")]
    pub skills: Option<Skills>,

    /// Ralph loop configuration for iterative task execution
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ralph_loop: Option<RalphLoop>,

    /// Background task configuration with concurrency settings
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    pub background_task: HashMap<BackgroundTaskKind, BackgroundTask>,

    /// Notification system configuration
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notification: Option<Notification>,

    /// Git master skill configuration for version control operations
    #[serde(skip_serializing_if = "Option::is_none")]
    pub git_master: Option<GitMaster>,
}

/// Agent configuration defining behavior and capabilities.
///
/// Each agent has a unique identifier and can be customized with specific
/// models, temperatures, prompts, skills, and permissions. Agents inherit
/// settings from their category but can override them individually.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    /// Unique identifier for this agent instance
    pub id: String,

    /// Model identifier (e.g., "claude-3-5-sonnet-20241022")
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,

    /// Model variant for provider-specific configurations
    #[serde(skip_serializing_if = "Option::is_none")]
    pub variant: Option<String>,

    /// Category name this agent belongs to for inheritance
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,

    /// List of skill names available to this agent
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub skills: Vec<String>,

    /// Temperature parameter for model randomness (0.0 to 1.0)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f32>,

    /// Top-p nucleus sampling parameter (0.0 to 1.0)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f32>,

    /// Custom system prompt for this agent
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt: Option<String>,

    /// Additional prompt text appended to the base prompt
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt_append: Option<String>,

    /// Tool availability map (tool name -> enabled flag)
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub tools: HashMap<String, bool>,

    /// Whether this agent is disabled
    #[serde(default)]
    pub disable: bool,

    /// Human-readable description of this agent's purpose
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    /// Agent execution mode (subagent, primary, or all)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mode: Option<AgentMode>,

    /// Color code for UI representation (e.g., "#FF5733")
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,

    /// Permission settings for different action types
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    #[serde(rename = "permission")]
    pub permissions: HashMap<PermissionKind, PermissionEntry>,
}

/// Permission entry supporting simple policies or tool-specific policies.
///
/// Can be either a global policy string ("allow", "ask", "deny") or a map
/// of tool names to their specific policies, allowing granular control over
/// which tools require permission.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum PermissionEntry {
    /// Simple global policy: "allow", "ask", or "deny"
    Policy(PermissionPolicy),
    /// Tool-specific policies mapping tool names to permission policies
    PolicyMap(HashMap<String, PermissionPolicy>),
}

/// Category configuration for grouping related agents.
///
/// Categories provide shared default settings that can be inherited by
/// multiple agents. This reduces configuration duplication and allows
/// consistent behavior across groups of similar agents.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Category {
    /// Description of this category's purpose and contents
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    /// Default model for agents in this category
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,

    /// Default model variant for agents in this category
    #[serde(skip_serializing_if = "Option::is_none")]
    pub variant: Option<String>,

    /// Default temperature for agents in this category
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f32>,

    /// Default top-p for agents in this category
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f32>,

    /// Maximum token limit for responses
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "maxTokens")]
    pub max_tokens: Option<u32>,

    /// Thinking mode configuration for reasoning visibility
    #[serde(skip_serializing_if = "Option::is_none")]
    pub thinking: Option<Thinking>,

    /// Reasoning effort level for cognitive processing
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "reasoningEffort")]
    pub reasoning_effort: Option<ReasoningEffort>,

    /// Text verbosity level for agent communication
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "textVerbosity")]
    pub text_verbosity: Option<TextVerbosity>,

    /// Default tool availability for agents in this category
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub tools: HashMap<String, bool>,

    /// Additional prompt text to append for category agents
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt_append: Option<String>,

    /// Marks agents in this category as experimental/unstable
    #[serde(skip_serializing_if = "Option::is_none")]
    pub is_unstable_agent: Option<bool>,
}

/// Thinking configuration for agent reasoning visibility.
///
/// Controls how and when agents expose their internal reasoning process
/// through thinking blocks, which can help understand agent decision-making.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Thinking {
    /// Whether thinking mode is enabled or disabled
    #[serde(rename = "type")]
    pub mode: ThinkingMode,

    /// Maximum token budget for thinking blocks
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "budgetTokens")]
    pub budget_tokens: Option<u32>,
}

/// Claude Code integration settings.
///
/// Controls which features of oh-my-opencode are enabled when used
/// with Claude Code, allowing fine-grained control over the integration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClaudeCode {
    /// Enable or disable MCP server integration
    #[serde(rename = "mcp", skip_serializing_if = "Option::is_none")]
    pub mcp_enabled: Option<bool>,

    /// Enable or disable custom commands
    #[serde(rename = "commands", skip_serializing_if = "Option::is_none")]
    pub commands_enabled: Option<bool>,

    /// Enable or disable skills system
    #[serde(rename = "skills", skip_serializing_if = "Option::is_none")]
    pub skills_enabled: Option<bool>,

    /// Enable or disable agent system
    #[serde(rename = "agents", skip_serializing_if = "Option::is_none")]
    pub agents_enabled: Option<bool>,

    /// Enable or disable hooks system
    #[serde(rename = "hooks", skip_serializing_if = "Option::is_none")]
    pub hooks_enabled: Option<bool>,

    /// Enable or disable plugin system
    #[serde(rename = "plugins", skip_serializing_if = "Option::is_none")]
    pub plugins_enabled: Option<bool>,

    /// Override enable/disable state for specific plugins
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub plugins_override: HashMap<String, bool>,
}

/// Sisyphus agent configuration for task planning and execution.
///
/// Sisyphus is responsible for breaking down complex tasks into smaller
/// subtasks and managing their execution. This configuration controls
/// its planning and execution behavior.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SisyphusAgent {
    /// Whether the Sisyphus agent is disabled
    #[serde(default)]
    pub disabled: bool,

    /// Enable default task builder functionality
    #[serde(skip_serializing_if = "Option::is_none")]
    pub default_builder_enabled: Option<bool>,

    /// Enable task planning capabilities
    #[serde(skip_serializing_if = "Option::is_none")]
    pub planner_enabled: Option<bool>,

    /// Allow replacing existing plans with new ones
    #[serde(skip_serializing_if = "Option::is_none")]
    pub replace_plan: Option<bool>,
}

/// Comment checker configuration.
///
/// Validates that comments in agent responses are properly formatted
/// and contain meaningful information. Can use a custom prompt for validation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommentChecker {
    /// Custom validation prompt for comment checking
    #[serde(skip_serializing_if = "Option::is_none")]
    pub custom_prompt: Option<String>,
}

/// Experimental features configuration.
///
/// Experimental features are under development and may change without notice.
/// This structure enables and configures these experimental capabilities.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Experimental {
    /// Dynamic context pruning configuration for context optimization
    #[serde(skip_serializing_if = "Option::is_none")]
    pub dynamic_context_pruning: Option<DynamicContextPruning>,

    /// Other experimental features with enable/disable flags
    #[serde(flatten)]
    pub others: HashMap<Experiment, bool>,
}

/// Skills configuration supporting simple lists or detailed configs.
///
/// Skills can be specified as a simple list of skill names for quick setup,
/// or as a detailed configuration with sources, definitions, and metadata
/// for more advanced customization.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum Skills {
    /// Simple skill list: ["python", "react"]
    Simple(Vec<String>),
    /// Detailed skill configuration with definitions and sources
    Config(SkillsConfig),
}

/// Detailed skills configuration.
///
/// Provides comprehensive skill management including definitions,
/// sources, and enable/disable lists for fine-grained control.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillsConfig {
    /// Map of skill names to their definitions or enable flags
    #[serde(flatten)]
    pub definition: HashMap<String, SkillEntry>,

    /// External source locations for loading skill definitions
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sources: Option<SourcesEntry>,

    /// Explicitly enabled skills
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub enable: Vec<String>,

    /// Explicitly disabled skills
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub disable: Vec<String>,
}

/// Skill entry supporting simple flags or detailed definitions.
///
/// Skills can be enabled with a simple boolean flag or configured with
/// detailed specifications including descriptions, templates, and metadata.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum SkillEntry {
    /// Simple boolean flag: true to enable, false to disable
    Flag(bool),
    /// Detailed skill configuration with full specification
    Detailed(SkillDefinition),
}

/// Detailed skill definition.
///
/// Complete specification of a skill including its behavior, template,
/// source, model requirements, and other metadata for proper integration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillDefinition {
    /// Human-readable description of the skill's purpose
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    /// Template string for generating the skill prompt
    #[serde(skip_serializing_if = "Option::is_none")]
    pub template: Option<String>,

    /// External source location for the skill definition
    #[serde(rename = "from", skip_serializing_if = "Option::is_none")]
    pub from_source: Option<String>,

    /// Model requirement for this skill
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,

    /// Preferred agent for this skill
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent: Option<String>,

    /// Whether this skill operates as a subtask
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subtask: Option<bool>,

    /// Hint for argument format and expectations
    #[serde(rename = "argument-hint", skip_serializing_if = "Option::is_none")]
    pub argument_hint: Option<String>,

    /// License information for the skill
    #[serde(skip_serializing_if = "Option::is_none")]
    pub license: Option<String>,

    /// Compatibility information
    #[serde(skip_serializing_if = "Option::is_none")]
    pub compatibility: Option<String>,

    /// Additional metadata as key-value pairs
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub metadata: HashMap<String, JsonValue>,

    /// List of tools this skill is allowed to use
    #[serde(
        default,
        rename = "allowed-tools",
        skip_serializing_if = "Vec::is_empty"
    )]
    pub allowed_tools: Vec<String>,

    /// Whether this skill is disabled
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disable: Option<bool>,
}

/// External source configuration for loading skill definitions.
///
/// Specifies where to find skill definitions in the filesystem,
/// supporting directory traversal with optional glob patterns.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SourcesEntry {
    /// Base path for skill definition files
    #[serde(default)]
    pub path: String,

    /// Recursive directory traversal setting
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recursive: Option<String>,

    /// Glob pattern for matching skill files
    #[serde(skip_serializing_if = "Option::is_none")]
    pub glob: Option<String>,
}

/// Ralph loop configuration for iterative task execution.
///
/// The Ralph loop enables agents to iteratively refine their work
/// until a satisfactory result is achieved or maximum iterations are reached.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RalphLoop {
    /// Enable or disable the Ralph loop mechanism
    #[serde(default)]
    pub enabled: bool,

    /// Default maximum number of iterations per task
    #[serde(default = "default_max_iterations_100")]
    pub default_max_iterations: u32,

    /// Directory for storing loop state and checkpoints
    #[serde(skip_serializing_if = "Option::is_none")]
    pub state_dir: Option<String>,
}

/// Background task configuration supporting global or per-type settings.
///
/// Can specify a single concurrency value for all tasks or different
/// values for specific task types (provider, model, or default).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde[untagged]]
pub enum BackgroundTask {
    /// Single concurrency value for all task types
    Number(u32),
    /// Task-specific concurrency settings
    MappedNumber(HashMap<String, u32>),
}

/// Notification system configuration.
///
/// Controls how and when notifications are displayed to the user
/// about system events and agent activities.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Notification {
    /// Force enable notifications even if disabled elsewhere
    #[serde(skip_serializing_if = "Option::is_none")]
    pub force_enable: Option<bool>,
}

/// Git master skill configuration for version control operations.
///
/// Configures the behavior of git-related operations including
/// commit message formatting and co-author attribution.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitMaster {
    /// Include a commit footer in commit messages
    #[serde(default = "default_true")]
    pub commit_footer: bool,

    /// Include Co-authored-by trailers for collaborative work
    #[serde(default = "default_true")]
    pub include_co_authored_by: bool,
}

fn default_true() -> bool {
    true
}

fn default_schema() -> Option<String> {
    Some(String::from("https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/refs/heads/dev/assets/oh-my-opencode.schema.json"))
}

fn default_max_iterations_100() -> u32 {
    100
}
