begin;

-- Keep the class-template assignment RPC unavailable to anonymous callers.
-- The function is intended for authenticated school administrators and Form Masters;
-- its body enforces the caller's tenant and class scope.
revoke all on function public.schoolpro_set_class_result_template(
  uuid, uuid, text, text, jsonb, jsonb
) from public, anon;

grant execute on function public.schoolpro_set_class_result_template(
  uuid, uuid, text, text, jsonb, jsonb
) to authenticated;

commit;
