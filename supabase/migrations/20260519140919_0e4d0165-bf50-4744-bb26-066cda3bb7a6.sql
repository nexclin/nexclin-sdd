ALTER TABLE public.payment_methods
  ADD COLUMN IF NOT EXISTS credit_1x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_2x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_3x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_4x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_5x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_6x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_7x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_8x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_9x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_10x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_11x_fee_anticip numeric,
  ADD COLUMN IF NOT EXISTS credit_12x_fee_anticip numeric;