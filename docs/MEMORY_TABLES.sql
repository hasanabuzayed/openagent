-- Memory System Tables for Open Agent
-- Run this in your Supabase SQL editor to enable the memory features.
--
-- Prerequisites:
-- - pgvector extension enabled
-- - Existing tables: runs, tasks, events, chunks, task_outcomes, missions

-- ============================================================
-- User Facts: Long-term storage of user preferences and project info
-- ============================================================

CREATE TABLE IF NOT EXISTS user_facts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fact_text TEXT NOT NULL,
    category TEXT, -- 'preference', 'project', 'convention', 'person'
    embedding VECTOR(1536), -- For semantic search
    source_mission_id UUID REFERENCES missions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for text search
CREATE INDEX IF NOT EXISTS idx_user_facts_text ON user_facts USING gin(to_tsvector('english', fact_text));

-- Index for category filtering
CREATE INDEX IF NOT EXISTS idx_user_facts_category ON user_facts(category);

-- Vector similarity search index
CREATE INDEX IF NOT EXISTS idx_user_facts_embedding ON user_facts USING ivfflat (embedding vector_cosine_ops);

-- ============================================================
-- Mission Summaries: Learnings from completed missions
-- ============================================================

CREATE TABLE IF NOT EXISTS mission_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    key_files TEXT[] DEFAULT '{}',
    tools_used TEXT[] DEFAULT '{}',
    success BOOLEAN DEFAULT true,
    embedding VECTOR(1536), -- For semantic search
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique constraint - one summary per mission
CREATE UNIQUE INDEX IF NOT EXISTS idx_mission_summaries_mission ON mission_summaries(mission_id);

-- Vector similarity search index
CREATE INDEX IF NOT EXISTS idx_mission_summaries_embedding ON mission_summaries USING ivfflat (embedding vector_cosine_ops);

-- Index for success filtering
CREATE INDEX IF NOT EXISTS idx_mission_summaries_success ON mission_summaries(success);

-- ============================================================
-- RPC Functions for semantic search
-- ============================================================

-- Search user facts by embedding similarity
CREATE OR REPLACE FUNCTION search_user_facts_by_embedding(
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.5,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    fact_text TEXT,
    category TEXT,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uf.id,
        uf.fact_text,
        uf.category,
        1 - (uf.embedding <=> query_embedding) AS similarity
    FROM user_facts uf
    WHERE uf.embedding IS NOT NULL
        AND 1 - (uf.embedding <=> query_embedding) > match_threshold
    ORDER BY uf.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Search mission summaries by embedding similarity
CREATE OR REPLACE FUNCTION search_mission_summaries_by_embedding(
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.5,
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    mission_id UUID,
    summary TEXT,
    key_files TEXT[],
    tools_used TEXT[],
    success BOOLEAN,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ms.id,
        ms.mission_id,
        ms.summary,
        ms.key_files,
        ms.tools_used,
        ms.success,
        1 - (ms.embedding <=> query_embedding) AS similarity
    FROM mission_summaries ms
    WHERE ms.embedding IS NOT NULL
        AND 1 - (ms.embedding <=> query_embedding) > match_threshold
    ORDER BY ms.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- ============================================================
-- Row Level Security (if needed)
-- ============================================================

-- Enable RLS on new tables
ALTER TABLE user_facts ENABLE ROW LEVEL SECURITY;
ALTER TABLE mission_summaries ENABLE ROW LEVEL SECURITY;

-- Allow service role full access
CREATE POLICY "Service role access" ON user_facts FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role access" ON mission_summaries FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================
-- Verification Query
-- ============================================================

-- Run this to verify tables were created:
-- SELECT table_name FROM information_schema.tables WHERE table_name IN ('user_facts', 'mission_summaries');
