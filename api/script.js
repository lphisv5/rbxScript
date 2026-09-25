export default async function handler(req, res) {
  const userAgent = req.headers['user-agent'] || '';

  // 1. บล็อกการเข้าถึงจาก Web Browser โดยตรง (แสดงหน้า 403 Forbidden)
  const isRoblox = userAgent.includes('Roblox') || userAgent.includes('RobloxStudio');
  if (!isRoblox) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    return res.status(403).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>403 Forbidden</title>
        <style>
          body { background: #0f0f11; color: #ff4d4d; font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
          .box { border: 1px solid #333; background: #16161a; padding: 30px; border-radius: 12px; text-align: center; }
          h1 { margin: 0 0 10px 0; font-size: 22px; }
          p { color: #888; margin: 0; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="box">
          <h1>403 Forbidden</h1>
          <p>Direct browser access is strictly prohibited.</p>
        </div>
      </body>
      </html>
    `);
  }

  // 2. ดึงค่าจาก Query Parameters
  const key = req.query.key;
  const hwid = req.query.hwid;
  const timestamp = req.query.t;

  // ตรวจสอบว่าส่งข้อมูลมาครบถ้วนหรือไม่
  if (!key || !hwid || !timestamp) {
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.status(400).send('print("Error: Invalid parameters")');
  }

  // 3. ป้องกัน Replay Attack (ลิงก์มีอายุใช้งาน 30 วินาที)
  const currentTime = Math.floor(Date.now() / 1000);
  const reqTime = parseInt(timestamp, 10);
  if (isNaN(reqTime) || Math.abs(currentTime - reqTime) > 30) {
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.status(403).send('print("Error: Request expired")');
  }

  // 4. ตรวจสอบ Key & ล็อก HWID
  // (ตัวอย่างการตรวจสอบแบบ Hardcode — สามารถเปลี่ยนไปดึงค่าจาก Database เช่น Supabase ได้)
  const ALLOWED_KEYS = {
    "VIP-KEY-1234": "HWID_USER_1",
    "DEMO-KEY-9999": hwid // ยอมรับ HWID แรกที่ส่งมา
  };

  if (!ALLOWED_KEYS[key]) {
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.status(401).send('print("Error: Invalid or Expired Key")');
  }

  // 5. ส่วนของโค้ด Lua ที่ต้องการส่งไปรันใน Roblox
  // **ข้อแนะนำสำคัญ:** ควรนำโค้ดในตัวแปร luaPayload นี้ไปผ่าน Obfuscator ก่อนวางจริง
  const luaPayload = `
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Vercel Shield",
        Text = "ยืนยันสิทธิ์สำเร็จ! ยินดีต้อนรับ " .. LocalPlayer.Name,
        Duration = 5
    })
    
    print("[+] Executed successfully for HWID: ${hwid}")
  `;

  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  return res.status(200).send(luaPayload);
}
