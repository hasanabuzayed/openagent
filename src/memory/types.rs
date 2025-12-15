//! Types for the memory subsystem.

use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Status of a run or task.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MemoryStatus {
    Pending,
    Running,
    Completed,
    Failed,
}

impl std::fmt::Display for MemoryStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Pending => write!(f, "pending"),
            Self::Running => write!(f, "running"),
            Self::Completed => write!(f, "completed"),
            Self::Failed => write!(f, "failed"),
        }
    }
}

/// A run stored in the database.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DbRun {
    pub id: Uuid,
    pub created_at: String,
    pub updated_at: String,
    pub status: String,
    pub input_text: String,
    pub final_output: Option<String>,
    pub total_cost_cents: Option<i32>,
    pub summary_text: Option<String>,
    pub archive_path: Option<String>,
}

/// A task stored in the database (hierarchical).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DbTask {
    pub id: Uuid,
    pub run_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub depth: i32,
    pub seq: i32,
    pub description: String,
    pub status: String,
    pub complexity_score: Option<f64>,
    pub model_used: Option<String>,
    pub budget_cents: Option<i32>,
    pub spent_cents: Option<i32>,
    pub output: Option<String>,
    pub created_at: String,
    pub completed_at: Option<String>,
}

/// An event stored in the database.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DbEvent {
    pub id: Option<i64>,
    pub run_id: Uuid,
    pub task_id: Option<Uuid>,
    pub seq: i32,
    pub ts: Option<String>,
    pub agent_type: String,
    pub event_kind: String,
    pub preview_text: Option<String>,
    pub meta: Option<serde_json::Value>,
    pub blob_path: Option<String>,
    pub prompt_tokens: Option<i32>,
    pub completion_tokens: Option<i32>,
    pub cost_cents: Option<i32>,
}

/// A chunk for vector search.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DbChunk {
    pub id: Option<Uuid>,
    pub run_id: Uuid,
    pub task_id: Option<Uuid>,
    pub source_event_id: Option<i64>,
    pub chunk_text: String,
    pub meta: Option<serde_json::Value>,
}

/// Event kinds for the event stream.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum EventKind {
    /// Task started
    TaskStart,
    /// Task completed
    TaskEnd,
    /// LLM request sent
    LlmRequest,
    /// LLM response received
    LlmResponse,
    /// Tool invoked
    ToolCall,
    /// Tool result received
    ToolResult,
    /// Complexity estimation
    ComplexityEstimate,
    /// Model selection decision
    ModelSelect,
    /// Verification result
    Verification,
    /// Task split into subtasks
    TaskSplit,
    /// Error occurred
    Error,
}

impl std::fmt::Display for EventKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            Self::TaskStart => "task_start",
            Self::TaskEnd => "task_end",
            Self::LlmRequest => "llm_request",
            Self::LlmResponse => "llm_response",
            Self::ToolCall => "tool_call",
            Self::ToolResult => "tool_result",
            Self::ComplexityEstimate => "complexity_estimate",
            Self::ModelSelect => "model_select",
            Self::Verification => "verification",
            Self::TaskSplit => "task_split",
            Self::Error => "error",
        };
        write!(f, "{}", s)
    }
}

/// Search result from vector similarity search.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    pub id: Uuid,
    pub run_id: Uuid,
    pub task_id: Option<Uuid>,
    pub chunk_text: String,
    pub meta: Option<serde_json::Value>,
    pub similarity: f64,
}

/// Context pack for injection into prompts.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextPack {
    /// Relevant chunks from memory
    pub chunks: Vec<SearchResult>,
    /// Total token estimate for the context
    pub estimated_tokens: usize,
    /// Query that was used
    pub query: String,
}

impl ContextPack {
    /// Format as a string for prompt injection.
    pub fn format_for_prompt(&self) -> String {
        if self.chunks.is_empty() {
            return String::new();
        }
        
        let mut out = String::from("## Relevant Context from Memory\n\n");
        for (i, chunk) in self.chunks.iter().enumerate() {
            out.push_str(&format!(
                "### Context {} (similarity: {:.2})\n{}\n\n",
                i + 1,
                chunk.similarity,
                chunk.chunk_text
            ));
        }
        out
    }
}

