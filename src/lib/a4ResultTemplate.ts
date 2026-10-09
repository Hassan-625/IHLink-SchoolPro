export function prepareA4ResultSheet(sheet:any,template:any,resultCount:number){
 const a4=template.component_columns?.__a4;if(!a4)return;
 const first=Number(template.start_row),last=Number(a4.last_subject_row);
 if(!Number.isInteger(first)||!Number.isInteger(last)||last<first)throw new Error('Choose a valid result design.');
 if(resultCount<1)throw new Error('No published results are available for this student, term and session.');
 if(resultCount>last-first+1)throw new Error('This result design needs more subject rows. Extend the workbook and its mappings before generating.');
 for(let row=first;row<=last;row++)for(const column of ['A','C','D','E','F','G','I','J','M','N'])sheet.getCell(column+row).master.value=null;
 sheet.pageSetup={...sheet.pageSetup,paperSize:9,orientation:'portrait',fitToPage:true,fitToWidth:1,fitToHeight:1};
}
