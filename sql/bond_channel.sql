-- Bond Channel: bidirectional message table between IEBC Internal Bond and External Daytona Bond.
-- Run this once in your Supabase SQL editor.

CREATE TABLE IF NOT EXISTS bond_channel (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    direction   TEXT        NOT NULL CHECK (direction IN ('internal_to_external', 'external_to_internal')),
    from_label  TEXT        NOT NULL,
    message_type TEXT       NOT NULL DEFAULT 'directive'
                            CHECK (message_type IN ('directive','report','feedback','suggestion','acknowledgment')),
    content     TEXT        NOT NULL,
    priority    TEXT        NOT NULL DEFAULT 'normal'
                            CHECK (priority IN ('critical','high','normal','low')),
    status      TEXT        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending','delivered','read','actioned')),
    metadata    JSONB       DEFAULT '{}',
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- Index for efficient polling by direction + status
CREATE INDEX IF NOT EXISTS bond_channel_direction_status
    ON bond_channel (direction, status, created_at);

-- Auto-update updated_at on row change
CREATE OR REPLACE FUNCTION update_bond_channel_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bond_channel_updated_at ON bond_channel;
CREATE TRIGGER bond_channel_updated_at
    BEFORE UPDATE ON bond_channel
    FOR EACH ROW EXECUTE FUNCTION update_bond_channel_timestamp();
