export type ClassResultBatchRosterStudent = {
  id: string;
  class_id?: string | null;
  current_class_id?: string | null;
};
export type ClassResultBatchRosterOptions = {
  classId: string;
  session: string;
  maxStudents?: number;
};
export type ClassResultBatchRosterPayload = {
  class_id: string;
  session: string;
  expected_student_count: number;
  students: Array<{ student_id: string; student_order: number }>;
};
export function buildClassResultBatchRoster(
  roster: ClassResultBatchRosterStudent[],
  options: ClassResultBatchRosterOptions
): ClassResultBatchRosterPayload;
