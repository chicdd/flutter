using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 부가서비스마스터 테이블 엔티티
    /// </summary>
    [Table("부가서비스마스터")]
    public class 부가서비스마스터
    {
        [Key]
        public int 관리id { get; set; }
        public string? 관제관리번호 { get; set; }
        public string? 부가서비스코드 { get; set; }
        public string? 부가서비스코드명 { get; set; }
        public string? 부가서비스제공코드 { get; set; }
        public string? 부가서비스제공코드명 { get; set; }
        public DateTime? 부가서비스일자 { get; set; }
        public string? 추가메모 { get; set; }
    }

    /// <summary>
    /// 부가서비스코드마스터 테이블 엔티티
    /// </summary>
    [Table("부가서비스코드마스터")]
    public class 부가서비스코드마스터
    {
        [Key]
        public string 부가서비스코드 { get; set; } = string.Empty;
        public string? 부가서비스코드명 { get; set; }
    }

    /// <summary>
    /// 부가서비스제공마스터 테이블 엔티티
    /// </summary>
    [Table("부가서비스제공마스터")]
    public class 부가서비스제공마스터
    {
        [Key]
        public string 부가서비스제공코드 { get; set; } = string.Empty;
        public string? 부가서비스제공코드명 { get; set; }
    }
}
