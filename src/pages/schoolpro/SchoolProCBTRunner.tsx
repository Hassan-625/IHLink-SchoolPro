import {customerMessage} from '@/lib/customerMessage';
import { useEffect, useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/lib/supabase";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export function SchoolProCBTRunner() {
  const { testId } = useParams();
  const [data, setData] = useState<any>(null);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);
  const [clock, setClock] = useState(Date.now());
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!supabase || !testId) return;
    void (async () => {
      setLoading(true);
      const result = await supabase.rpc("start_schoolpro_cbt", { p_test: testId });
      if (result.error) setMessage(customerMessage(result.error.message));
      else {
        setData(result.data);
        setAnswers((result.data as any)?.answers || {});
      }
      setLoading(false);
    })();
  }, [testId]);

  useEffect(() => {
    const timer = window.setInterval(() => setClock(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  const remaining = data?.expires_at
    ? Math.max(0, Math.floor((new Date(data.expires_at).getTime() - clock) / 1000))
    : 0;

  const questions = useMemo(() => {
    const source = Array.isArray(data?.questions) ? data.questions : [];
    return source.map((question: any) => {
      const options = Array.isArray(question.options) ? [...question.options] : [];
      if (data?.test?.randomize_options) options.sort(() => Math.random() - 0.5);
      return { ...question, displayOptions: options };
    });
  }, [data]);

  async function saveAnswer(questionId: string, value: string) {
    setAnswers((current) => ({ ...current, [questionId]: value }));
    if (!supabase || !data?.attempt_id) return;
    const result = await supabase.rpc("save_schoolpro_cbt_answer", {
      p_attempt: data.attempt_id,
      p_question: questionId,
      p_answer: value,
    });
    if (result.error) setMessage(customerMessage("Answer save failed: " + result.error.message));
  }

  async function submit(auto = false) {
    if (!supabase || !data?.attempt_id || submitting || data?.submitted) return;
    setSubmitting(true);
    const result = await supabase.rpc("submit_schoolpro_cbt", { p_attempt: data.attempt_id });
    if (result.error) {
      setMessage(customerMessage(result.error.message));
      setSubmitting(false);
      return;
    }
    const response = result.data as any;
    const summary = response?.theory_pending
      ? `Submitted. Objective score: ${response.objective_score} / ${response.total_marks}. Theory answers are awaiting teacher marking.`
      : `Submitted successfully. Score: ${response?.objective_score ?? response?.score ?? 0} / ${response?.total_marks ?? data.test?.total_marks ?? 0}.`;
    setMessage(auto ? "Time expired. " + summary : summary);
    setData((current: any) => ({ ...current, submitted: true }));
    setSubmitting(false);
  }

  useEffect(() => {
    if (data?.attempt_id && remaining === 0 && !submitting && !data?.submitted) void submit(true);
  }, [remaining, data?.attempt_id, data?.submitted, submitting]);

  if (loading) return <main className="min-h-screen grid place-items-center">Preparing secure CBT attempt…</main>;
  if (!data) return <main className="min-h-screen grid place-items-center p-6"><Card><h1 className="text-xl font-bold">CBT unavailable</h1><p className="mt-2">{message || "You cannot start this test."}</p></Card></main>;

  return (
    <main className="min-h-screen bg-background p-4 md:p-10">
      <div className="mx-auto max-w-4xl">
        <div className="sticky top-0 z-10 rounded-xl border bg-background/95 p-4 backdrop-blur">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div><h1 className="text-3xl font-black">{data.test?.title || "CBT Examination"}</h1><p className="text-sm text-muted">Attempt {data.attempt_no}</p></div>
            <div className="text-right"><p className="text-xs text-muted">Time remaining</p><p className="text-2xl font-black">{String(Math.floor(remaining / 60)).padStart(2, "0")}:{String(remaining % 60).padStart(2, "0")}</p></div>
          </div>
        </div>
        <p className="mt-4 text-muted">{data.test?.instructions || "Answer all applicable questions before submitting."}</p>
        <div className="mt-6 space-y-4">
          {questions.map((question: any, index: number) => (
            <Card key={question.id}>
              <p className="font-bold">{index + 1}. {question.question_text} <span className="text-xs text-muted">({question.marks} mark{Number(question.marks) === 1 ? "" : "s"})</span></p>
              {question.displayOptions.length ? (
                <div className="mt-3 space-y-2">{question.displayOptions.map((option: any) => <label key={String(option)} className="flex gap-2"><input type="radio" name={question.id} value={String(option)} checked={answers[question.id] === String(option)} onChange={(event) => void saveAnswer(question.id, event.target.value)} />{String(option)}</label>)}</div>
              ) : (
                <textarea value={answers[question.id] || ""} onChange={(event) => setAnswers((current) => ({ ...current, [question.id]: event.target.value }))} onBlur={(event) => void saveAnswer(question.id, event.target.value)} className="mt-3 min-h-24 w-full rounded-lg border p-3" placeholder="Your answer" />
              )}
            </Card>
          ))}
        </div>
        <Button className="mt-5" disabled={submitting || data.submitted || remaining === 0} onClick={() => void submit(false)}>{submitting ? "Submitting…" : data.submitted ? "Submitted" : "Submit Test"}</Button>
        {message && <p className="mt-4 font-semibold">{message}</p>}
      </div>
    </main>
  );
}
