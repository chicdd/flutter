namespace securityindexAPI.Models
{
    /// <summary>
    /// 검색로그 데이터 모델
    /// </summary>
    public class 검색로그마스터
    {
        /// <summary>
        /// 성명
        /// </summary>
        public string? 성명 { get; set; }

        /// <summary>
        /// 기록일자 (수신일자)
        /// </summary>
        public DateTime? 기록일자 { get; set; }

        /// <summary>
        /// 기록시간 (수신시간)
        /// </summary>
        public string? 기록시간 { get; set; }

        /// <summary>
        /// 입력내용 (로그데이터)
        /// </summary>
        public string? 입력내용 { get; set; }
    }
}
