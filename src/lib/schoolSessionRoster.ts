export type SessionRosterStudent = { id: string; class_id?: string | null; class_name?: string | null; status?: string | null };
export type SessionEnrollmentRow = { student_id: string; class_id: string; class_name: string; arm: string; section: string; status: string };

/** Resolve one session roster without carrying inactive current students into legacy sessions. */
export function resolveSchoolSessionRoster<T extends SessionRosterStudent>(
  students: T[],
  historyRows: SessionEnrollmentRow[],
  schoolHasAnyHistory: boolean,
): (T & { current_class_id?: string | null; session_status?: string; class_level?: string })[] {
  if (!historyRows.length) {
    return schoolHasAnyHistory ? [] : students.filter((student) => student.status === 'active');
  }
  const historyByStudent = new Map(historyRows.map((row) => [row.student_id, row]));
  return students.filter((student) => historyByStudent.has(student.id)).map((student) => {
    const row = historyByStudent.get(student.id)!;
    return {
      ...student,
      current_class_id: student.class_id,
      session_status: row.status,
      class_id: row.class_id,
      class_name: [row.class_name, row.arm].filter(Boolean).join(' '),
      class_level: row.section,
    };
  });
}
