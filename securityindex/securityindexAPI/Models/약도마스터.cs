namespace securityindexAPI.Models
{
    /// <summary>
    /// 약도마스터 테이블 모델
    /// </summary>
    public class 약도마스터
    {
        /// <summary>
        /// 관제관리번호
        /// </summary>
        public string? 관제관리번호 { get; set; }

        /// <summary>
        /// 등록일자
        /// </summary>
        public DateTime? 등록일자 { get; set; }

        /// <summary>
        /// 순번
        /// </summary>
        public string? 순번 { get; set; }

        /// <summary>
        /// DATA구분코드
        /// </summary>
        public string? DATA구분코드 { get; set; }

        /// <summary>
        /// 약도데이터 (이미지 바이트 배열)
        /// </summary>
        public byte[]? 약도데이터 { get; set; }

        /// <summary>
        /// 비지오 (이미지 바이트 배열)
        /// </summary>
        public byte[]? 비지오 { get; set; }

        /// <summary>
        /// WMF (이미지 바이트 배열)
        /// </summary>
        public byte[]? WMF { get; set; }
    }
}
