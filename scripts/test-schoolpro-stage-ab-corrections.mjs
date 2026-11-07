import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const read=path=>readFile(path,'utf8');
const [register,access,shared,app,pricing,subscription,sharedPlanFeatures,games,migration,dashboard,schoolPermissions,sidebar]=await Promise.all([
 read('src/pages/schoolpro/SchoolProRegister.tsx'),
 read('src/lib/schoolAccess.ts'),
 read('src/pages/schoolpro/schoolShared.tsx'),
 read('src/App.tsx'),
 read('src/pages/schoolpro/SchoolProPricing.tsx'),
 read('src/pages/schoolpro/SchoolProSubscription.tsx'),
 read('src/lib/schoolProPlanFeatures.ts'),
 read('src/pages/schoolpro/SchoolProGames.tsx'),
 read('supabase/migrations/20261104150000_schoolpro_stage_ab_dashboard_and_report_entitlement_corrections.sql'),
 read('src/pages/schoolpro/SchoolProLiveDashboard.tsx'),
 read('src/lib/schoolPermissions.ts'),
 read('src/components/Sidebar.tsx')
]);

assert(register.includes("'Games & Sports'"),'School registration must offer Games & Sports');
assert(register.includes('value="starter"')&&register.includes('value="professional"')&&register.includes('value="enterprise"'),'Registration must allow a preferred public plan');
assert(register.includes('form.plan_key'),'Selected plan must be submitted with the onboarding request');
assert(access.includes("case 'game_master':return '/schoolpro/games';"),'Game Master must land on the Games dashboard');
assert(access.includes("case 'discipline_master':case 'counsellor':return '/schoolpro/discipline';"),'Discipline specialists must land on their authorized workspace');
assert(access.includes("case 'bursar':case 'accountant':return '/schoolpro/fees';")&&access.includes("case 'exam_officer':return '/schoolpro/results';")&&access.includes("case 'registrar':return '/schoolpro/students';"),'Finance, examination and registrar roles must land on their authorized workspace');
assert(schoolPermissions.includes("'judge':'dashboard'"),'Assigned judges must see their judging portal link through the staff navigation permission filter');
assert(schoolPermissions.includes("const features:Record<string,string>={cbt:'cbt',branding:'custom_branding'};")&&!schoolPermissions.includes("reports:'advanced_reports'"),'Standard report permission must not require the Enterprise advanced_reports entitlement');
assert(shared.includes("href:'/schoolpro/subscription'"),'School billing managers must have a Plans & Subscription navigation entry');
assert.match(sidebar,/if\(item\.href===['"]\/schoolpro\/subscription['"]\)return \['proprietor','administrator','bursar','super_administrator'\]\.includes\(role\)/,'Plans & Subscription navigation must be limited to authorized billing managers.');
assert(shared.includes("label:'Houses, Games & Competitions',href:'/schoolpro/games'"),'School management navigation must expose Games');
assert(shared.includes("label:'My Judging Panel',href:'/schoolpro/judge'"),'Teacher navigation must expose assigned judging panel');
assert(app.includes('<Route path="/schoolpro/games" element={<Guard permission="games"><SchoolProGames/></Guard>}/>'),'Games route must retain its role/permission guard');
assert(app.includes('<Route path="/schoolpro/broadsheet" element={<Guard permission="reports"><SchoolProBroadsheet/></Guard>}/>'),'Standard broadsheet must not be wrapped in the Enterprise advanced-reports gate');
assert(app.includes('<Route path="/schoolpro/reports" element={<Guard><SchoolProEntitlementGate feature="advanced_reports">'),'Advanced reports must remain Enterprise-gated');
assert(pricing.includes("from('schoolpro_plan_catalog')")&&pricing.includes('annual_price')&&!pricing.includes('monthly_price')&&!pricing.includes('termly_price'),'Pricing must combine authoritative entitlements with the currently supported annual billing cycle');
assert(pricing.includes('schoolProPlanFeatures(flags)')&&sharedPlanFeatures.includes('Houses, Games, Sports and Competitions'),'Public plan comparison must use the shared plan-feature definitions, including Games on every tier');
assert(subscription.includes('schoolProPlanFeatures(p.planFeatures||{})')&&sharedPlanFeatures.includes('Houses, Games, Sports and Competitions'),'Subscription view must use the shared plan-feature definitions, including Games');
assert(games.includes('House Masters')&&games.includes('Inter-house standings')&&games.includes('Staff judging panel'),'Games management must retain houses, judges and standings');
assert(dashboard.includes("access.can('finance')")&&dashboard.includes('canViewFinance&&')&&dashboard.includes('canReadFinance?'),'Generic role dashboard must load and display financial data only for roles with finance permission');
assert(dashboard.includes("access.can('students')")&&dashboard.includes('canReadStudents?'),'Generic role dashboard must only query student records for roles with student permission');
assert(migration.includes("jsonb_build_object('games', true)"),'Migration must enable Games on every public/legacy plan');
assert(migration.includes("when 'games' then private.schoolpro_plan_feature_allowed(target_school, 'games')"),'Games must be checked against plan entitlement and role permission');
assert(migration.includes("needle text := $needle$'discipline','medical'$needle$"),'Migration must add Games to leadership permission arrays');
assert(!migration.includes("when 'reports' then private.schoolpro_plan_feature_allowed"),'Standard reports permission must not be tied to Enterprise Advanced Reports');
assert(migration.includes("'advanced_reports'"),'Advanced Reports entitlement must remain a separate plan feature');

console.log('PASS: Stage A-B registration, Games/Sports plan access, Game Master landing, judge navigation, standard-vs-advanced report gates and plan catalogue wiring.');
