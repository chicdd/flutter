namespace securityindexAPI.Models
{
    /// <summary>
    /// 고객정보 변동이력 데이터 모델
    /// </summary>
    public class 고객변경이력마스터
    {
        /// <summary>
        /// 처리자 (관제사용자마스터.성명)
        /// </summary>
        public string? 처리자 { get; set; }

        /// <summary>
        /// 변경처리일시 (변경처리일자)
        /// </summary>
        public DateTime? 변경처리일시 { get; set; }

        /// <summary>
        /// 변경전
        /// </summary>
        public string? 변경전 { get; set; }

        /// <summary>
        /// 변경후
        /// </summary>
        public string? 변경후 { get; set; }

        /// <summary>
        /// 메모
        /// </summary>
        public string? 메모 { get; set; }
    }
}
