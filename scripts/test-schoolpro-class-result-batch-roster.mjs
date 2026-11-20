import assert from "node:assert/strict";
import { buildClassResultBatchRoster } from "../src/lib/schoolproClassResultBatchRoster.mjs";

const historicalRoster = [
  { id: "student-a", class_id: "class-pre-a", current_class_id: "class-basic-1" },
  { id: "student-b", class_id: "class-pre-a", current_class_id: "class-nursery-1" },
  { id: "student-c", class_id: "class-pre-a", current_class_id: "class-pre-a" },
];
const payload = buildClassResultBatchRoster(historicalRoster, {
  classId: "class-pre-a",
  session: "2024/2025",
});
assert.deepEqual(payload, {
  class_id: "class-pre-a",
  session: "2024/2025",
  expected_student_count: 3,
  students: [
    { student_id: "student-a", student_order: 1 },
    { student_id: "student-b", student_order: 2 },
    { student_id: "student-c", student_order: 3 },
  ],
});
assert.equal(payload.students.some((row) => row.student_id === "class-basic-1"), false);

assert.throws(
  () => buildClassResultBatchRoster([{ id: "a", class_id: "class-1" }, { id: "a", class_id: "class-1" }], { classId: "class-1", session: "2025/2026" }),
  /unique stable student ID/,
);
assert.throws(
  () => buildClassResultBatchRoster([{ id: "a", class_id: "class-2" }], { classId: "class-1", session: "2025/2026" }),
  /outside the selected class/,
);
assert.throws(
  () => buildClassResultBatchRoster([{ id: "a", class_id: "class-1" }], { classId: "class-1", session: "2025" }),
  /valid academic session/,
);
assert.throws(
  () => buildClassResultBatchRoster(Array.from({ length: 501 }, (_, i) => ({ id: String(i), class_id: "class-1" })), { classId: "class-1", session: "2025/2026" }),
  /supported batch size/,
);
assert.throws(() => buildClassResultBatchRoster([], { classId: "class-1", session: "2025/2026" }), /no students/);

console.log("SchoolPro class-result batch session-roster contract passed.");
