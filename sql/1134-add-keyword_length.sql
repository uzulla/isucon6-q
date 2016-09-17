ALTER TABLE entry ADD COLUMN `keyword_length` INTEGER NOT NULL DEFAULT 0;
ALTER TABLE entry ADD INDEX `keyword_and_length` (`keyword`, `keyword_length`);

