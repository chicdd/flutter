using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 스마트정보조회마스터 테이블 엔티티
    /// </summary>
    [Table("스마트정보조회마스터")]
    public class 스마트정보조회마스터
    {
        [Key]
        public string? 휴대폰번호 { get; set; }
        public string? 관제관리번호 { get; set; }
        public string? 상호명 { get; set; }
        public string? 사용자이름 { get; set; }
        public bool? 원격경계여부 { get; set; }
        public bool? 원격해제여부 { get; set; }
        public DateTime? 등록일자 { get; set; }
    }
}
