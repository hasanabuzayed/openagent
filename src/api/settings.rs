//! API endpoints for global settings management.

use std::sync::Arc;

use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, put},
    Router,
};
use serde::{Deserialize, Serialize};

use crate::settings::Settings;
use crate::workspace;

use super::routes::AppState;

/// Create the settings API routes.
pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/", get(get_settings).put(update_settings))
        .route("/library-remote", put(update_library_remote))
}

/// Response for settings endpoints.
#[derive(Debug, Serialize)]
pub struct SettingsResponse {
    pub library_remote: Option<String>,
}

impl From<Settings> for SettingsResponse {
    fn from(settings: Settings) -> Self {
        Self {
            library_remote: settings.library_remote,
        }
    }
}

/// Request to update all settings.
#[derive(Debug, Deserialize)]
pub struct UpdateSettingsRequest {
    #[serde(default)]
    pub library_remote: Option<String>,
}

/// Request to update library remote specifically.
#[derive(Debug, Deserialize)]
pub struct UpdateLibraryRemoteRequest {
    /// Git remote URL. Set to null or empty string to clear.
    pub library_remote: Option<String>,
}

/// Response after updating library remote.
#[derive(Debug, Serialize)]
pub struct UpdateLibraryRemoteResponse {
    pub library_remote: Option<String>,
    /// Whether the library was reinitialized.
    pub library_reinitialized: bool,
    /// Error message if library initialization failed.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub library_error: Option<String>,
}

/// GET /api/settings
/// Get all settings.
async fn get_settings(State(state): State<Arc<AppState>>) -> Json<SettingsResponse> {
    let settings = state.settings.get().await;
    Json(settings.into())
}

/// PUT /api/settings
/// Update all settings.
async fn update_settings(
    State(state): State<Arc<AppState>>,
    Json(req): Json<UpdateSettingsRequest>,
) -> Result<Json<SettingsResponse>, (StatusCode, String)> {
    let new_settings = Settings {
        library_remote: req.library_remote,
    };

    state
        .settings
        .update(new_settings.clone())
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(new_settings.into()))
}

/// PUT /api/settings/library-remote
/// Update the library remote URL and optionally reinitialize the library.
async fn update_library_remote(
    State(state): State<Arc<AppState>>,
    Json(req): Json<UpdateLibraryRemoteRequest>,
) -> Result<Json<UpdateLibraryRemoteResponse>, (StatusCode, String)> {
    // Normalize empty string to None
    let new_remote = req.library_remote.filter(|s| !s.trim().is_empty());

    // Update the setting
    let previous = state
        .settings
        .set_library_remote(new_remote.clone())
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    // If the value actually changed, reinitialize the library
    let (library_reinitialized, library_error) = if previous.is_some() {
        if let Some(ref remote) = new_remote {
            // Reinitialize with new remote
            match reinitialize_library(&state, remote).await {
                Ok(()) => (true, None),
                Err(e) => (false, Some(e)),
            }
        } else {
            // Clear the library
            *state.library.write().await = None;
            tracing::info!("Library cleared (remote set to None)");
            (true, None)
        }
    } else {
        // No change in value
        (false, None)
    };

    Ok(Json(UpdateLibraryRemoteResponse {
        library_remote: new_remote,
        library_reinitialized,
        library_error,
    }))
}

/// Reinitialize the library with a new remote URL.
async fn reinitialize_library(state: &Arc<AppState>, remote: &str) -> Result<(), String> {
    let library_path = state.config.library_path.clone();

    match crate::library::LibraryStore::new(library_path, remote).await {
        Ok(store) => {
            // Sync OpenCode plugins
            if let Ok(plugins) = store.get_plugins().await {
                if let Err(e) = crate::opencode_config::sync_global_plugins(&plugins).await {
                    tracing::warn!("Failed to sync OpenCode plugins: {}", e);
                }
            }

            tracing::info!("Configuration library reinitialized from {}", remote);
            let library = Arc::new(store);
            *state.library.write().await = Some(Arc::clone(&library));

            // Sync skills/tools to all workspaces
            let workspaces = state.workspaces.list().await;
            for ws in workspaces {
                let is_default_host = ws.id == workspace::DEFAULT_WORKSPACE_ID
                    && ws.workspace_type == workspace::WorkspaceType::Host;

                if is_default_host || !ws.skills.is_empty() {
                    if let Err(e) = workspace::sync_workspace_skills(&ws, &library).await {
                        tracing::warn!(
                            workspace = %ws.name,
                            error = %e,
                            "Failed to sync skills after library reinit"
                        );
                    }
                }

                if is_default_host || !ws.tools.is_empty() {
                    if let Err(e) = workspace::sync_workspace_tools(&ws, &library).await {
                        tracing::warn!(
                            workspace = %ws.name,
                            error = %e,
                            "Failed to sync tools after library reinit"
                        );
                    }
                }
            }

            Ok(())
        }
        Err(e) => {
            tracing::error!("Failed to reinitialize library from {}: {}", remote, e);
            Err(e.to_string())
        }
    }
}
