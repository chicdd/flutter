using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 존코드테이블 모델
    /// </summary>
    [Table("존코드테이블")]
    public class 존마스터
    {
        [Key]
        [Column("존번호")]
        public string? 존번호 { get; set; }

        [Column("관제관리번호")]
        public string? 관제관리번호 { get; set; }

        [Column("감지기설치위치")]
        public string? 감지기설치위치 { get; set; }

        [Column("감지기명")]
        public string? 감지기명 { get; set; }

        [Column("비고")]
        public string? 비고 { get; set; }
    }
}
