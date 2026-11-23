export type SchoolProBatchReviewPreviewCell = { cell: string; value: string; formula: boolean };
export type SchoolProBatchReviewItem = {
  id: string;
  label: string;
  payload: {
    workbook: Blob;
    meta: { formulaCalculation?: { formulaCount?: number } };
    preview: SchoolProBatchReviewPreviewCell[];
  };
};
type Props = {
  items: SchoolProBatchReviewItem[];
  busy: boolean;
  finalizingId: string | null;
  onApprove: (item: SchoolProBatchReviewItem) => void;
  onReject: (item: SchoolProBatchReviewItem) => void;
};
export function SchoolProClassResultBatchReview({items,busy,finalizingId,onApprove,onReject}: Props) {
  if (!items.length) return null;
  return <section aria-labelledby="schoolpro-batch-review-heading" className="rounded-xl border bg-white p-4">
    <h3 id="schoolpro-batch-review-heading" className="font-bold">Review each student workbook before finalizing</h3>
    <p className="mt-1 text-sm text-muted">The consolidated class score workbook is stored privately and contains one row per student with one column per allocated canonical subject. Individual report-card workbooks remain separate; approving one links only that student’s official output.</p>
    <div className="mt-3 space-y-4">{items.map(item => {
      const saving=finalizingId===item.id, disabled=busy||finalizingId!==null;
      return <article key={item.id} data-testid="batch-review-item" data-student-id={item.id} className="rounded-xl border p-3">
        <div className="flex flex-wrap items-center justify-between gap-2"><div><b>{item.label}</b><p className="text-xs text-muted">{item.payload.preview.length} preview cells · {item.payload.meta.formulaCalculation?.formulaCount||0} calculated formulas</p></div>
        <div className="flex gap-2"><button type="button" disabled={disabled} aria-label={`Approve and finalize ${item.label}`} onClick={()=>onApprove(item)} className="rounded-lg bg-emerald-700 px-3 py-2 text-sm font-semibold text-white disabled:opacity-50">{saving?"Saving review…":"Approve and finalize"}</button>
        <button type="button" disabled={disabled} aria-label={`Reject ${item.label}`} onClick={()=>onReject(item)} className="rounded-lg border px-3 py-2 text-sm font-semibold disabled:opacity-50">{saving?"Saving review…":"Reject"}</button></div></div>
        <details className="mt-3"><summary className="cursor-pointer text-sm font-semibold">Inspect populated workbook preview</summary><div className="mt-3 grid grid-cols-2 gap-2">{item.payload.preview.map(row=><div key={row.cell} className="min-w-0 rounded-lg border p-2 text-xs"><b>{row.cell}</b><p className="break-words">{row.formula?"Calculated · "+row.value:row.value}</p></div>)}</div></details>
      </article>;
    })}</div>
  </section>;
}
