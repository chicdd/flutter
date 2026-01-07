using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 보수점검지시마스터 모델
    /// </summary>
    [Table("보수점검지시마스터")]
    public class 보수점검지시마스터
    {
        [Key]
        [Column("관제관리번호")]
        public string 관제관리번호 { get; set; } = string.Empty;

        [Column("발생자")]
        public string? 발생자 { get; set; }

        [Column("점검기준월")]
        public DateTime? 점검기준월 { get; set; }

        [Column("처리일자")]
        public DateTime? 처리일자 { get; set; }

        [Column("존점검")]
        public bool? 존점검 { get; set; }

        [Column("키테스트")]
        public bool? 키테스트 { get; set; }

        [Column("키예탁")]
        public bool? 키예탁 { get; set; }

        [Column("키수량")]
        public int? 키수량 { get; set; }

        [Column("도면점검")]
        public bool? 도면점검 { get; set; }

        [Column("고객카드")]
        public bool? 고객카드 { get; set; }

        [Column("처리자")]
        public string? 처리자 { get; set; }

        [Column("고객요청사항")]
        public string? 고객요청사항 { get; set; }

        [Column("처리완료여부")]
        public string? 처리완료여부 { get; set; }
    }
}
