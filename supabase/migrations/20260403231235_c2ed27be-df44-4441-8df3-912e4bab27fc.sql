ALTER TABLE public.acquirers
ADD COLUMN IF NOT EXISTS debit_other_fee_percent numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_fee_percent numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_2x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_3x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_4x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_5x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_6x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_7x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_8x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_9x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_10x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_11x_fee numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit_other_12x_fee numeric DEFAULT 0;