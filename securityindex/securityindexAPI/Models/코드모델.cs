using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace securityindexAPI.Models
{
    /// <summary>
    /// 관리구역 코드 모델
    /// </summary>
    [Table("관리구역코드마스터")]
    public class 관리구역코드모델
    {
        [Key]
        [Column("관리구역코드")]
        public string 관리구역코드 { get; set; } = string.Empty;

        [Column("관리구역코드명")]
        public string 관리구역코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 출동권역 코드 모델
    /// </summary>
    [Table("출동권역코드마스터")]
    public class 출동권역코드모델
    {
        [Key]
        [Column("출동권역코드")]
        public string 출동권역코드 { get; set; } = string.Empty;

        [Column("출동권역코드명")]
        public string 출동권역코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 업종 코드 모델
    /// </summary>
    [Table("업종대코드마스터")]
    public class 업종코드모델
    {
        [Key]
        [Column("업종대코드")]
        public string 업종대코드 { get; set; } = string.Empty;

        [Column("업종대코드명")]
        public string 업종대코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 사항 코드 모델
    /// </summary>

    /// <summary>
    /// 경찰서 코드 모델
    /// </summary>
    [Table("경찰서코드마스터")]
    public class 경찰서코드모델
    {
        [Key]
        [Column("경찰서코드")]
        public string 경찰서코드 { get; set; } = string.Empty;

        [Column("경찰서코드명")]
        public string 경찰서코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 지구대 코드 모델
    /// </summary>
    [Table("지구대코드마스터")]
    public class 지구대코드모델
    {
        [Key]
        [Column("지구대코드")]
        public string 지구대코드 { get; set; } = string.Empty;

        [Column("지구대코드명")]
        public string 지구대코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 주사용회선 모델
    /// </summary>
    [Table("사용회선종류마스터")]
    public class 사용회선종류모델
    {
        [Key]
        [Column("사용회선종류")]
        public string 사용회선종류 { get; set; } = string.Empty;

        [Column("사용회선종류명")]
        public string 사용회선종류명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 서비스 코드 모델
    /// </summary>
    [Table("서비스종류코드마스터")]
    public class 서비스코드모델
    {
        [Key]
        [Column("서비스종류코드")]
        public string 서비스종류코드 { get; set; } = string.Empty;

        [Column("서비스종류코드명")]
        public string 서비스종류코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 서비스 코드 모델
    /// </summary>
    [Table("관제고객상태코드마스터")]
    public class 관제고객상태코드모델
    {
        [Key]
        [Column("관제고객상태코드")]
        public string 관제고객상태코드 { get; set; } = string.Empty;

        [Column("관제고객상태코드명")]
        public string 관제고객상태코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 주장치종류 모델
    /// </summary>
    [Table("기기종류코드마스터")]
    public class 기기종류코드모델
    {
        [Key]
        [Column("기기종류코드")]
        public string 기기종류코드 { get; set; } = string.Empty;

        [Column("기기종류명")]
        public string 기기종류명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 주장치종류 모델
    /// </summary>
    [Table("차량코드마스터")]
    public class 차량코드모델
    {
        [Key]
        [Column("차량코드")]
        public string 차량코드 { get; set; } = string.Empty; 

        [Column("차량코드명")]
        public string 차량코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 주장치분류 코드 모델
    /// </summary>
    [Table("미경계분류코드마스터")]
    public class 미경계분류코드모델
    {
        [Key]
        [Column("미경계분류코드")]
        public string 미경계분류코드 { get; set; } = string.Empty;

        [Column("미경계분류코드명")]
        public string 미경계분류코드명 { get; set; } = string.Empty;
    }

    /// <summary>
    /// 미경계설정 모델
    /// </summary>
    [Table("미경계종류코드마스터")]
    public class 미경계종류코드모델
    {
        [Key]
        [Column("미경계종류코드")]
        public string 미경계종류코드 { get; set; } = string.Empty;

        [Column("미경계종류코드명")]
        public string 미경계종류코드명 { get; set; } = string.Empty;

    }

    /// <summary>
    /// 회사구분 모델
    /// </summary>
    [Table("회사구분코드마스터")]
    public class 회사구분코드모델
    {
        [Key]
        [Column("회사구분코드")]
        public string 회사구분코드 { get; set; } = string.Empty;

        [Column("회사구분코드명")]
        public string 회사구분코드명 { get; set; } = string.Empty;

    }

    /// <summary>
    /// 지사구분 모델
    /// </summary>
    [Table("지사구분코드마스터")]
    public class 지사구분코드모델
    {
        [Key]
        [Column("지사구분코드")]
        public string 지사구분코드 { get; set; } = string.Empty;

        [Column("지사구분코드명")]
        public string 지사구분코드명 { get; set; } = string.Empty;

    }
}
