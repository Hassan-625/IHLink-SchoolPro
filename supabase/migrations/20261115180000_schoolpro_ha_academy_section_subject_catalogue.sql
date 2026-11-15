-- Add only the missing HA Academy subject catalogue entries.
-- The workbook's repeated class rows describe one section catalogue, so each
-- subject is registered once per section, not once per class arm.
-- Existing subject records are preserved; known Nursery/Primary naming
-- equivalents are treated as already represented to avoid duplicate concepts.
do $$
declare
  v_school_id uuid;
begin
  select id into strict v_school_id
  from public.schoolpro_schools
  where lower(trim(name)) = 'ha academy';

  -- The migration is intentionally school-specific. Disposable CI baselines
  -- may not seed HA Academy; in that case this migration is a safe no-op.
  if v_school_id is null then
    raise notice 'HA Academy is absent from this database; skipping its subject catalogue seed.';
    return;
  end if;

  insert into public.schoolpro_subjects (school_id, name, code, class_name)
  select v_school_id, seed.name, seed.code, seed.class_name
  from (values
    -- Pre-Nursery is part of the Nursery section, so these foundation subjects
    -- share the Nursery catalogue and are not stored in a separate section.
    ('Early Language & Communication', 'NREL', 'Nursery'),
    ('Early Numeracy', 'NREN', 'Nursery'),
    ('Environmental Awareness', 'NREA', 'Nursery'),
    ('Creative Expression', 'NRCE', 'Nursery'),
    ('Rhymes & Movement', 'NRRM', 'Nursery'),
    ('Personal & Social Habits', 'NRPS', 'Nursery'),
    ('Health, Hygiene & Safety', 'NRHS', 'Nursery'),

    -- Nursery workbook subjects not already represented by the current catalogue.
    ('Basic Science', 'NBSC', 'Nursery'),
    ('Creative Arts', 'NCCA', 'Nursery'),
    ('Rhymes & Music', 'NRHM', 'Nursery'),
    ('Physical Development', 'NPHD', 'Nursery'),

    -- Primary workbook subjects not already represented by the current catalogue.
    ('Basic Science & Technology', 'PBST', 'Primary'),
    ('Computer Studies', 'PCOM', 'Primary'),
    ('Cultural & Creative Arts', 'PCCA', 'Primary'),
    ('National Values Education', 'PNVE', 'Primary'),
    ('Physical & Health Education', 'PPHE', 'Primary'),
    ('Religious Studies', 'PREL', 'Primary'),

    -- Junior Secondary workbook curriculum.
    ('English Language', 'JSENG', 'Junior Secondary'),
    ('Mathematics', 'JSMTH', 'Junior Secondary'),
    ('Basic Science', 'JSBSC', 'Junior Secondary'),
    ('Basic Technology', 'JSBTE', 'Junior Secondary'),
    ('Social Studies', 'JSSOC', 'Junior Secondary'),
    ('Civic Education', 'JSCIV', 'Junior Secondary'),
    ('Business Studies', 'JSBUS', 'Junior Secondary'),
    ('Computer Studies', 'JSCOM', 'Junior Secondary'),
    ('Agricultural Science', 'JSAGR', 'Junior Secondary'),
    ('Religious Studies', 'JSREL', 'Junior Secondary'),

    -- Senior Secondary workbook curriculum.
    ('English Language', 'SSENG', 'Senior Secondary'),
    ('Mathematics', 'SSMTH', 'Senior Secondary'),
    ('Biology', 'SSBIO', 'Senior Secondary'),
    ('Chemistry', 'SSCHE', 'Senior Secondary'),
    ('Physics', 'SSPHY', 'Senior Secondary'),
    ('Economics', 'SSECO', 'Senior Secondary'),
    ('Government', 'SSGOV', 'Senior Secondary'),
    ('Literature-in-English', 'SSLIT', 'Senior Secondary'),
    ('Computer Studies', 'SSCOM', 'Senior Secondary'),
    ('Civic Education', 'SSCIV', 'Senior Secondary')
  ) as seed(name, code, class_name)
  where not exists (
    select 1
    from public.schoolpro_subjects existing
    where existing.school_id = v_school_id
      and existing.class_name = seed.class_name
      and lower(trim(existing.name)) = lower(trim(seed.name))
  )
  on conflict (school_id, code, class_name) do nothing;
end
$$;
