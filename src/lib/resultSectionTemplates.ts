export const RESULT_SECTIONS=[['all','School default'],['nursery','Nursery'],['primary','Primary'],['junior_secondary','Junior secondary'],['senior_secondary','Senior secondary']] as const;
/** Section copies remain inside the same school-owned row and its storage permissions. */
export function resolveResultSectionTemplate<T extends {component_columns:Record<string,any>}>(base:T|null,section:string):T|null{
 if(!base)return null;
 const copy=base.component_columns?.__section_templates?.[section];
 return copy?{...base,...copy,...Object.fromEntries(Object.entries(base).filter(([key])=>["id","school_id","updated_by","updated_at","created_at"].includes(key))),component_columns:copy.component_columns||{}}:base;
}
export function keepResultSectionTemplate(base:any,section:string,copy:any){
 const {id,school_id,updated_by,updated_at,created_at,...design}=copy;
 const {__section_templates,...columns}=design.component_columns||{};
 return {...base?.component_columns,__section_templates:{...base?.component_columns?.__section_templates,[section]:{...design,component_columns:columns}}};
}
