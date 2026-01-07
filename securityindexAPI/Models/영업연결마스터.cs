using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    [Table("영업연결마스터")]
    public class 영업연결마스터
    {
        [Key]
        [Column("업체코드")]
        public string? 업체코드 { get; set; }

        [Column("서버")]
        public string? 서버 { get; set; }

        [Column("DB")]
        public string? DB { get; set; }

        [Column("ID")]
        public string? ID { get; set; }

        [Column("암호")]
        public string? 암호 { get; set; }

        [Column("사용여부")]
        public string? 사용여부 { get; set; }
    }
}
