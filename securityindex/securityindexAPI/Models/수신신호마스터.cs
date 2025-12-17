namespace securityindexAPI.Models
{
    /// <summary>
    /// 수신신호 정보 모델
    /// </summary>
    public class 수신신호마스터
    {
        public string? 관제관리번호 { get; set; }
        public string? 관제상호 { get; set; }
        public DateTime? 수신일자 { get; set; }
        public string? 수신시간 { get; set; }
        public string? 신호명 { get; set; }
        public string? 신호코드 { get; set; }
        public string? 비고 { get; set; }
        public string? 관제자 { get; set; }
        public string? 공중회선 { get; set; }
        public string? 전용회선 { get; set; }
        public string? 입력내용 { get; set; }
        public string? 글자색 { get; set; }
        public string? 바탕색 { get; set; }
    }
}
