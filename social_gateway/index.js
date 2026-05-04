// index.js
require('dotenv').config();
const express = require('express');
const TelegramBot = require('node-telegram-bot-api');
const axios = require('axios');
const xml2js = require('xml2js');
const crypto = require('crypto');

const app = express();
app.use(express.json());
app.use('/webhook/wechat', express.text({ type: 'text/xml' }));

// --- ⚙️ 設定檔載入 ---
const TELEGRAM_TOKEN = process.env.TELEGRAM_TOKEN;
const LOCAL_API_URL = process.env.LOCAL_API_URL || 'http://127.0.0.1:8080';
const AI_LIB_TOKEN = process.env.AI_LIB_TOKEN;
const PORT = process.env.PORT || 3001;

// --- 🤖 與本地 AI 伺服器溝通的函式 ---
async function askLocalAI(query, docName = null) {
    try {
        const headers = { 'Content-Type': 'application/json' };
        if (AI_LIB_TOKEN && AI_LIB_TOKEN.trim() !== '') {
            headers['Authorization'] = `Bearer ${AI_LIB_TOKEN}`;
        }
        const payload = { query };
        if (docName) payload.docName = docName;

        const response = await axios.post(`${LOCAL_API_URL}/query`, payload, { headers });
        return response.data; // { answer: "...", citations: [...] }
    } catch (error) {
        console.error('[API 請求錯誤]', error.message);
        throw new Error('無法連接到本地 AI 大腦。');
    }
}

// ==========================================
// 🚀 Telegram 模組初始化 (Polling)
// ==========================================
if (TELEGRAM_TOKEN && TELEGRAM_TOKEN !== 'your_telegram_bot_token_here') {
    const telegramBot = new TelegramBot(TELEGRAM_TOKEN, { polling: true });
    console.log('✅ [Social Gateway] Telegram 模組已啟動 (Polling 模式)');

    telegramBot.on('message', async (msg) => {
        const chatId = msg.chat.id;
        const text = msg.text;
        const username = msg.from.username || msg.from.first_name || 'User';

        if (!text) return;
        console.log(`[接收] Telegram (@${username}): ${text}`);
        telegramBot.sendChatAction(chatId, 'typing');

        try {
            const aiResponse = await askLocalAI(text);
            let replyMessage = aiResponse.answer;
            if (aiResponse.citations && aiResponse.citations.length > 0) {
                replyMessage += '\n\n--- 參考來源 ---\n';
                aiResponse.citations.forEach((c, i) => replyMessage += `[${i + 1}] ${c.doc}\n`);
            }
            telegramBot.sendMessage(chatId, replyMessage);
            console.log(`[回覆] Telegram (@${username}): 成功發送回覆。`);
        } catch (error) {
            telegramBot.sendMessage(chatId, `⚠️ 發生錯誤：${error.message}`);
        }
    });
} else {
    console.log('⚠️ [Social Gateway] TELEGRAM_TOKEN 未設定，已略過 Telegram 啟動。');
}

// ==========================================
// 🟩 WhatsApp Cloud API (Webhook)
// ==========================================
app.get('/webhook/whatsapp', (req, res) => {
    const verify_token = process.env.WHATSAPP_VERIFY_TOKEN;
    const mode = req.query["hub.mode"];
    const token = req.query["hub.verify_token"];
    const challenge = req.query["hub.challenge"];

    if (mode && token && mode === "subscribe" && token === verify_token) {
        console.log('✅ [Social Gateway] WhatsApp Webhook 驗證成功');
        res.status(200).send(challenge);
    } else {
        res.sendStatus(403);
    }
});

app.post('/webhook/whatsapp', async (req, res) => {
    // 立即回傳 200 OK 避免 Meta 重新發送請求
    res.sendStatus(200);

    const body = req.body;
    if (body.object && body.entry && body.entry[0].changes && body.entry[0].changes[0].value.messages && body.entry[0].changes[0].value.messages[0]) {
        const phone_number_id = body.entry[0].changes[0].value.metadata.phone_number_id;
        const from = body.entry[0].changes[0].value.messages[0].from; 
        const msg_body = body.entry[0].changes[0].value.messages[0].text?.body;

        if (!msg_body) return;

        console.log(`[接收] WhatsApp (${from}): ${msg_body}`);

        try {
            const aiResponse = await askLocalAI(msg_body);
            const replyMessage = aiResponse.answer;
            
            await axios({
                method: "POST",
                url: `https://graph.facebook.com/v17.0/${phone_number_id}/messages?access_token=${process.env.WHATSAPP_TOKEN}`,
                data: {
                    messaging_product: "whatsapp",
                    to: from,
                    text: { body: replyMessage },
                },
                headers: { "Content-Type": "application/json" },
            });
            console.log(`[回覆] WhatsApp (${from}): 成功發送回覆。`);
        } catch (err) {
            console.error("❌ WhatsApp 發送錯誤:", err.message);
        }
    }
});

// ==========================================
// 💬 WeChat 公眾號 (Webhook)
// ==========================================
app.get('/webhook/wechat', (req, res) => {
    const { signature, timestamp, nonce, echostr } = req.query;
    const token = process.env.WECHAT_TOKEN;
    if (!token) return res.send('error');

    const tmpArr = [token, timestamp, nonce].sort();
    const hash = crypto.createHash('sha1').update(tmpArr.join('')).digest('hex');

    if (hash === signature) {
        console.log('✅ [Social Gateway] WeChat Webhook 驗證成功');
        res.send(echostr);
    } else {
        res.send('error');
    }
});

app.post('/webhook/wechat', async (req, res) => {
    const xmlStr = req.body;
    if (!xmlStr) return res.send('success');

    try {
        const result = await xml2js.parseStringPromise(xmlStr, { explicitArray: false });
        const message = result.xml;
        
        if (message.MsgType !== 'text') {
            return res.send('success');
        }

        const fromUser = message.FromUserName;
        const toUser = message.ToUserName;
        const content = message.Content;

        console.log(`[接收] WeChat (${fromUser}): ${content}`);

        // 注意：這段呼叫若超過 5 秒，WeChat 伺服器會將其判定為逾時並斷開連線
        const aiResponse = await askLocalAI(content);
        const replyText = aiResponse.answer;

        const replyXml = `
            <xml>
                <ToUserName><![CDATA[${fromUser}]]></ToUserName>
                <FromUserName><![CDATA[${toUser}]]></FromUserName>
                <CreateTime>${Math.floor(Date.now() / 1000)}</CreateTime>
                <MsgType><![CDATA[text]]></MsgType>
                <Content><![CDATA[${replyText}]]></Content>
            </xml>
        `;
        
        res.set('Content-Type', 'text/xml');
        res.send(replyXml.trim());
        console.log(`[回覆] WeChat (${fromUser}): 成功發送 XML 回覆。`);

    } catch (err) {
        console.error("❌ WeChat 處理錯誤:", err.message);
        res.send('success');
    }
});

// 啟動伺服器
app.listen(PORT, () => {
    console.log(`🚀 [Social Gateway] Node.js Webhook 伺服器運行於 port ${PORT}`);
});
