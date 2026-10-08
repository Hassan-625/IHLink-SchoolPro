/** Keep service diagnostics out of customer messages while retaining useful validation. */
export function customerMessage(value:unknown,fallback='This action could not be completed. Please try again or contact support.'){
 const message=typeof value==='string'?value:value instanceof Error?value.message:'';
 if(!message||message.length>250||/supabase|edge.?function|postgres|sqlstate|schema|relation|constraint|row.level|\brpc\b|\bjwt\b|datastation|cashsub|legitdataway|routing|\bprovider\b|\bstack\b|https?:\/\/|fetch|cors|storage|signed.?url|service.role|endpoint|public\.|[a-z]+_[a-z]+/i.test(message))return fallback;
 return message;
}
