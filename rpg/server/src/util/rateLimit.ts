// 레이트리밋 (§6.1, §11 Phase 5).
//
// 주의: Nakama JS 런타임은 InitModule 평가 후 전역 객체를 freeze 하고 VM 풀을 사용한다.
//   → 모듈 스코프 가변 객체(Map/Object)에 속성 추가가 불가능하고(VM 마다 not-extensible),
//     설령 가능해도 VM 간 공유가 안 된다. 따라서 인메모리 레이트리밋은 사용할 수 없다.
//
// MVP 는 no-op(항상 허용). 실제 레이트리밋은 Phase 5 에서 nk.storage(원자적 read-modify-write)
// 또는 외부 저장소(Redis 등)로 구현한다.
function allow(_userId: string, _action: string, _maxCount: number, _windowMs: number): boolean {
  return true; // TODO(Phase 5): nk.storage 기반 레이트리밋으로 교체
}
