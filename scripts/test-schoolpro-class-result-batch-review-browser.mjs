import { chromium } from "playwright";
import { spawn } from "node:child_process";
import { writeFile, rm } from "node:fs/promises";
import assert from "node:assert/strict";

const port = 5207;
const html = '<html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="root"></div><script type="module" src="/batch-review-qa.tsx"></script></body></html>';
const harness = `import React from "react";
import { createRoot } from "react-dom/client";
import { SchoolProClassResultBatchReview } from "./src/components/schoolpro/SchoolProClassResultBatchReview";
import "./src/index.css";
const items = [
 { id:"student-a", label:"Amina Example", payload:{ workbook:new Blob(), meta:{formulaCalculation:{formulaCount:3}}, preview:[{cell:"A1",value:"Amina Example",formula:false},{cell:"G10",value:"150",formula:true}] } },
 { id:"student-b", label:"Bala Example", payload:{ workbook:new Blob(), meta:{formulaCalculation:{formulaCount:2}}, preview:[{cell:"A1",value:"Bala Example",formula:false}] } }
];
const actions:string[]=[];
(window as any).__batchReviewActions=actions;
createRoot(document.getElementById("root")!).render(<SchoolProClassResultBatchReview items={items} busy={new URLSearchParams(location.search).get("busy")==="1"} finalizingId={null} onApprove={item=>actions.push("approve:"+item.id)} onReject={item=>actions.push("reject:"+item.id)}/>);
`;
let server;
let browser;
try {
 await writeFile("batch-review-qa.html", html);
 await writeFile("batch-review-qa.tsx", harness);
 server = spawn("node", ["node_modules/vite/bin/vite.js", "--host", "127.0.0.1", "--port", String(port)], { stdio: "ignore" });
 let ready = false;
 for (let i=0;i<100;i++) {
   try { if ((await fetch(`http://127.0.0.1:${port}/batch-review-qa.html`)).ok) { ready=true; break; } } catch {}
   await new Promise(resolve=>setTimeout(resolve,100));
 }
 assert(ready, "Vite QA harness did not start");
 browser = await chromium.launch({headless:true});
 const page = await browser.newPage();
 await page.goto(`http://127.0.0.1:${port}/batch-review-qa.html`);
 await page.getByRole("heading",{name:"Review each student workbook before finalizing"}).waitFor();
 assert.equal(await page.getByTestId("batch-review-item").count(),2);
 await page.getByText("3 calculated formulas",{exact:false}).waitFor();
 await page.getByText("Inspect populated workbook preview").first().click();
 await page.getByText("Calculated · 150",{exact:true}).waitFor();
 await page.getByRole("button",{name:"Approve and finalize Amina Example"}).click();
 await page.getByRole("button",{name:"Reject Bala Example"}).click();
 const actions = await page.evaluate(()=>window.__batchReviewActions);
 assert.deepEqual(actions,["approve:student-a","reject:student-b"]);
 await page.goto(`http://127.0.0.1:${port}/batch-review-qa.html?busy=1`);
 await page.getByRole("heading",{name:"Review each student workbook before finalizing"}).waitFor();
 assert.equal(await page.getByRole("button",{name:"Approve and finalize Amina Example"}).isDisabled(),true);
 assert.equal(await page.getByRole("button",{name:"Reject Bala Example"}).isDisabled(),true);
 console.log("PASS: batch review queue renders per-student previews, approval/rejection actions and busy-state guards.");
} finally {
 await browser?.close();
 server?.kill();
 await rm("batch-review-qa.html",{force:true});
 await rm("batch-review-qa.tsx",{force:true});
}
