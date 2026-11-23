export interface SchoolProCustomRosterStudent {
  id: string;
  first_name?: string | null;
  middle_name?: string | null;
  last_name?: string | null;
  admission_number?: string | null;
  class_name?: string;
  gender?: string | null;
  date_of_birth?: string | null;
}

export interface SchoolProCustomSubject {
  subject_id: string;
  id?: string;
  name?: string;
  code?: string;
}

export interface SchoolProCustomResult {
  student_id: string;
  subject_id: string;
  total_score: number | string;
  status: string;
  assessment_scheme_id: string;
  assessment_scores: Record<string, number | string>;
  grade?: string | null;
  grade_label?: string | null;
}

export interface SchoolProCustomAssessmentScheme {
  id: string;
  components: Array<{ key: string; label?: string; name?: string; maxScore: number | string }>;
}

export interface SchoolProCustomWorkbookOptions {
  templateBuffer: ArrayBuffer | Uint8Array;
  templateConfig: {
    sheet_name: string;
    student_block?: { startRow: number; endRow: number; rowStride?: number } | null;
    field_cells?: Record<string, string>;
    columns?: Record<string, string>;
    component_columns?: Record<string, any>;
    custom_fields?: Array<{ id: string; label?: string; cell: string; source: string; value?: string; valueType?: "text" | "number" | "date" | "boolean"; enabled?: boolean }>;
  };
  roster: SchoolProCustomRosterStudent[];
  subjects: SchoolProCustomSubject[];
  subjectRowMappings: Record<string, number | string>;
  results: SchoolProCustomResult[];
  assessmentSchemes: SchoolProCustomAssessmentScheme[];
  schoolName: string;
  className: string;
  term: string;
  session: string;
}

export interface SchoolProCustomWorkbookResult {
  buffer: any;
  formulaCalculation: {
    formulaCount: number;
    evaluationCount: number;
    sheets: Array<{ name: string; formulaCount: number }>;
    engine: string;
    engineVersion: string;
    calculationMode: string;
  };
  studentCount: number;
  subjectCount: number;
  boundResultCount: number;
  subjectIds: string[];
  worksheetName: string;
  repeatedStudentBlock: { startRow: number; endRow: number; rowStride: number };
}

export function buildSchoolProCustomClassResultWorkbook(
  options: SchoolProCustomWorkbookOptions
): Promise<SchoolProCustomWorkbookResult>;
