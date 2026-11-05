export const schoolProPlanFeatures = (flags: Record<string, unknown>): string[] => [
  "Core school management",
  "Student, staff, class and academic-session management",
  "Attendance and fee management",
  "Standard results, report cards, class broadsheets and ordinary exports",
  "Parent and guardian portal",
  "Library, transport, hostel and inventory modules",
  "Payroll, discipline, certificates and school operations",
  "Houses, Games, Sports and Competitions",
  ...(flags.website === true ? ["School website"] : []),
  ...(flags.cbt === true ? ["Computer-Based Testing (CBT) and online examinations"] : []),
  ...(flags.advanced_reports === true ? ["Enterprise Advanced Reports: school, class, subject, student, attendance, assessment and progression analytics"] : []),
  ...(flags.custom_branding === true ? ["Custom branding by request and IHLink review/approval"] : []),
];
