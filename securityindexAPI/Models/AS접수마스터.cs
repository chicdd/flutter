using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// AS접수마스터 테이블 모델
    /// </summary>
    [Table("AS접수마스터")]
    public class AS접수마스터
    {
        /// <summary>
        /// 관제관리번호
        /// </summary>
        [Key]
        [Column("id")]
        [MaxLength(50)]
        public string? id { get; set; }
        /// <summary>
        /// 관제관리번호
        /// </summary>
        [Column("관제관리번호")]
        [MaxLength(50)]
        public string? 관제관리번호 { get; set; }

        /// <summary>
        /// 고객이름
        /// </summary>
        [Column("고객이름")]
        [MaxLength(100)]
        public string? 고객이름 { get; set; }

        /// <summary>
        /// 고객연락처
        /// </summary>
        [Column("고객연락처")]
        [MaxLength(50)]
        public string? 고객연락처 { get; set; }

        /// <summary>
        /// 요청일자
        /// </summary>
        [Column("요청일자")]
        [MaxLength(50)]
        public DateTime? 요청일자 { get; set; }

        /// <summary>
        /// 요청시간
        /// </summary>
        [Column("요청시간")]
        [MaxLength(50)]
        public string? 요청시간 { get; set; }

        /// <summary>
        /// 요청제목
        /// </summary>
        [Column("요청제목")]
        [MaxLength(200)]
        public string? 요청제목 { get; set; }

        /// <summary>
        /// 접수일자
        /// </summary>
        [Column("접수일자")]
        [MaxLength(50)]
        public DateTime? 접수일자 { get; set; }

        /// <summary>
        /// 접수시간
        /// </summary>
        [Column("접수시간")]
        [MaxLength(50)]
        public string? 접수시간 { get; set; }

        /// <summary>
        /// 담당구역
        /// </summary>
        [Column("담당구역")]
        [MaxLength(50)]
        public string? 담당구역 { get; set; }

        /// <summary>
        /// 처리여부
        /// </summary>
        [Column("처리여부")]
        [MaxLength(50)]
        public string? 처리여부 { get; set; }

        /// <summary>
        /// 입력자
        /// </summary>
        [Column("입력자")]
        [MaxLength(50)]
        public string? 입력자 { get; set; }

        /// <summary>
        /// 세부내용
        /// </summary>
        [Column("세부내용")]
        [MaxLength(1000)]
        public string? 세부내용 { get; set; }

        /// <summary>
        /// 처리비고
        /// </summary>
        [Column("처리비고")]
        [MaxLength(1000)]
        public string? 처리비고 { get; set; }
    }

    /// <summary>
    /// AS접수 조회 결과 모델 (조인된 데이터)
    /// </summary>
    public class AS접수조회
    {
        /// <summary>
        /// 관제상호
        /// </summary>
        public string? 관제상호 { get; set; }

        /// <summary>
        /// 고객이름
        /// </summary>
        public string? 고객이름 { get; set; }

        /// <summary>
        /// 고객연락처
        /// </summary>
        public string? 고객연락처 { get; set; }

        /// <summary>
        /// 요청일자
        /// </summary>
        public DateTime? 요청일자 { get; set; }

        /// <summary>
        /// 요청시간
        /// </summary>
        public string? 요청시간 { get; set; }

        /// <summary>
        /// 요청제목
        /// </summary>
        public string? 요청제목 { get; set; }

        /// <summary>
        /// 접수일자
        /// </summary>
        public DateTime? 접수일자 { get; set; }

        /// <summary>
        /// 접수시간
        /// </summary>
        public string? 접수시간 { get; set; }

        /// <summary>
        /// 세부내용
        /// </summary>
        public string? 세부내용 { get; set; }

        /// <summary>
        /// 담당자코드명
        /// </summary>
        public string? 담당자코드명 { get; set; }

        /// <summary>
        /// 처리여부
        /// </summary>
        public string? 처리여부 { get; set; }

        /// <summary>
        /// 성명 (접수자)
        /// </summary>
        public string? 성명 { get; set; }

        /// <summary>
        /// 처리비고
        /// </summary>
        public string? 처리비고 { get; set; }
    }
}
