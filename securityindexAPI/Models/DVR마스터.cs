using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// DVR연동마스터 테이블 엔티티
    /// </summary>
    [Table("DVR연동마스터")]
    public class DVR연동마스터
    {
        [Key]
        public string? 관제관리번호 { get; set; }
        public bool? 접속방식 { get; set; }
        public string? DVR종류코드 { get; set; }
        public string? DVR종류코드명 { get; set; }
        public string? 접속주소 { get; set; }
        public string? 접속포트 { get; set; }
        public string? 접속ID { get; set; }
        public string? 접속암호 { get; set; }
        public DateTime? 추가일자 { get; set; }
    }

    /// <summary>
    /// DVR종류코드마스터 테이블 엔티티
    /// </summary>
    [Table("DVR종류코드마스터")]
    public class DVR종류코드마스터
    {
        [Key]
        public string DVR종류코드 { get; set; } = string.Empty;
        public string? DVR종류코드명 { get; set; }
    }
}
