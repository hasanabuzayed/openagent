'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  getLibraryMcps,
  saveLibraryMcps,
  type McpServerDef,
} from '@/lib/api';
import {
  ArrowLeft,
  Save,
  AlertCircle,
  Loader,
  Plug,
} from 'lucide-react';
import { cn } from '@/lib/utils';

export default function McpsPage() {
  const [mcps, setMcps] = useState<Record<string, McpServerDef>>({});
  const [jsonContent, setJsonContent] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [parseError, setParseError] = useState<string | null>(null);
  const [isDirty, setIsDirty] = useState(false);

  useEffect(() => {
    const loadMcps = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await getLibraryMcps();
        setMcps(data);
        setJsonContent(JSON.stringify(data, null, 2));
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load MCPs');
      } finally {
        setLoading(false);
      }
    };
    loadMcps();
  }, []);

  const handleContentChange = (value: string) => {
    setJsonContent(value);
    setIsDirty(true);
    setParseError(null);

    try {
      JSON.parse(value);
    } catch (err) {
      setParseError(err instanceof Error ? err.message : 'Invalid JSON');
    }
  };

  const handleSave = async () => {
    if (parseError) return;

    try {
      setSaving(true);
      const parsed = JSON.parse(jsonContent);
      await saveLibraryMcps(parsed);
      setMcps(parsed);
      setIsDirty(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save MCPs');
    } finally {
      setSaving(false);
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
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-white/[0.06]">
        <div className="flex items-center gap-4">
          <Link
            href="/library"
            className="p-2 rounded-lg hover:bg-white/[0.04] transition-colors"
          >
            <ArrowLeft className="h-5 w-5 text-white/60" />
          </Link>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-indigo-500/10">
              <Plug className="h-5 w-5 text-indigo-400" />
            </div>
            <div>
              <h1 className="text-lg font-medium text-white">MCP Servers</h1>
              <p className="text-xs text-white/40">mcp/servers.json</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {isDirty && (
            <span className="text-xs text-amber-400">Unsaved changes</span>
          )}
          <button
            onClick={handleSave}
            disabled={saving || !!parseError || !isDirty}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg transition-colors',
              isDirty && !parseError
                ? 'text-white bg-indigo-500 hover:bg-indigo-600'
                : 'text-white/40 bg-white/[0.04]'
            )}
          >
            <Save className={cn('h-4 w-4', saving && 'animate-pulse')} />
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>

      {/* Errors */}
      {(error || parseError) && (
        <div className={cn(
          'mx-4 mt-4 p-3 rounded-lg flex items-center gap-2 text-sm',
          error ? 'bg-red-500/10 text-red-400' : 'bg-amber-500/10 text-amber-400'
        )}>
          <AlertCircle className="h-4 w-4 flex-shrink-0" />
          {error || parseError}
        </div>
      )}

      {/* Editor */}
      <div className="flex-1 p-4 overflow-hidden">
        <textarea
          value={jsonContent}
          onChange={(e) => handleContentChange(e.target.value)}
          className="w-full h-full font-mono text-sm bg-[#0d0d0e] border border-white/[0.06] rounded-lg p-4 text-white/90 resize-none focus:outline-none focus:border-indigo-500/50"
          spellCheck={false}
        />
      </div>
    </div>
  );
}
