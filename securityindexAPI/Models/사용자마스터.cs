using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 사용자마스터 테이블 모델
    /// </summary>
    [Table("사용자마스터")]
    public class 사용자마스터
    {
        [Key]
        [Column("등록번호")]
        public string? 등록번호 { get; set; }

        [Column("관제관리번호")]
        public string? 관제관리번호 { get; set; }

        [Column("사용자명")]
        public string? 사용자명 { get; set; }

        [Column("직급")]
        public string? 직급 { get; set; }

        [Column("휴대전화")]
        public string? 휴대전화 { get; set; }

        [Column("계약자와관계")]
        public string? 계약자와관계 { get; set; }

        [Column("주민번호")]
        public string? 주민번호 { get; set; }

        [Column("OC사용자")]
        public string? OC사용자 { get; set; }

        [Column("비고")]
        public string? 비고 { get; set; }

        [Column("무단해제허용")]
        public bool? 무단해제허용 { get; set; }

        [Column("SMS발송")]
        public bool? SMS발송 { get; set; }

        [Column("요원카드")]
        public bool? 요원카드 { get; set; }

        [Column("미경계SMS")]
        public bool? 미경계SMS { get; set; }

        [Column("예비카드여부")]
        public bool? 예비카드여부 { get; set; }
    }
}
