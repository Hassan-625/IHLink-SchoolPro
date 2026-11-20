/**
 * Build the immutable roster request for a class-result batch.
 *
 * Input must be the already session-resolved roster returned by
 * schoolSessionStudents(). The class_id on those rows is the historical
 * session placement; current_class_id is deliberately never consulted.
 * The database RPC must independently revalidate every ID against
 * schoolpro_enrollment_history for the supplied school/session/class.
 */
export function buildClassResultBatchRoster(roster, { classId, session, maxStudents = 500 } = {}) {
  const targetClassId = String(classId ?? "").trim();
  const targetSession = String(session ?? "").trim();
  if (!targetClassId) throw new Error("A selected class is required for the result batch.");
  if (!/^\d{4}\s*[/-]\s*\d{4}$/.test(targetSession)) {
    throw new Error("A valid academic session is required for the result batch.");
  }
  if (!Array.isArray(roster) || roster.length === 0) {
    throw new Error("The selected session has no students in this class.");
  }
  if (!Number.isInteger(maxStudents) || maxStudents < 1 || maxStudents > 500 || roster.length > maxStudents) {
    throw new Error("The class roster exceeds the supported batch size.");
  }

  const seen = new Set();
  const students = roster.map((student, index) => {
    const id = String(student?.id ?? "").trim();
    if (!id || seen.has(id)) {
      throw new Error("Every class-batch student must have a unique stable student ID.");
    }
    seen.add(id);
    if (String(student?.class_id ?? "").trim() !== targetClassId) {
      throw new Error("The roster contains a student outside the selected class in this academic session.");
    }
    return { student_id: id, student_order: index + 1 };
  });

  return {
    class_id: targetClassId,
    session: targetSession,
    expected_student_count: students.length,
    students,
  };
}
