import {schoolRoleOptions} from './schoolRoles';
export type SchoolStaffRole = Exclude<typeof schoolRoleOptions[number][0], 'proprietor'>;
export const schoolStaffRoles = schoolRoleOptions.filter(role => role[0] !== 'proprietor');
