-- Public document verification accepts a serial without a school identifier.
-- Enforce normalized global uniqueness so a serial can never resolve to another
-- school's document when compared case-insensitively by verify_schoolpro_document().
do $serial_guard$
begin
  if exists (
    select 1
    from public.schoolpro_document_issues
    group by upper(trim(serial_number))
    having count(*) > 1
  ) then
    raise exception 'Cannot enforce global document serial uniqueness: duplicate normalized serials exist';
  end if;
end
$serial_guard$;

create unique index if not exists schoolpro_document_issues_normalized_serial_global_uq
  on public.schoolpro_document_issues (upper(trim(serial_number)));
