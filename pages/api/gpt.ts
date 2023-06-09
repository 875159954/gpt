// import { fetch,Body,ResponseType } from '@tauri-apps/api/http';
import { NextApiRequest, NextApiResponse } from "next";
import { Messages, Message } from "./Message";

const url = "https://api.openai.com/v1/chat/completions";


const api_key = process.env.GPT_API_KEY

const Model = "gpt-3.5-turbo";
const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${api_key}`,
};

function parseResponse(chunk: string) {
    let subContent = "";
    const dataList = chunk
        .split("\n\n")
        .filter((e) => e)
        .map((e) => e.slice(6));
    for (const data of dataList) {
        if (data == "[DONE]") {
            return subContent;
        }
        const json = JSON.parse(data);
        const text = json["choices"][0]["delta"]["content"];
        if (text) {
            subContent += text;
        }
    }
    return subContent;
}

async function getData(history: Message[]) {
    const data = {
        model: Model,
        messages: history.slice(-7),
        temperature: 0.7,
        stream: true,
    };
    try {
        const response = await fetch(url, {
            method: "POST",
            body: JSON.stringify(data),
            headers: headers,
        });
        return response;
    } catch (e) {
        throw e;
    }
}
export default async function handler(req:NextApiRequest, res:NextApiResponse) {
    if (req.method === 'POST') {
      // Handle the POST request here
        try{
        const response = await getData(req.body.history)
        const body = response.body
        const reader =  await body?.getReader();
        let chunk = "";
        let done, value;
        if(response.status!== 200){
            res.write(`error code: ${response.status}`)
            res.end()
        }
        while (!done) {
            ({ value, done } =
                (await reader?.read()) as ReadableStreamReadResult<Uint8Array>);
            if (done) {
                break;
            }
            const str = new TextDecoder().decode(value);
            chunk += str;
            if (str.endsWith("\n\n")) {
                const tmp =parseResponse(chunk);
                res.write(tmp)
                chunk = "";
            }
        }
        
        res.status(200)
    }
    catch(e){
        console.log(e)
        res.write('server error')
    }
    } else {
      res.status(405).json({ message: 'Method not allowed' })
    }
    res.end()
  }