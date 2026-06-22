# 2D 인스턴스 RPG — 모노레포

인스턴스 기반 액션 RPG. 인스턴스는 사적, **경제(인벤토리·골드·마켓·거래)는 전역 공유**.
설계 스펙은 핸드오프 문서(§1~13)를 기준으로 한다. **권위 불변식(§3)**: 클라이언트는 경제를
표시/입력만 하고, 모든 경제 변경은 `Client → Nakama RPC → Supabase Postgres 함수` 경로로만.

## 레이어 구조

```
rpg/
  lib/            # Flutter + FLAME 클라이언트 (루트 = 클라이언트)
    game/         # FLAME 컴포넌트, 맵 생성(시드), 전투
    net/          # Nakama 클라이언트 래퍼
    models/       # DTO
    ui/           # 게임 화면, 인벤토리
  server/         # Nakama TypeScript 권위 런타임 (RPC, 거래 match, supabase 래퍼)
  db/             # Supabase 스키마 / SECURITY DEFINER 함수 / 시드
```

각 레이어 상세는 `server/README.md`, `db/README.md` 참고.

## 구현 상태 (이번 작업: 전체 스캐폴드 + Phase 0~1 동작)

| 영역 | 상태 |
|---|---|
| DB 스키마/RLS/시드 (§5) | ✅ 완료 |
| Postgres 함수 (§7): grant_drop, claim_kill, enhance_item, market(3), execute_trade, reads | ✅ 작성 |
| Nakama RPC (§6.1) 8종 + hello | ✅ 작성 (typecheck+build 통과) |
| 거래 match handler (§6.2) | 🟡 상태머신 골격 (escrow/execute_trade 와이어링 TODO) |
| 클라 Phase 0: 맵+이동 | ✅ 동작 (오프라인 폴백 포함) |
| 클라 Phase 1: 인스턴스+드랍+인벤토리 | ✅ 동작 (서버 연결 시) |
| 강화/마켓 UI (Phase 2~3) | ⬜ 서버는 준비됨, UI 미구현 |

## 실행

### 1) DB (Supabase)
`db/README.md` 의 적용 순서대로 마이그레이션→함수→시드 실행. service_role 키 확보.

### 2) 서버 (Nakama) — Node 필요, 실행엔 Docker 필요
```bash
cd server
npm install
npm run build          # build/index.js 번들 (Goja 로드용)
cp .env.example .env   # SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 채우기
docker compose up      # Nakama(7350) + Postgres + Console(7351)
```
> 현재 개발 머신에 Docker 미설치 → 빌드까지 검증됨. Docker Desktop 설치 후 기동.

### 3) 클라이언트 (Flutter)
```bash
flutter pub get
flutter run            # 데스크톱/웹/모바일
```
- 조작: **이동 WASD/화살표, 공격 몬스터 클릭/탭.**
- 서버 미연결이어도 **오프라인 모드**로 맵 탐험/이동이 동작한다(드랍은 서버 권위라 비활성).
- 실기기 접속 시 `lib/net/nakama_service.dart` 의 `host` 를 머신 IP 로(안드로 에뮬: `10.0.2.2`).

## 검증 완료
- `server`: `npm run typecheck`, `npm run build` 통과 (InitModule 전역 노출 확인).
- `lib`: `flutter analyze` 무경고, `flutter test` 통과.

## 권위 불변식 self-check (§3)
- 아이템 mint 는 `grant_drop`(서버)에서만 — 클라에 추가 코드 없음.
- 클라는 Supabase 직접 쓰기 없음 — 전부 Nakama RPC 경유.
- 모든 write 함수: 트랜잭션 + `ledger` append + `idempotency_key` UNIQUE.
- 드랍/강화 RNG 는 Nakama(`util/rng.ts`)에서 수행.
