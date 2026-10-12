create or replace function private.schoolpro_teacher_allocation_visible(p_school uuid,p_member uuid,p_class uuid) returns boolean language plpgsql stable security definer set search_path='' as $$
declare own_member uuid;
begin
 if auth.uid() is null or not private.is_active_account() then return false;end if;
 select m.id into own_member from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role in('teacher','class_teacher');
 if own_member is null then return true;end if;
 return own_member=p_member or exists(select 1 from public.schoolpro_classes c where c.id=p_class and c.school_id=p_school and c.form_teacher_id=own_member);
end $$;
revoke all on function private.schoolpro_teacher_allocation_visible(uuid,uuid,uuid) from public,anon;
grant execute on function private.schoolpro_teacher_allocation_visible(uuid,uuid,uuid) to authenticated;
alter policy "Teachers read their own allocations" on public.schoolpro_subject_assignments using (private.schoolpro_teacher_allocation_visible(school_id,teacher_member_id,class_id));