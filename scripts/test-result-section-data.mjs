import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import ts from 'typescript';
async function module(path){let source=await readFile(path,'utf8');if(path.endsWith('resultTemplateProfiles.ts'))source=source.replace(/^export \\{ unsupportedWorkbookFormula \} from [\"'][^\"']+[\"'];\\s*$/m,'');const code=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;return import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));}
const {resolveResultSectionTemplate,keepResultSectionTemplate}=await module('src/lib/resultSectionTemplates.ts');
const base={id:'private-row',school_id:'only-this-school',storage_path:'school/default.xlsx',component_columns:{exam:'E',__section_templates:{nursery:{storage_path:'school/nursery.xlsx',component_columns:{exam:'F'}},primary:{storage_path:'school/primary.xlsx',component_columns:{exam:'G'}}}}};
assert.equal(resolveResultSectionTemplate(base,'nursery').storage_path,'school/nursery.xlsx');
assert.equal(resolveResultSectionTemplate(base,'primary').component_columns.exam,'G');
assert.equal(resolveResultSectionTemplate(base,'junior_secondary').storage_path,'school/default.xlsx');
const updated={...base,component_columns:keepResultSectionTemplate(base,'senior_secondary',{id:'different',school_id:'different-school',storage_path:'school/senior.xlsx',component_columns:{exam:'H',__section_templates:{invalid:{}}}})};
assert.equal(resolveResultSectionTemplate(updated,'primary').storage_path,'school/primary.xlsx');
assert.equal(resolveResultSectionTemplate(updated,'senior_secondary').school_id,'only-this-school');
assert.equal(updated.component_columns.__section_templates.senior_secondary.id,undefined);
assert.equal(updated.component_columns.__section_templates.senior_secondary.component_columns.__section_templates,undefined);
assert.equal(base.component_columns.__section_templates.senior_secondary,undefined);
const {fetchSchoolRows}=await module('src/lib/schoolDataPaging.ts');
const pupils=Array.from({length:1120},(_,i)=>({id:i}));let ranges=[];
const query={range:async(start,end)=>{ranges.push([start,end]);return {data:pupils.slice(start,end+1),error:null};}};
const roster=await fetchSchoolRows(query);assert.equal(roster.data.length,1120);assert.equal(new Set(roster.data.map(x=>x.id)).size,1120);assert.deepEqual(ranges,[[0,499],[500,999],[1000,1499]]);
const failure=await fetchSchoolRows({range:async(start)=>start?{data:null,error:{message:'Request failed'}}:{data:pupils.slice(0,500),error:null}});assert.deepEqual(failure.data,[]);assert(failure.error);
console.log('PASS: distinct section designs, school identity retained, independent saves, full 1,120-pupil paging and failures cannot masquerade as complete rosters.');

const {normalizeResultSection}=await module('src/lib/resultSectionTemplates.ts');
for(const [label,expected] of [
 ['Nursery 2','nursery'],['KG 1','nursery'],['Pre-primary','nursery'],
 ['Primary 4','primary'],['Basic 6','primary'],['JSS 2','junior_secondary'],
 ['Junior Secondary 3','junior_secondary'],['SSS 1','senior_secondary'],
 ['Senior Secondary 2','senior_secondary'],['Unknown','all']
])assert.equal(normalizeResultSection(label),expected,`section normalization for ${label}`);
const {resultTemplateProfile,assessmentMaximumForResults,sumResultTotals}=await module('src/lib/resultTemplateProfiles.ts');
for(const [section,label] of [
 ['nursery','Nursery report'],['primary','Primary report'],
 ['junior_secondary','Junior secondary report'],['senior_secondary','Senior secondary report']
]){
 const profile=resultTemplateProfile(section);
 assert.equal(profile.name,label);
 assert.equal(profile.component_columns.__layout.section,section);
 assert.equal(profile.columns.subject,'B');
 assert.equal(profile.columns.total,'G');
}
assert.equal(assessmentMaximumForResults([{assessment_scheme_id:'a'},{assessment_scheme_id:'b'}],[
 {id:'a',components:[{maxScore:20},{maxScore:'30'}]},
 {id:'b',components:[{maxScore:50}]}
]),100);
assert.equal(assessmentMaximumForResults([],[]),null);
assert.equal(assessmentMaximumForResults([{assessment_scheme_id:'missing'}],[]),null);
assert.equal(assessmentMaximumForResults([{assessment_scheme_id:'a'}],[{id:'a',components:[{maxScore:0}]}]),null);
assert.equal(sumResultTotals([{total_score:35},{total_score:'45'}]),80);
assert.equal(sumResultTotals([]),null);
assert.equal(sumResultTotals([{total_score:'invalid'}]),null);
console.log('PASS: canonical section labels, four section profiles, scheme-aware maximum validation and safe term-total aggregation.');
