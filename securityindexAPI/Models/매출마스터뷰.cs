namespace securityindexAPI.Models
{
    /// <summary>
    /// 최근수금이력 모델
    /// </summary>
    public class 매출마스터뷰
    {
        /// <summary>
        /// 매출년월
        /// </summary>
        public string? 매출년월 { get; set; }

        /// <summary>
        /// 청구금액
        /// </summary>
        public decimal? 청구금액 { get; set; }

        /// <summary>
        /// 실입금액
        /// </summary>
        public decimal? 실입금액 { get; set; }

        /// <summary>
        /// 입금방법
        /// </summary>
        public string? 입금방법 { get; set; }

        /// <summary>
        /// 납입일자
        /// </summary>
        public DateTime? 납입일자 { get; set; }

        /// <summary>
        /// 수금여부
        /// </summary>
        public bool? 수금여부 { get; set; }

        /// <summary>
        /// 처리자
        /// </summary>
        public string? 처리자 { get; set; }

        /// <summary>
        /// 비고
        /// </summary>
        public string? 비고 { get; set; }
    }
}
