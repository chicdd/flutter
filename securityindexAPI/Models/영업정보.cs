namespace securityindexAPI.Models
{
    /// <summary>
    /// 영업정보 응답 모델 (고객마스터뷰 + 매출마스터뷰 조합)
    /// </summary>
    public class 영업정보
    {
        // 기본정보
        public string? 고객번호 { get; set; }
        public string? 상호명 { get; set; }
        public string? 대표자 { get; set; }
        public string? 상호전화 { get; set; }
        public string? 팩스번호 { get; set; }
        public string? 휴대전화 { get; set; }
        public string? 고객상태 { get; set; }
        public string? 납입방법 { get; set; }
        public string? 담당권역 { get; set; }
        public string? 신규판매자 { get; set; }

        // 사업자정보
        public string? 사업자등록번호 { get; set; }
        public string? 사업자상호 { get; set; }
        public string? 사업자대표자 { get; set; }
        public string? 사업장주소 { get; set; }
        public string? 업태 { get; set; }
        public string? 종목 { get; set; }
        public string? 계산서이메일 { get; set; }

        // 월정료 정보
        public decimal? 월정료 { get; set; }
        public decimal? VAT { get; set; }
        public decimal? 총금액 { get; set; }
        public decimal? 보증금 { get; set; }
        public int 통합관리건수 { get; set; }
        public int? 미납월분 { get; set; }
        public decimal? 미납총금액 { get; set; }
    }
}
