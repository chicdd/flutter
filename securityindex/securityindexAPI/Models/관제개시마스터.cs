using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 관제개시마스터 모델
    /// </summary>
    [Table("관제개시마스터")]
    public class 관제개시마스터
    {
        [Key]
        [Column("관제관리번호")]
        public string 관제관리번호 { get; set; } = string.Empty;

        [Column("경비개시일자")]
        public DateTime? 경비개시일자 { get; set; }

        [Column("존점검결과")]
        public bool? 존점검결과 { get; set; }

        [Column("키테스트")]
        public bool? 키테스트 { get; set; }

        [Column("키수량")]
        public int? 키수량 { get; set; }

        [Column("도면점검")]
        public bool? 도면점검 { get; set; }

        [Column("고객카드")]
        public bool? 고객카드 { get; set; }

        [Column("점검자")]
        public string? 점검자 { get; set; }

        [Column("관제확인자")]
        public string? 관제확인자 { get; set; }

        [Column("설치공사자")]
        public string? 설치공사자 { get; set; }

        [Column("키인수자")]
        public string? 키인수자 { get; set; }

        [Column("비고사항")]
        public string? 비고사항 { get; set; }
    }
}
