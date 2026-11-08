export const providers={openai:{label:'OpenAI',model:'gpt-4.1-mini'},groq:{label:'Groq',model:'llama-3.3-70b-versatile'},openrouter:{label:'OpenRouter',model:'openai/gpt-4.1-mini'}};
export type LlmConnection={provider:keyof typeof providers;model:string;apiKey:string;enabled:boolean};
export const emptyLlm:LlmConnection={provider:'openai',model:'gpt-4.1-mini',apiKey:'',enabled:false};
