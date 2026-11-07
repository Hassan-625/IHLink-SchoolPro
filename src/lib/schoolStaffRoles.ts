import {schoolRoleOptions} from './schoolRoles';
export const schoolStaffRoles = [...schoolRoleOptions.filter(role => role[0] !== 'proprietor'), ['principal', 'Principal'] as const];
export type SchoolStaffRole = typeof schoolStaffRoles[number][0];
