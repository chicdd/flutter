namespace securityindexAPI.Models
{
    /// <summary>
    /// 관제고객마스터뷰의 전체 필드를 포함하는 상세 정보 모델
    /// </summary>
    public class 관제고객마스터
    {
        // 기본 식별 정보
        public string 관제관리번호 { get; set; } = string.Empty;
        public string? 관제일련번호 { get; set; }
        public string? 고객관리번호 { get; set; }

        // 회선 정보
        public string? 사용회선종류 { get; set; }
        public string? 사용회선종류명 { get; set; }
        public string? 관제고객상태코드 { get; set; }
        public string? 관제고객상태코드명 { get; set; }
        public string? 공중회선 { get; set; }
        public string? 전용회선 { get; set; }
        public string? 인터넷회선 { get; set; }

        // 고객 정보
        public string? 관제상호 { get; set; }
        public string? 관제연락처1 { get; set; }
        public string? 관제연락처2 { get; set; }
        public string? 물건주소 { get; set; }
        public string? 대처경로1 { get; set; }
        public string? 대표자 { get; set; }
        public string? 대표자HP { get; set; }

        // 일자 정보
        public DateTime? 개통일자 { get; set; }

        // 회사/지사 구분
        public string? 회사구분코드 { get; set; }
        public string? 회사구분코드명 { get; set; }
        public string? 지사구분코드 { get; set; }
        public string? 지사구분코드명 { get; set; }

        // 관리 구역
        public string? 관리구역코드 { get; set; }
        public string? 관리구역코드명 { get; set; }
        public string? 출동권역코드 { get; set; }
        public string? 출동권역코드명 { get; set; }

        // 차량 정보
        public string? 차량코드 { get; set; }
        public string? 차량코드명 { get; set; }

        // 관할 기관
        public string? 경찰서코드 { get; set; }
        public string? 경찰서코드명 { get; set; }
        public string? 지구대코드 { get; set; }
        public string? 지구대코드명 { get; set; }
        public string? 소방서코드 { get; set; }
        public string? 소방서코드명 { get; set; }

        // 업종 정보
        public string? 업종대코드 { get; set; }
        public string? 업종대코드명 { get; set; }
        public string? 업종중코드 { get; set; }
        public string? 업종중코드명 { get; set; }

        // ARS 및 원격 정보
        public string? ARS옵션코드 { get; set; }
        public string? ARS옵션코드명 { get; set; }
        public string? ARS전화번호 { get; set; }
        public string? 원격전화번호 { get; set; }

        // 기기 정보
        public string? 기기종류코드 { get; set; }
        public string? 기기종류명 { get; set; }

        // 미경계 정보
        public string? 미경계종류코드 { get; set; }
        public string? 미경계종류코드명 { get; set; }

        // 보안 정보
        public string? 원격암호 { get; set; }

        // 집계 및 액션
        public bool? 월간집계 { get; set; }
        public string? 관제액션 { get; set; }

        // 키 관리
        public bool? 키인수여부 { get; set; }

        // 경계/해제 시간 - 평일
        public string? 평일경계 { get; set; }
        public string? 평일해제 { get; set; }

        // 경계/해제 시간 - 주말
        public string? 주말경계 { get; set; }
        public string? 주말해제 { get; set; }

        // 경계/해제 시간 - 휴일
        public string? 휴일경계 { get; set; }
        public string? 휴일해제 { get; set; }

        // 무단 범위
        public string? 평일무단범위 { get; set; }
        public string? 휴일무단범위 { get; set; }
        public string? 주말무단범위 { get; set; }

        // 장치 위치
        public string? 주장치위치 { get; set; }

        // 메모
        public string? 메모 { get; set; }

        // 미경계 분류
        public string? 미경계분류코드 { get; set; }
        public string? 미경계분류코드명 { get; set; }

        // 무단 사용
        public bool? 평일무단사용 { get; set; }
        public bool? 휴일무단사용 { get; set; }
        public bool? 주말무단사용 { get; set; }

        // 서비스 정보
        public string? 서비스종류코드 { get; set; }
        public string? 서비스종류코드명 { get; set; }
        public string? 사용코드종류 { get; set; }
        public string? 사용코드종류명 { get; set; }

        // DVR 정보
        public bool? dvr여부 { get; set; }
        public string? dvr주소 { get; set; }
        public string? dvrlogin { get; set; }
        public string? dvrpass { get; set; }

        // 키박스 및 원격
        public string? 키박스번호 { get; set; }
        public string? 원격포트 { get; set; }

        // 전용자 정보
        public string? 전용자번호 { get; set; }
        public string? 전용자메모 { get; set; }

        // 관제 개통 정보
        public DateTime? 관제개통일자 { get; set; }
        public string? 관제개통자 { get; set; }

        // 임시 필드
        public string? TMP1 { get; set; }
        public string? TMP2 { get; set; }
        public string? TMP3 { get; set; }
        public string? TMP4 { get; set; }
        public string? TMP5 { get; set; }
        public string? TMP6 { get; set; }
        public string? TMP7 { get; set; }
        public string? TMP8 { get; set; }
        public string? TMP9 { get; set; }
        public string? TMP10 { get; set; }

        // 커스텀 필드
        public string? cu1 { get; set; }
        public string? cu2 { get; set; }
        public string? cu3 { get; set; }
        public string? cu4 { get; set; }

        // 고객용 정보
        public string? 고객용상호 { get; set; }
        public string? 메모2 { get; set; }

        // 기기 회사
        public string? 자동원격기기코드 { get; set; }
        public string? 기기회사코드 { get; set; }
    }
}
