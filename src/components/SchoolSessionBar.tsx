import {useSchoolSession} from '@/hooks/useSchoolSession';
import {AcademicPeriodSelect} from '@/components/AcademicPeriodSelect';

export function SchoolSessionBar(){
  const {session}=useSchoolSession();
  return <section className="mb-4 rounded-xl border p-3 print:hidden">
    <AcademicPeriodSelect kind="session" value={session} label="Working academic session" placeholder="Choose a session before continuing" />
    <p className="mt-1 text-xs">Records and reports retain the session in which they were saved. Selecting a different session changes the working view only; it does not promote students or move enrolments.</p>
  </section>;
}
