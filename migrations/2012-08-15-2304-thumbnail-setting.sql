ALTER TABLE accounts ADD COLUMN thumbnail BOOLEAN NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN accounts.thumbnail IS
'Whether display images as thumbnails or full size in excerpts.';
