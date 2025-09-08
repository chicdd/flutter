const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors()); // Flutter에서 접근 허용
app.use(express.json());

// 🔧 MSSQL 연결 설정
const config = {
  user: 'neo',
  password: 'neo01579#',
  server: '112.219.138.170:41433', // or '192.168.0.1'
  database: '원식TEST',
  options: {
    encrypt: false, // true for Azure
    trustServerCertificate: true, // local dev 환경에서 필요
  }
};

// 🔌 DB 연결 테스트
sql.connect(config).then(pool => {
  if (pool.connected) {
    console.log('✅ MSSQL 연결 성공');
  }
}).catch(err => {
  console.error('❌ DB 연결 실패:', err);
});

// 📘 예시 API: 사용자 목록 조회
app.get('/users', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const result = await pool.request().query('SELECT * FROM Users');
    res.json(result.recordset); // Flutter에서 쉽게 파싱할 수 있도록 JSON 반환
  } catch (err) {
    console.error(err);
    res.status(500).send('서버 오류');
  }
});

app.listen(port, () => {
  console.log(`🚀 서버 실행 중: http://localhost:${port}`);
});