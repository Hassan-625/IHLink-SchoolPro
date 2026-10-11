import {schoolSection} from '@/lib/schoolClassFilters';
export async function loadSchoolLessonPage(db:any,schoolId:string,filters:{classId:string;section:string;status:string;term:string;session:string;search:string;page:number},classes:{id:string;name:string;level?:string|null}[]){
 let query=db.from('schoolpro_lesson_notes').select('*',{count:'exact'}).eq('school_id',schoolId);
 if(filters.classId)query=query.eq('class_id',filters.classId);
 else if(filters.section){const ids=classes.filter(c=>schoolSection(c.level,c.name)===filters.section).map(c=>c.id);if(!ids.length)return{data:[],count:0,error:null};query=query.in('class_id',ids);}
 if(filters.status)query=query.eq('status',filters.status);
 if(filters.term)query=query.eq('term',filters.term);
 if(filters.session)query=query.eq('session',filters.session);
 const search=filters.search.trim().replaceAll('%','').replaceAll('_','');if(search)query=query.ilike('title','%'+search+'%');
 return await query.order('lesson_date',{ascending:false}).order('id').range(filters.page*50,filters.page*50+49);
}
