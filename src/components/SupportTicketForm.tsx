import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/context/AuthContext";
import { supabase } from "@/lib/supabase";

type SupportProduct =
  | "corporate"
  | "datasub"
  | "schoolpro"
  | "consult"
  | "host"
  | "engineering"
  | "account";

export function SupportTicketForm({
  product,
  accentClass = "bg-royal-600 hover:bg-royal-700",
}: {
  product: SupportProduct;
  accentClass?: string;
}) {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    subject: "",
    category: "general",
    priority: "normal",
    message: "",
  });
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const field =
    "w-full rounded-xl border border-border bg-white px-3 py-2.5 text-sm outline-none focus:border-royal-500";

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!user) {
      navigate("/signin", { state: { from: window.location.pathname } });
      return;
    }
    if (!supabase) return;
    setBusy(true);
    setNotice("");
    const { data, error } = await supabase
      .from("support_tickets")
      .insert({ ...form, product, user_id: user.id })
      .select("ticket_number")
      .single();
    setBusy(false);
    if (error) setNotice(error.message);
    else {
      setNotice(`Ticket ${data.ticket_number} was created successfully.`);
      setForm({
        subject: "",
        category: "general",
        priority: "normal",
        message: "",
      });
    }
  }

  return (
    <form onSubmit={submit} className="space-y-3">
      {notice && (
        <div className="rounded-xl border bg-slate-50 p-3 text-sm">
          {notice}
        </div>
      )}
      <label className="block text-sm font-bold">
        Subject
        <input
          required
          className={`${field} mt-2`}
          value={form.subject}
          onChange={(event) =>
            setForm({ ...form, subject: event.target.value })
          }
          placeholder="Brief description"
        />
      </label>
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="block text-sm font-bold">
          Category
          <select
            className={`${field} mt-2`}
            value={form.category}
            onChange={(event) =>
              setForm({ ...form, category: event.target.value })
            }
          >
            <option value="general">General support</option>
            <option value="account">Account & access</option>
            <option value="billing">Billing & payment</option>
            <option value="technical">Technical issue</option>
            <option value="service">Service request</option>
          </select>
        </label>
        <label className="block text-sm font-bold">
          Priority
          <select
            className={`${field} mt-2`}
            value={form.priority}
            onChange={(event) =>
              setForm({ ...form, priority: event.target.value })
            }
          >
            <option value="low">Low</option>
            <option value="normal">Normal</option>
            <option value="high">High</option>
            <option value="urgent">Urgent</option>
          </select>
        </label>
      </div>
      <label className="block text-sm font-bold">
        Message
        <textarea
          required
          rows={4}
          className={`${field} mt-2 resize-y`}
          value={form.message}
          onChange={(event) =>
            setForm({ ...form, message: event.target.value })
          }
          placeholder="Describe the issue, what you expected, and any error shown"
        />
      </label>
      <Button type="submit" fullWidth disabled={busy} themeClass={accentClass}>
        {busy
          ? "Creating ticket…"
          : user
            ? "Create Support Ticket"
            : "Sign In to Create Ticket"}
      </Button>
    </form>
  );
}
