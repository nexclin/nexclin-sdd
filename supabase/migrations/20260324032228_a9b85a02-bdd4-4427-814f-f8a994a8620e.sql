-- Allow anonymous users to read their specific anamnesis response (by ID in URL)
CREATE POLICY "Anon can read response by id" ON anamnesis_responses
  FOR SELECT TO anon USING (true);

-- Allow anonymous users to update only pending responses (prevents re-submission)
CREATE POLICY "Anon can update pending response" ON anamnesis_responses
  FOR UPDATE TO anon
  USING (status != 'preenchido')
  WITH CHECK (true);

-- Allow anonymous to read anamnesis config (for form field definitions)
CREATE POLICY "Anon can read anamnesis config" ON anamnesis_config
  FOR SELECT TO anon USING (true);