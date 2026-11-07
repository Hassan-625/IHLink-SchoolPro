import {schoolRoleOptions} from './schoolRoles';
export type SchoolStaffRole = Exclude<typeof schoolRoleOptions[number][0], 'proprietor'> | 'principal';
export const schoolStaffRoles = [...schoolRoleOptions.filter(role => role[0] !== 'proprietor'), ['principal', 'Principal'] as const];
