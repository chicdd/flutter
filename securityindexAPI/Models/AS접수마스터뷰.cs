namespace securityindexAPI.Models
{
    /// <summary>
    /// 최근 방문 및 A/S이력 모델
    /// </summary>
    public class AS접수마스터뷰
    {
        /// <summary>
        /// 요청일자
        /// </summary>
        public string? 요청일자 { get; set; }

        /// <summary>
        /// 권역명
        /// </summary>
        public string? 권역명 { get; set; }

        /// <summary>
        /// 요청제목
        /// </summary>
        public string? 요청제목 { get; set; }

        /// <summary>
        /// 처리여부
        /// </summary>
        public bool? 처리여부 { get; set; }

        /// <summary>
        /// 처리일시
        /// </summary>
        public string? 처리일시 { get; set; }

        /// <summary>
        /// 처리비고
        /// </summary>
        public string? 처리비고 { get; set; }

        /// <summary>
        /// 접수자성명
        /// </summary>
        public string? 접수자성명 { get; set; }

        /// <summary>
        /// 처리자성명
        /// </summary>
        public string? 처리자성명 { get; set; }

        /// <summary>
        /// 개인AS처리자
        /// </summary>
        public string? 개인AS처리자 { get; set; }
    }
}
