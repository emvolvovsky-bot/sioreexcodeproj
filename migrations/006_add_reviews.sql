-- Migration: Add reviews table for hosts and talents
-- Created: 2024

-- Create reviews table without foreign keys first
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reviewer_id UUID NOT NULL,
    reviewed_user_id UUID NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_review UNIQUE (reviewer_id, reviewed_user_id),
    CONSTRAINT no_self_review CHECK (reviewer_id != reviewed_user_id)
);

-- Add foreign key constraints if they don't exist (with error handling)
DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'reviews_reviewer_id_fkey' AND table_name = 'reviews'
        ) THEN
            ALTER TABLE reviews ADD CONSTRAINT reviews_reviewer_id_fkey 
                FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Could not add reviewer_id foreign key: %', SQLERRM;
    END;
    
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'reviews_reviewed_user_id_fkey' AND table_name = 'reviews'
        ) THEN
            ALTER TABLE reviews ADD CONSTRAINT reviews_reviewed_user_id_fkey 
                FOREIGN KEY (reviewed_user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Could not add reviewed_user_id foreign key: %', SQLERRM;
    END;
END $$;

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_reviews_reviewed_user ON reviews(reviewed_user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_reviews_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_reviews_timestamp
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_reviews_updated_at();

-- Add average rating column to users table (for quick access)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'average_rating'
    ) THEN
        ALTER TABLE users ADD COLUMN average_rating DECIMAL(3,2) DEFAULT NULL;
    END IF;
END $$;

-- Add review count column to users table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'review_count'
    ) THEN
        ALTER TABLE users ADD COLUMN review_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- Function to update user's average rating and review count
CREATE OR REPLACE FUNCTION update_user_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update average rating and review count for the reviewed user
    UPDATE users
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating)::DECIMAL(3,2), NULL)
            FROM reviews
            WHERE reviewed_user_id = NEW.reviewed_user_id
        ),
        review_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE reviewed_user_id = NEW.reviewed_user_id
        )
    WHERE id = NEW.reviewed_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update stats when a review is created
CREATE TRIGGER update_user_rating_on_insert
    AFTER INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rating_stats();

-- Trigger to update stats when a review is updated
CREATE TRIGGER update_user_rating_on_update
    AFTER UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rating_stats();

-- Trigger to update stats when a review is deleted
CREATE OR REPLACE FUNCTION update_user_rating_on_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating)::DECIMAL(3,2), NULL)
            FROM reviews
            WHERE reviewed_user_id = OLD.reviewed_user_id
        ),
        review_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE reviewed_user_id = OLD.reviewed_user_id
        )
    WHERE id = OLD.reviewed_user_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_rating_on_delete
    AFTER DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rating_on_delete();

