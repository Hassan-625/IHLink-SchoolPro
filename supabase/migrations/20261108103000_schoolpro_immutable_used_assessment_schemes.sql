-- Assessment scheme definitions become immutable once saved result rows reference them.
-- Renaming a scheme or changing which scheme is the default remains allowed.
create or replace function private.prevent_used_assessment_scheme_change()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
begin
 if (
   new.school_id is distinct from old.school_id
   or new.school_level is distinct from old.school_level
   or new.components is distinct from old.components
 ) and exists(
   select 1 from public.schoolpro_results r
   where r.assessment_scheme_id=old.id and r.school_id=old.school_id
 ) then
  raise exception 'This assessment scheme is already used by saved results. Create a new scheme to change its components or school level.';
 end if;
 return new;
end
$function$;
revoke all on function private.prevent_used_assessment_scheme_change() from public,anon,authenticated;
drop trigger if exists prevent_used_schoolpro_assessment_scheme_change on public.schoolpro_assessment_schemes;
create trigger prevent_used_schoolpro_assessment_scheme_change
before update on public.schoolpro_assessment_schemes
for each row execute procedure private.prevent_used_assessment_scheme_change();
