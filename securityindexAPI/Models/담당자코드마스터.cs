using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 담당자코드마스터 테이블 모델
    /// </summary>
    [Table("담당자코드마스터")]
    public class 담당자코드마스터
    {
        /// <summary>
        /// 담당자코드 (Primary Key)
        /// </summary>
        [Key]
        [Column("담당자코드")]
        [MaxLength(50)]
        public string 담당자코드 { get; set; } = string.Empty;

        /// <summary>
        /// 담당자코드명
        /// </summary>
        [Column("담당자코드명")]
        [MaxLength(100)]
        public string? 담당자코드명 { get; set; }
    }
}
