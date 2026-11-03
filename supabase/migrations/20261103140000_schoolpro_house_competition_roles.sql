-- Add dedicated SchoolPro B6 specialist roles.
alter type public.school_member_role add value if not exists 'discipline_master';
alter type public.school_member_role add value if not exists 'game_master';
