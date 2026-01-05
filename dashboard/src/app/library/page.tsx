'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  getLibraryStatus,
  syncLibrary,
  commitLibrary,
  pushLibrary,
  listLibrarySkills,
  listLibraryCommands,
  type LibraryStatus,
  type SkillSummary,
  type CommandSummary,
} from '@/lib/api';
import {
  GitBranch,
  RefreshCw,
  Upload,
  Check,
  AlertCircle,
  FileCode,
  Terminal,
  Plug,
  ChevronRight,
  Loader,
} from 'lucide-react';
import { cn } from '@/lib/utils';

export default function LibraryPage() {
  const [status, setStatus] = useState<LibraryStatus | null>(null);
  const [skills, setSkills] = useState<SkillSummary[]>([]);
  const [commands, setCommands] = useState<CommandSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [committing, setCommitting] = useState(false);
  const [pushing, setPushing] = useState(false);
  const [commitMessage, setCommitMessage] = useState('');
  const [showCommitDialog, setShowCommitDialog] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [statusData, skillsData, commandsData] = await Promise.all([
        getLibraryStatus(),
        listLibrarySkills(),
        listLibraryCommands(),
      ]);
      setStatus(statusData);
      setSkills(skillsData);
      setCommands(commandsData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load library');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleSync = async () => {
    try {
      setSyncing(true);
      await syncLibrary();
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to sync');
    } finally {
      setSyncing(false);
    }
  };

  const handleCommit = async () => {
    if (!commitMessage.trim()) return;
    try {
      setCommitting(true);
      await commitLibrary(commitMessage);
      setCommitMessage('');
      setShowCommitDialog(false);
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to commit');
    } finally {
      setCommitting(false);
    }
  };

  const handlePush = async () => {
    try {
      setPushing(true);
      await pushLibrary();
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to push');
    } finally {
      setPushing(false);
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
    <div className="p-6 max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-semibold text-white mb-2">Library</h1>
        <p className="text-white/50">
          Manage your configuration library: MCP servers, skills, and commands.
        </p>
      </div>

      {error && (
        <div className="mb-6 p-4 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 flex items-center gap-2">
          <AlertCircle className="h-4 w-4 flex-shrink-0" />
          {error}
        </div>
      )}

      {/* Git Status Bar */}
      {status && (
        <div className="mb-8 p-4 rounded-xl bg-white/[0.02] border border-white/[0.06]">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <GitBranch className="h-4 w-4 text-white/40" />
                <span className="text-sm font-medium text-white">{status.branch}</span>
              </div>
              <div className="flex items-center gap-2">
                {status.clean ? (
                  <span className="flex items-center gap-1 text-xs text-emerald-400">
                    <Check className="h-3 w-3" />
                    Clean
                  </span>
                ) : (
                  <span className="flex items-center gap-1 text-xs text-amber-400">
                    <AlertCircle className="h-3 w-3" />
                    {status.modified_files.length} modified
                  </span>
                )}
              </div>
              {(status.ahead > 0 || status.behind > 0) && (
                <div className="text-xs text-white/40">
                  {status.ahead > 0 && <span className="text-emerald-400">+{status.ahead}</span>}
                  {status.ahead > 0 && status.behind > 0 && ' / '}
                  {status.behind > 0 && <span className="text-amber-400">-{status.behind}</span>}
                </div>
              )}
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={handleSync}
                disabled={syncing}
                className="flex items-center gap-2 px-3 py-1.5 text-xs font-medium text-white/70 hover:text-white bg-white/[0.04] hover:bg-white/[0.08] rounded-lg transition-colors disabled:opacity-50"
              >
                <RefreshCw className={cn('h-3 w-3', syncing && 'animate-spin')} />
                Sync
              </button>
              {!status.clean && (
                <button
                  onClick={() => setShowCommitDialog(true)}
                  disabled={committing}
                  className="flex items-center gap-2 px-3 py-1.5 text-xs font-medium text-white/70 hover:text-white bg-white/[0.04] hover:bg-white/[0.08] rounded-lg transition-colors disabled:opacity-50"
                >
                  <Check className="h-3 w-3" />
                  Commit
                </button>
              )}
              {status.ahead > 0 && (
                <button
                  onClick={handlePush}
                  disabled={pushing}
                  className="flex items-center gap-2 px-3 py-1.5 text-xs font-medium text-emerald-400 hover:text-emerald-300 bg-emerald-500/10 hover:bg-emerald-500/20 rounded-lg transition-colors disabled:opacity-50"
                >
                  <Upload className={cn('h-3 w-3', pushing && 'animate-pulse')} />
                  Push
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Commit Dialog */}
      {showCommitDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md p-6 rounded-xl bg-[#1a1a1c] border border-white/[0.06]">
            <h3 className="text-lg font-medium text-white mb-4">Commit Changes</h3>
            <input
              type="text"
              placeholder="Commit message..."
              value={commitMessage}
              onChange={(e) => setCommitMessage(e.target.value)}
              className="w-full px-4 py-2 rounded-lg bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-white/30 focus:outline-none focus:border-indigo-500/50 mb-4"
            />
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowCommitDialog(false)}
                className="px-4 py-2 text-sm text-white/60 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={handleCommit}
                disabled={!commitMessage.trim() || committing}
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-500 hover:bg-indigo-600 rounded-lg disabled:opacity-50"
              >
                {committing ? 'Committing...' : 'Commit'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Section Cards */}
      <div className="grid gap-4">
        {/* MCP Servers */}
        <Link
          href="/library/mcps"
          className="group p-5 rounded-xl bg-white/[0.02] border border-white/[0.06] hover:bg-white/[0.04] hover:border-white/[0.08] transition-all"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-lg bg-indigo-500/10">
                <Plug className="h-5 w-5 text-indigo-400" />
              </div>
              <div>
                <h3 className="text-lg font-medium text-white">MCP Servers</h3>
                <p className="text-sm text-white/50">Configure Model Context Protocol servers</p>
              </div>
            </div>
            <ChevronRight className="h-5 w-5 text-white/30 group-hover:text-white/60 transition-colors" />
          </div>
        </Link>

        {/* Skills */}
        <Link
          href="/library/skills"
          className="group p-5 rounded-xl bg-white/[0.02] border border-white/[0.06] hover:bg-white/[0.04] hover:border-white/[0.08] transition-all"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-lg bg-emerald-500/10">
                <FileCode className="h-5 w-5 text-emerald-400" />
              </div>
              <div>
                <h3 className="text-lg font-medium text-white">Skills</h3>
                <p className="text-sm text-white/50">
                  {skills.length} skill{skills.length !== 1 ? 's' : ''} available
                </p>
              </div>
            </div>
            <ChevronRight className="h-5 w-5 text-white/30 group-hover:text-white/60 transition-colors" />
          </div>
        </Link>

        {/* Commands */}
        <Link
          href="/library/commands"
          className="group p-5 rounded-xl bg-white/[0.02] border border-white/[0.06] hover:bg-white/[0.04] hover:border-white/[0.08] transition-all"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-lg bg-amber-500/10">
                <Terminal className="h-5 w-5 text-amber-400" />
              </div>
              <div>
                <h3 className="text-lg font-medium text-white">Commands</h3>
                <p className="text-sm text-white/50">
                  {commands.length} command{commands.length !== 1 ? 's' : ''} available
                </p>
              </div>
            </div>
            <ChevronRight className="h-5 w-5 text-white/30 group-hover:text-white/60 transition-colors" />
          </div>
        </Link>
      </div>
    </div>
  );
}
