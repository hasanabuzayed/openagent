'use client';

import { Suspense, useEffect, useState } from 'react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import {
  listLibraryCommands,
  getLibraryCommand,
  saveLibraryCommand,
  deleteLibraryCommand,
  type CommandSummary,
  type Command,
} from '@/lib/api';
import {
  ArrowLeft,
  Save,
  AlertCircle,
  Loader,
  Terminal,
  Plus,
  Trash2,
  ChevronRight,
} from 'lucide-react';
import { cn } from '@/lib/utils';

function CommandsPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const selectedName = searchParams.get('name');

  const [commands, setCommands] = useState<CommandSummary[]>([]);
  const [selectedCommand, setSelectedCommand] = useState<Command | null>(null);
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(true);
  const [loadingCommand, setLoadingCommand] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isDirty, setIsDirty] = useState(false);
  const [showNewDialog, setShowNewDialog] = useState(false);
  const [newCommandName, setNewCommandName] = useState('');

  const loadCommands = async () => {
    try {
      setLoading(true);
      const data = await listLibraryCommands();
      setCommands(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load commands');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCommands();
  }, []);

  useEffect(() => {
    if (selectedName) {
      loadCommand(selectedName);
    } else {
      setSelectedCommand(null);
      setContent('');
    }
  }, [selectedName]);

  const loadCommand = async (name: string) => {
    try {
      setLoadingCommand(true);
      setError(null);
      const command = await getLibraryCommand(name);
      setSelectedCommand(command);
      setContent(command.content);
      setIsDirty(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load command');
    } finally {
      setLoadingCommand(false);
    }
  };

  const handleSave = async () => {
    if (!selectedCommand) return;

    try {
      setSaving(true);
      await saveLibraryCommand(selectedCommand.name, content);
      setIsDirty(false);
      await loadCommands();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save command');
    } finally {
      setSaving(false);
    }
  };

  const handleCreate = async () => {
    if (!newCommandName.trim()) return;

    const template = `---
description: A new command
---

Describe what this command does.
`;

    try {
      setSaving(true);
      await saveLibraryCommand(newCommandName, template);
      await loadCommands();
      setShowNewDialog(false);
      setNewCommandName('');
      router.push(`/library/commands?name=${encodeURIComponent(newCommandName)}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create command');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedCommand) return;
    if (!confirm(`Delete command "${selectedCommand.name}"?`)) return;

    try {
      await deleteLibraryCommand(selectedCommand.name);
      await loadCommands();
      router.push('/library/commands');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete command');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader className="h-8 w-8 animate-spin text-white/40" />
      </div>
    );
  }

  return (
    <div className="h-full flex">
      {/* Commands List */}
      <div className="w-64 flex-shrink-0 border-r border-white/[0.06] flex flex-col">
        <div className="p-4 border-b border-white/[0.06]">
          <div className="flex items-center justify-between mb-4">
            <Link
              href="/library"
              className="p-2 -ml-2 rounded-lg hover:bg-white/[0.04] transition-colors"
            >
              <ArrowLeft className="h-4 w-4 text-white/60" />
            </Link>
            <button
              onClick={() => setShowNewDialog(true)}
              className="p-2 rounded-lg hover:bg-white/[0.04] transition-colors"
            >
              <Plus className="h-4 w-4 text-white/60" />
            </button>
          </div>
          <div className="flex items-center gap-2">
            <Terminal className="h-4 w-4 text-amber-400" />
            <span className="text-sm font-medium text-white">Commands</span>
          </div>
        </div>
        <div className="flex-1 overflow-y-auto p-2">
          {commands.length === 0 ? (
            <p className="text-sm text-white/40 text-center py-4">No commands yet</p>
          ) : (
            commands.map((command) => (
              <Link
                key={command.name}
                href={`/library/commands?name=${encodeURIComponent(command.name)}`}
                className={cn(
                  'flex items-center justify-between p-3 rounded-lg transition-colors',
                  selectedName === command.name
                    ? 'bg-white/[0.08] text-white'
                    : 'text-white/60 hover:bg-white/[0.04] hover:text-white'
                )}
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium truncate">/{command.name}</p>
                  {command.description && (
                    <p className="text-xs text-white/40 truncate">{command.description}</p>
                  )}
                </div>
                <ChevronRight className="h-4 w-4 flex-shrink-0 opacity-40" />
              </Link>
            ))
          )}
        </div>
      </div>

      {/* Editor */}
      <div className="flex-1 flex flex-col">
        {selectedCommand ? (
          <>
            <div className="flex items-center justify-between p-4 border-b border-white/[0.06]">
              <div>
                <h2 className="text-lg font-medium text-white">/{selectedCommand.name}</h2>
                <p className="text-xs text-white/40">{selectedCommand.path}</p>
              </div>
              <div className="flex items-center gap-2">
                {isDirty && (
                  <span className="text-xs text-amber-400">Unsaved changes</span>
                )}
                <button
                  onClick={handleDelete}
                  className="p-2 rounded-lg text-red-400 hover:bg-red-500/10 transition-colors"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
                <button
                  onClick={handleSave}
                  disabled={saving || !isDirty}
                  className={cn(
                    'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg transition-colors',
                    isDirty
                      ? 'text-white bg-indigo-500 hover:bg-indigo-600'
                      : 'text-white/40 bg-white/[0.04]'
                  )}
                >
                  <Save className={cn('h-4 w-4', saving && 'animate-pulse')} />
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </div>
            </div>

            {error && (
              <div className="mx-4 mt-4 p-3 rounded-lg bg-red-500/10 text-red-400 flex items-center gap-2 text-sm">
                <AlertCircle className="h-4 w-4 flex-shrink-0" />
                {error}
              </div>
            )}

            <div className="flex-1 p-4 overflow-hidden">
              {loadingCommand ? (
                <div className="flex items-center justify-center h-full">
                  <Loader className="h-6 w-6 animate-spin text-white/40" />
                </div>
              ) : (
                <textarea
                  value={content}
                  onChange={(e) => {
                    setContent(e.target.value);
                    setIsDirty(true);
                  }}
                  className="w-full h-full font-mono text-sm bg-[#0d0d0e] border border-white/[0.06] rounded-lg p-4 text-white/90 resize-none focus:outline-none focus:border-indigo-500/50"
                  spellCheck={false}
                />
              )}
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-white/40">
            Select a command to edit
          </div>
        )}
      </div>

      {/* New Command Dialog */}
      {showNewDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md p-6 rounded-xl bg-[#1a1a1c] border border-white/[0.06]">
            <h3 className="text-lg font-medium text-white mb-4">New Command</h3>
            <input
              type="text"
              placeholder="Command name (e.g., my-command)"
              value={newCommandName}
              onChange={(e) => setNewCommandName(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, '-'))}
              className="w-full px-4 py-2 rounded-lg bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-white/30 focus:outline-none focus:border-indigo-500/50 mb-4"
            />
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowNewDialog(false)}
                className="px-4 py-2 text-sm text-white/60 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={handleCreate}
                disabled={!newCommandName.trim() || saving}
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-500 hover:bg-indigo-600 rounded-lg disabled:opacity-50"
              >
                {saving ? 'Creating...' : 'Create'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function CommandsPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center h-full">
        <Loader className="h-8 w-8 animate-spin text-white/40" />
      </div>
    }>
      <CommandsPageContent />
    </Suspense>
  );
}
