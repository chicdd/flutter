namespace securityindexAPI.Models
{
    /// <summary>
    /// 문서 정보 모델
    /// </summary>
    public class 문서정보
    {
        public string? 관제관리번호 { get; set; }
        public string? 문서일련번호 { get; set; }
        public string? 문서명 { get; set; }
        public string? 문서확장자 { get; set; }
        public string? 문서설명 { get; set; }
        public DateTime? 첨부일자 { get; set; }
        public string? 첨부자 { get; set; }
        public string? 문서종류 { get; set; }
    }
}
