'use client';

import { Suspense, useEffect, useState } from 'react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import {
  listLibrarySkills,
  getLibrarySkill,
  saveLibrarySkill,
  deleteLibrarySkill,
  type SkillSummary,
  type Skill,
} from '@/lib/api';
import {
  ArrowLeft,
  Save,
  AlertCircle,
  Loader,
  FileCode,
  Plus,
  Trash2,
  ChevronRight,
} from 'lucide-react';
import { cn } from '@/lib/utils';

function SkillsPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const selectedName = searchParams.get('name');

  const [skills, setSkills] = useState<SkillSummary[]>([]);
  const [selectedSkill, setSelectedSkill] = useState<Skill | null>(null);
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(true);
  const [loadingSkill, setLoadingSkill] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isDirty, setIsDirty] = useState(false);
  const [showNewDialog, setShowNewDialog] = useState(false);
  const [newSkillName, setNewSkillName] = useState('');

  const loadSkills = async () => {
    try {
      setLoading(true);
      const data = await listLibrarySkills();
      setSkills(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load skills');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSkills();
  }, []);

  useEffect(() => {
    if (selectedName) {
      loadSkill(selectedName);
    } else {
      setSelectedSkill(null);
      setContent('');
    }
  }, [selectedName]);

  const loadSkill = async (name: string) => {
    try {
      setLoadingSkill(true);
      setError(null);
      const skill = await getLibrarySkill(name);
      setSelectedSkill(skill);
      setContent(skill.content);
      setIsDirty(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load skill');
    } finally {
      setLoadingSkill(false);
    }
  };

  const handleSave = async () => {
    if (!selectedSkill) return;

    try {
      setSaving(true);
      await saveLibrarySkill(selectedSkill.name, content);
      setIsDirty(false);
      await loadSkills();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save skill');
    } finally {
      setSaving(false);
    }
  };

  const handleCreate = async () => {
    if (!newSkillName.trim()) return;

    const template = `---
description: A new skill
---

# ${newSkillName}

Describe what this skill does.
`;

    try {
      setSaving(true);
      await saveLibrarySkill(newSkillName, template);
      await loadSkills();
      setShowNewDialog(false);
      setNewSkillName('');
      router.push(`/library/skills?name=${encodeURIComponent(newSkillName)}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create skill');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedSkill) return;
    if (!confirm(`Delete skill "${selectedSkill.name}"?`)) return;

    try {
      await deleteLibrarySkill(selectedSkill.name);
      await loadSkills();
      router.push('/library/skills');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete skill');
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
      {/* Skills List */}
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
            <FileCode className="h-4 w-4 text-emerald-400" />
            <span className="text-sm font-medium text-white">Skills</span>
          </div>
        </div>
        <div className="flex-1 overflow-y-auto p-2">
          {skills.length === 0 ? (
            <p className="text-sm text-white/40 text-center py-4">No skills yet</p>
          ) : (
            skills.map((skill) => (
              <Link
                key={skill.name}
                href={`/library/skills?name=${encodeURIComponent(skill.name)}`}
                className={cn(
                  'flex items-center justify-between p-3 rounded-lg transition-colors',
                  selectedName === skill.name
                    ? 'bg-white/[0.08] text-white'
                    : 'text-white/60 hover:bg-white/[0.04] hover:text-white'
                )}
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium truncate">{skill.name}</p>
                  {skill.description && (
                    <p className="text-xs text-white/40 truncate">{skill.description}</p>
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
        {selectedSkill ? (
          <>
            <div className="flex items-center justify-between p-4 border-b border-white/[0.06]">
              <div>
                <h2 className="text-lg font-medium text-white">{selectedSkill.name}</h2>
                <p className="text-xs text-white/40">{selectedSkill.path}/SKILL.md</p>
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
              {loadingSkill ? (
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

            {/* References */}
            {selectedSkill.references.length > 0 && (
              <div className="p-4 border-t border-white/[0.06]">
                <p className="text-xs text-white/40 mb-2">Reference files:</p>
                <div className="flex flex-wrap gap-2">
                  {selectedSkill.references.map((ref) => (
                    <span
                      key={ref}
                      className="px-2 py-1 text-xs bg-white/[0.04] rounded-md text-white/60"
                    >
                      {ref}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-white/40">
            Select a skill to edit
          </div>
        )}
      </div>

      {/* New Skill Dialog */}
      {showNewDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md p-6 rounded-xl bg-[#1a1a1c] border border-white/[0.06]">
            <h3 className="text-lg font-medium text-white mb-4">New Skill</h3>
            <input
              type="text"
              placeholder="Skill name (e.g., my-skill)"
              value={newSkillName}
              onChange={(e) => setNewSkillName(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, '-'))}
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
                disabled={!newSkillName.trim() || saving}
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

export default function SkillsPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center h-full">
        <Loader className="h-8 w-8 animate-spin text-white/40" />
      </div>
    }>
      <SkillsPageContent />
    </Suspense>
  );
}
