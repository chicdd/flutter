namespace securityindexAPI.Models
{
    // 관제고객마스터뷰의 모든 필드를 포함하는 통합 모델
    public class 고객검색
    {
        // 기본 정보 (공통)
        public string 관제관리번호 { get; set; } = string.Empty;
        public string 관제상호 { get; set; } = string.Empty;

        // 인덱스 조회용 필드
        public string 관제고객상태코드명 { get; set; } = string.Empty;
        public string 물건주소 { get; set; } = string.Empty;

        // 검색용 필드
        public string? 대표자 { get; set; }
        public string? 관제연락처1 { get; set; }
    }

    public class 사용자마스터
    {
        public string? 휴대전화 { get; set; }
        public string? 관제관리번호 { get; set; }
    }
}
