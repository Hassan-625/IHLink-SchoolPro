export type RosterSubject = { subject_id: string; name?: string; code?: string };
export type RosterStudent = { id: string; first_name?: string | null; middle_name?: string | null; last_name?: string | null; admission_number?: string | null; gender?: string | null; date_of_birth?: string | null };
export type RosterAssessmentComponent = { key: string; label?: string; maxScore: number | string };
export type RosterSubjectResult = {
  student_id: string; subject_id: string; total_score?: number | string | null;
  assessment_scores?: Record<string, number | string | null>;
  grade?: string | null; grade_label?: string | null; status?: string | null;
  subject_average?: number | string | null; subject_position?: number | string | null; subject_remark?: string | null;
};
export function populateRosterSubjectRows(args: {
  worksheet: any; roster: RosterStudent[]; subjects: RosterSubject[];
  subjectRowMappings: Record<string, number | string>; results: RosterSubjectResult[];
  columns?: Record<string, string>; componentColumns?: Record<string, string>;
  assessmentComponentsBySubject?: Record<string, RosterAssessmentComponent[]>; studentFieldCells?: Record<string, string>; studentContext?: {schoolName?:string;term?:string;session?:string}; customFields?: Array<{id:string;label?:string;cell:string;source:string;value?:string;valueType?:"text"|"number"|"date"|"boolean";enabled?:boolean}>; customFieldValuesByStudent?: Record<string,Record<string,unknown>>; rowStride?: number;
  studentBlock: { startRow: number; endRow: number; rowStride?: number };
}): { firstSubjectRow: number; lastSubjectRow: number; subjectBlockHeight: number; rowStride: number; finalRow: number; students: Array<{studentId:string;index:number;rowOffset:number;subjectRows:Record<string,number>;firstSubjectRow:number;lastSubjectRow:number}>; boundResultCount:number; subjectRows:Array<Record<string,string|number>> };
