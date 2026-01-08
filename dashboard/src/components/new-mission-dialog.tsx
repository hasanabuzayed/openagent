'use client';

import { useEffect, useRef, useState } from 'react';
import { Plus } from 'lucide-react';
import type { Workspace } from '@/lib/api';
import type { LibraryAgentSummary } from '@/contexts/library-context';

interface NewMissionDialogProps {
  workspaces: Workspace[];
  libraryAgents: LibraryAgentSummary[];
  disabled?: boolean;
  onCreate: (options?: { workspaceId?: string; agent?: string }) => Promise<void> | void;
}

export function NewMissionDialog({
  workspaces,
  libraryAgents,
  disabled = false,
  onCreate,
}: NewMissionDialogProps) {
  const [open, setOpen] = useState(false);
  const [newMissionWorkspace, setNewMissionWorkspace] = useState('');
  const [newMissionAgent, setNewMissionAgent] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const dialogRef = useRef<HTMLDivElement>(null);

  const formatWorkspaceType = (type: Workspace['workspace_type']) =>
    type === 'host' ? 'host' : 'isolated';

  useEffect(() => {
    if (!open) return;

    const handleClickOutside = (event: MouseEvent) => {
      if (dialogRef.current && !dialogRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [open]);

  const resetForm = () => {
    setNewMissionWorkspace('');
    setNewMissionAgent('');
  };

  const handleCancel = () => {
    setOpen(false);
    resetForm();
  };

  const handleCreate = async () => {
    if (disabled || submitting) return;
    setSubmitting(true);
    try {
      await onCreate({
        workspaceId: newMissionWorkspace || undefined,
        agent: newMissionAgent || undefined,
      });
      setOpen(false);
      resetForm();
    } finally {
      setSubmitting(false);
    }
  };

  const isBusy = disabled || submitting;

  return (
    <div className="relative" ref={dialogRef}>
      <button
        type="button"
        onClick={() => setOpen((prev) => !prev)}
        disabled={isBusy}
        className="flex items-center gap-2 rounded-lg bg-indigo-500/20 px-3 py-2 text-sm font-medium text-indigo-400 hover:bg-indigo-500/30 transition-colors disabled:opacity-50"
      >
        <Plus className="h-4 w-4" />
        <span className="hidden sm:inline">New</span> Mission
      </button>
      {open && (
        <div className="absolute right-0 top-full mt-1 w-96 rounded-lg border border-white/[0.06] bg-[#1a1a1a] p-4 shadow-xl z-10">
          <h3 className="text-sm font-medium text-white mb-3">Create New Mission</h3>
          <div className="space-y-3">
            {/* Workspace selection */}
            <div>
              <label className="block text-xs text-white/50 mb-1.5">Workspace</label>
              <select
                value={newMissionWorkspace}
                onChange={(e) => setNewMissionWorkspace(e.target.value)}
                className="w-full rounded-lg border border-white/[0.06] bg-white/[0.02] px-3 py-2.5 text-sm text-white focus:border-indigo-500/50 focus:outline-none appearance-none cursor-pointer"
                style={{
                  backgroundImage:
                    "url(\"data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e\")",
                  backgroundPosition: 'right 0.5rem center',
                  backgroundRepeat: 'no-repeat',
                  backgroundSize: '1.5em 1.5em',
                  paddingRight: '2.5rem',
                }}
              >
                <option value="" className="bg-[#1a1a1a]">
                  Host (default)
                </option>
                {workspaces
                  .filter(
                    (ws) =>
                      ws.status === 'ready' &&
                      ws.id !== '00000000-0000-0000-0000-000000000000'
                  )
                  .map((workspace) => (
                    <option
                      key={workspace.id}
                      value={workspace.id}
                      className="bg-[#1a1a1a]"
                    >
                      {workspace.name} ({formatWorkspaceType(workspace.workspace_type)})
                    </option>
                  ))}
              </select>
              <p className="text-xs text-white/30 mt-1.5">Where the mission will run</p>
            </div>

            {/* Agent selection */}
            <div>
              <label className="block text-xs text-white/50 mb-1.5">Agent Configuration</label>
              <select
                value={newMissionAgent}
                onChange={(e) => {
                  setNewMissionAgent(e.target.value);
                }}
                className="w-full rounded-lg border border-white/[0.06] bg-white/[0.02] px-3 py-2.5 text-sm text-white focus:border-indigo-500/50 focus:outline-none appearance-none cursor-pointer"
                style={{
                  backgroundImage:
                    "url(\"data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e\")",
                  backgroundPosition: 'right 0.5rem center',
                  backgroundRepeat: 'no-repeat',
                  backgroundSize: '1.5em 1.5em',
                  paddingRight: '2.5rem',
                }}
              >
                <option value="" className="bg-[#1a1a1a]">
                  Default (no agent)
                </option>
                {libraryAgents.map((agent) => (
                  <option key={agent.name} value={agent.name} className="bg-[#1a1a1a]">
                    {agent.name}
                  </option>
                ))}
              </select>
              <p className="text-xs text-white/30 mt-1.5">
                Pre-configured model, tools & instructions from library
              </p>
            </div>

            <div className="flex gap-2 pt-1">
              <button
                type="button"
                onClick={handleCancel}
                className="flex-1 rounded-lg border border-white/[0.06] bg-white/[0.02] px-3 py-2 text-sm text-white/70 hover:bg-white/[0.04] transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleCreate}
                disabled={isBusy}
                className="flex-1 rounded-lg bg-indigo-500 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-600 transition-colors disabled:opacity-50"
              >
                Create
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
