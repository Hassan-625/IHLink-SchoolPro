import {MobileBrandPreview} from './MobileBrandPreview';
import {useState} from 'react';
import {Link} from 'react-router-dom';
import {ArrowRight} from 'lucide-react';
const slides=[{"image": "/mobile/school-community.webp", "title": "Your school, in your pocket", "description": "Bring your school community together."}, {"image": "/mobile/school-results.webp", "title": "Less paperwork. More teaching.", "description": "Classes and results, organised in one place."}, {"image": "/mobile/school-family.webp", "title": "Keep families in the loop", "description": "School-linked access for parents and students."}];
export function NativeSignedOutHome(){
 const [index,setIndex]=useState(0);const slide=slides[index];
 return <main className="welcome-screen schoolpro"><header className="welcome-brand"><img src="/brand/schoolpro-icon.png" alt=""/><span>IHLink SchoolPro</span></header><div className="welcome-progress" aria-label="Welcome slides">{slides.map((item,i)=><button key={item.image} type="button" aria-label={`Welcome slide ${i+1}`} aria-current={index===i?'step':undefined} onClick={()=>setIndex(i)}><span className={i<=index?'shown':''}/></button>)}</div><button type="button" className="welcome-art" aria-label="Next welcome slide" onClick={()=>setIndex((index+1)%slides.length)}><img src={slide.image} alt="" loading="eager"/><MobileBrandPreview kind={index}/></button><section className="welcome-copy" aria-live="polite"><p className="welcome-eyebrow">Welcome to SchoolPro</p><h1>{slide.title}</h1><p>{slide.description}</p></section><section className="welcome-actions"><Link className="welcome-primary" to="/schoolpro/register">Register your school<ArrowRight size={18}/></Link><Link className="welcome-secondary" to="/schoolpro/login">Sign in</Link></section></main>;
}
