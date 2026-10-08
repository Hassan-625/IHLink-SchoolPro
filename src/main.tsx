import {NativeSessionGate} from '@/components/NativeSessionGate';
import {NativeMobileShell} from '@/components/NativeMobileShell';
import{AccountClosureControl}from'@/components/AccountClosureControl';
import { Component, StrictMode, type ErrorInfo, type ReactNode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { AuthProvider } from "@/context/AuthContext";
import { enforceDeploymentSurface } from "@/lib/deploymentSurface";
import { ToastProvider } from "@/components/ui/Toast";
import "./index.css";

class StartupErrorBoundary extends Component<{children:ReactNode},{error:Error|null}> {
  state={error:null as Error|null};
  static getDerivedStateFromError(error:Error){return{error};}
  componentDidCatch(error:Error,info:ErrorInfo){console.error("IHLink SchoolPro startup/render error",error,info);}
  render(){if(this.state.error)return <main style={{minHeight:"100vh",padding:32,fontFamily:"system-ui,sans-serif",background:"#fff",color:"#071A3D"}}><h1 style={{fontSize:24,fontWeight:800}}>SchoolPro could not start</h1><p style={{marginTop:12}}>The application encountered a browser-side startup error.</p><pre style={{marginTop:20,padding:16,overflow:"auto",whiteSpace:"pre-wrap",background:"#f1f5f9",borderRadius:12}}>{this.state.error.message}</pre></main>;return this.props.children;}
}
enforceDeploymentSurface();
document.documentElement.dataset.appearance=localStorage.getItem("ihlink-appearance")||"light";
document.documentElement.dataset.density=localStorage.getItem("ihlink-density")||"comfortable";
const root=document.getElementById("root");if(!root)throw new Error("IHLink SchoolPro root element was not found.");
createRoot(root).render(<StrictMode><StartupErrorBoundary><BrowserRouter><NativeSessionGate><AuthProvider><ToastProvider><NativeMobileShell><App/><AccountClosureControl/></NativeMobileShell></ToastProvider></AuthProvider></NativeSessionGate></BrowserRouter></StartupErrorBoundary></StrictMode>);
