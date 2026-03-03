using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;
using System.Diagnostics;
using System.Text.Json;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api")]
    public class SelectController : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly neo_erpaDBContext _erpContext;
        private readonly ILogger<SelectController> _logger;
        private readonly IConfiguration _configuration;

        public SelectController(SecurityRingDBContext context, neo_erpaDBContext erpContext, ILogger<SelectController> logger, IConfiguration configuration)
        {
            _context = context;
            _erpContext = erpContext;
            _logger = logger;
            _configuration = configuration;
        }

        /// <summary>
        /// 관제고객 마스터 뷰에서 TOP 100 데이터를 JSON으로 반환 (목록용 필드만)
        /// </summary>
        /// <returns>관제고객 리스트</returns>
        [HttpGet]
        public async Task<ActionResult<IEnumerable<고객검색>>> Get관제고객()
        {
            try
            {
                var query = @"
                    SELECT TOP 100
                        관제관리번호,
                        관제상호,
                        관제고객상태코드명,
                        물건주소,
                        대표자,
                        관제연락처1
                    FROM 관제고객마스터뷰
                    ORDER BY 관제관리번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                using var reader = await command.ExecuteReaderAsync();
                var 고객리스트 = new List<고객검색>();

                while (await reader.ReadAsync())
                {
                    var customerData = new 고객검색
                    {
                        관제관리번호 = reader["관제관리번호"]?.ToString() ?? string.Empty,
                        관제상호 = reader["관제상호"]?.ToString() ?? string.Empty,
                        관제고객상태코드명 = reader["관제고객상태코드명"]?.ToString() ?? string.Empty,
                        물건주소 = reader["물건주소"]?.ToString() ?? string.Empty,
                        대표자 = reader["대표자"]?.ToString(),
                        관제연락처1 = reader["관제연락처1"]?.ToString()
                    };

                    고객리스트.Add(customerData);
                }

                await connection.CloseAsync();

                return Ok(고객리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "관제고객 데이터를 가져오는 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 필터링된 관제고객 데이터를 반환 (목록용 필드만)
        /// </summary>
        /// <param name="count">가져올 데이터 개수 (기본값: 100)</param>
        /// <param name="regionCode">지역코드 필터 (선택사항)</param>
        /// <returns>관제고객 리스트</returns>
        [HttpGet("top")]
        public async Task<ActionResult<IEnumerable<고객검색>>> GetTop관제고객([FromQuery] int count = 100, [FromQuery] string? regionCode = null)
        {
            try
            {
                if (count <= 0 || count > 1000)
                {
                    return BadRequest(new { message = "count는 1에서 1000 사이의 값이어야 합니다." });
                }

                // WHERE 절 생성 (지역코드 필터)
                string whereClause = "";
                List<string> regionCodes = new List<string>();
                if (!string.IsNullOrWhiteSpace(regionCode))
                {
                    regionCodes = regionCode.Split('/')
                        .Select(c => c.Trim())
                        .Where(c => !string.IsNullOrWhiteSpace(c))
                        .ToList();

                    if (regionCodes.Count > 0)
                    {
                        var paramNames = string.Join(", ", regionCodes.Select((_, i) => $"@regionCode{i}"));
                        whereClause = $"WHERE (관리구역코드 IN ({paramNames}) OR 관리구역코드 = '000')";
                    }
                }

                var query = $@"
                    SELECT TOP {count}
                        관제관리번호,
                        관제상호,
                        관제고객상태코드명,
                        물건주소,
                        대표자,
                        관제연락처1
                    FROM 관제고객마스터뷰
                    {whereClause}
                    ORDER BY 관제관리번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                // 지역코드 파라미터 추가
                if (regionCodes.Count > 0)
                {
                    for (int i = 0; i < regionCodes.Count; i++)
                    {
                        var regionParam = command.CreateParameter();
                        regionParam.ParameterName = $"@regionCode{i}";
                        regionParam.Value = regionCodes[i];
                        command.Parameters.Add(regionParam);
                    }
                }

                using var reader = await command.ExecuteReaderAsync();
                var 고객리스트 = new List<고객검색>();

                while (await reader.ReadAsync())
                {
                    var customerData = new 고객검색
                    {
                        관제관리번호 = reader["관제관리번호"]?.ToString() ?? string.Empty,
                        관제상호 = reader["관제상호"]?.ToString() ?? string.Empty,
                        관제고객상태코드명 = reader["관제고객상태코드명"]?.ToString() ?? string.Empty,
                        물건주소 = reader["물건주소"]?.ToString() ?? string.Empty,
                        대표자 = reader["대표자"]?.ToString(),
                        관제연락처1 = reader["관제연락처1"]?.ToString()
                    };

                    고객리스트.Add(customerData);
                }

                await connection.CloseAsync();

                return Ok(고객리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "관제고객 데이터를 가져오는 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 관제고객 상세 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>관제고객 상세 정보</returns>
        [HttpGet("{관제관리번호}")]
        public async Task<ActionResult<관제고객마스터>> Get관제고객상세(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT *
                    FROM 관제고객마스터뷰
                    WHERE 관제관리번호 = @관제관리번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                관제고객마스터? 고객상세 = null;

                if (await reader.ReadAsync())
                {
                    고객상세 = new 관제고객마스터
                    {
                        관제관리번호 = reader["관제관리번호"]?.ToString() ?? string.Empty,
                        고객관리번호 = reader["고객관리번호"]?.ToString(),
                        관제상호 = reader["관제상호"]?.ToString() ?? string.Empty,
                        고객용상호 = reader["고객용상호"]?.ToString(),
                        관제연락처1 = reader["관제연락처1"]?.ToString(),
                        관제연락처2 = reader["관제연락처2"]?.ToString(),
                        물건주소 = reader["물건주소"]?.ToString(),
                        대처경로1 = reader["대처경로1"]?.ToString(),
                        대표자 = reader["대표자"]?.ToString(),
                        대표자HP = reader["대표자HP"]?.ToString(),
                        개통일자 = reader["개통일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["개통일자"]),
                        공중회선 = reader["공중회선"]?.ToString(),
                        전용회선 = reader["전용회선"]?.ToString(),
                        인터넷회선 = reader["인터넷회선"]?.ToString(),
                        원격포트 = reader["원격포트"]?.ToString(),
                        관제고객상태코드 = reader["관제고객상태코드"]?.ToString(),
                        관제고객상태코드명 = reader["관제고객상태코드명"]?.ToString(),
                        관리구역코드 = reader["관리구역코드"]?.ToString(),
                        관리구역코드명 = reader["관리구역코드명"]?.ToString(),
                        출동권역코드 = reader["출동권역코드"]?.ToString(),
                        출동권역코드명 = reader["출동권역코드명"]?.ToString(),
                        업종대코드 = reader["업종대코드"]?.ToString(),
                        업종대코드명 = reader["업종대코드명"]?.ToString(),
                        차량코드 = reader["차량코드"]?.ToString(),
                        차량코드명 = reader["차량코드명"]?.ToString(),
                        경찰서코드 = reader["경찰서코드"]?.ToString(),
                        경찰서코드명 = reader["경찰서코드명"]?.ToString(),
                        지구대코드 = reader["지구대코드"]?.ToString(),
                        지구대코드명 = reader["지구대코드명"]?.ToString(),
                        소방서코드 = reader["소방서코드"]?.ToString(),
                        사용회선종류 = reader["사용회선종류"]?.ToString(),
                        사용회선종류명 = reader["사용회선종류명"]?.ToString(),
                        서비스종류코드 = reader["서비스종류코드"]?.ToString(),
                        서비스종류코드명 = reader["서비스종류코드명"]?.ToString(),
                        기기종류코드 = reader["기기종류코드"]?.ToString(),
                        기기종류명 = reader["기기종류명"]?.ToString(),
                        미경계종류코드 = reader["미경계종류코드"]?.ToString(),
                        미경계종류코드명 = reader["미경계종류코드명"]?.ToString(),
                        미경계분류코드명 = reader["미경계분류코드명"]?.ToString(),
                        원격전화번호 = reader["원격전화번호"]?.ToString(),
                        원격암호 = reader["원격암호"]?.ToString(),
                        ARS전화번호 = reader["ARS전화번호"]?.ToString(),
                        TMP1 = reader["TMP1"]?.ToString(), //키인수수량
                        TMP2 = reader["TMP2"]?.ToString(), //키패드
                        TMP3 = reader["TMP3"]?.ToString(), //키패드수량
                        TMP4 = reader["TMP4"]?.ToString(), //X좌표1
                        TMP5 = reader["TMP5"]?.ToString(), //Y좌표1
                        TMP6 = reader["TMP6"]?.ToString(), //X좌표2
                        TMP7 = reader["TMP7"]?.ToString(), //Y좌표2
                        TMP8 = reader["tmP8"]?.ToString(),
                        cu1 = reader["cu1"]?.ToString(), //개통전화번호
                        cu2 = reader["cu2"]?.ToString(), //모뎀일련번호
                        cu3 = reader["cu3"]?.ToString(), //확장고객정보의 개통일자
                        cu4 = reader["cu4"]?.ToString(), //추가메모
                        회사구분코드 = reader["회사구분코드"]?.ToString(),
                        회사구분코드명 = reader["회사구분코드명"]?.ToString(),
                        지사구분코드 = reader["지사구분코드"]?.ToString(),
                        지사구분코드명 = reader["지사구분코드명"]?.ToString(),
                        전용자번호 = reader["전용자번호"]?.ToString(),
                        전용자메모 = reader["전용자메모"]?.ToString(),
                        키박스번호 = reader["키박스번호"]?.ToString(),
                        월간집계 = reader["월간집계"] == DBNull.Value ? false : Convert.ToBoolean(reader["월간집계"]),
                        키인수여부 = reader["키인수여부"] == DBNull.Value ? false : Convert.ToBoolean(reader["키인수여부"]),
                        dvr여부 = reader["dvr여부"] == DBNull.Value ? false : Convert.ToBoolean(reader["dvr여부"]),
                        평일경계 = reader["평일경계"]?.ToString(),
                        평일해제 = reader["평일해제"]?.ToString(),
                        주말경계 = reader["주말경계"]?.ToString(),
                        주말해제 = reader["주말해제"]?.ToString(),
                        휴일경계 = reader["휴일경계"]?.ToString(),
                        휴일해제 = reader["휴일해제"]?.ToString(),
                        평일무단범위 = reader["평일무단범위"]?.ToString(),
                        주말무단범위 = reader["주말무단범위"]?.ToString(),
                        휴일무단범위 = reader["휴일무단범위"]?.ToString(),
                        평일무단사용 = reader["평일무단사용"] == DBNull.Value ? false : Convert.ToBoolean(reader["평일무단사용"]),
                        주말무단사용 = reader["주말무단사용"] == DBNull.Value ? false : Convert.ToBoolean(reader["주말무단사용"]),
                        휴일무단사용 = reader["휴일무단사용"] == DBNull.Value ? false : Convert.ToBoolean(reader["휴일무단사용"]),
                        관제액션 = reader["관제액션"]?.ToString(),
                        메모 = reader["메모"]?.ToString(),
                        메모2 = reader["메모2"]?.ToString()
                    };
                }

                await connection.CloseAsync();

                if (고객상세 == null)
                {
                    _logger.LogInformation($"관제관리번호 {관제관리번호}에 해당하는 고객을 찾을 수 없습니다.");
                    return NotFound(new { message = $"관제관리번호 {관제관리번호}에 해당하는 고객을 찾을 수 없습니다." });
                }

                _logger.LogInformation($"관제고객 상세 조회 완료: 관제관리번호={관제관리번호}");
                return Ok(고객상세);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"관제고객 상세 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 검색 조건에 따라 관제고객 데이터를 검색 (목록용 필드만)
        /// </summary>
        /// <param name="filterType">필터 타입 (고객번호, 상호, 대표자, 주소, 전화번호, 휴대전화)</param>
        /// <param name="query">검색어</param>
        /// <param name="sortType">정렬 타입 (번호정렬, 상호정렬)</param>
        /// <param name="count">가져올 최대 데이터 개수 (기본값: 100)</param>
        /// <returns>검색된 관제고객 리스트</returns>
        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<고객검색>>> Search관제고객(
            [FromQuery] string? filterType,
            [FromQuery] string? query,
            [FromQuery] string? sortType,
            [FromQuery] int count = 100,
            [FromQuery] string? regionCode = null)
        {
            try
            {
                if (count <= 0 || count > 1000)
                {
                    return BadRequest(new { message = "count는 1에서 1000 사이의 값이어야 합니다." });
                }

                string sqlQuery;
                string whereClause = "";
                string orderByClause = sortType == "상호정렬" ? "관제상호" : "관제관리번호";
                var conditions = new List<string>();

                // 검색 조건 추가
                if (!string.IsNullOrWhiteSpace(query))
                {
                    var searchQuery = query.Trim();

                    string searchCondition = filterType switch
                    {
                        "고객번호" => $"관제관리번호 LIKE '%{searchQuery}%'",
                        "상호" => $"관제상호 LIKE '%{searchQuery}%'",
                        "대표자" => $"대표자 LIKE '%{searchQuery}%'",
                        "물건주소" => $"물건주소 LIKE '%{searchQuery}%'",
                        "전화번호" or "관제연락처1" => $"관제연락처1 LIKE '%{searchQuery}%'",
                        "사용자HP" => $@"관제관리번호 IN (
                                SELECT DISTINCT 관제관리번호
                                FROM 사용자마스터
                                WHERE 휴대전화 LIKE '%{searchQuery}%')",
                        _ => $@"(관제관리번호 LIKE '%{searchQuery}%'
                                OR 관제상호 LIKE '%{searchQuery}%'
                                OR 대표자 LIKE '%{searchQuery}%'
                                OR 물건주소 LIKE '%{searchQuery}%')"
                    };

                    conditions.Add(searchCondition);
                    _logger.LogInformation($"검색 조건: filterType={filterType}, query={query}");
                }

                // 지역코드 필터 추가
                List<string> regionCodes = new List<string>();
                if (!string.IsNullOrWhiteSpace(regionCode))
                {
                    regionCodes = regionCode.Split('/')
                        .Select(c => c.Trim())
                        .Where(c => !string.IsNullOrWhiteSpace(c))
                        .ToList();

                    if (regionCodes.Count > 0)
                    {
                        var paramNames = string.Join(", ", regionCodes.Select((_, i) => $"@regionCode{i}"));
                        conditions.Add($"(관리구역코드 IN ({paramNames}) OR 관리구역코드 = '000')");
                        _logger.LogInformation($"지역코드 필터: {regionCode} -> [{string.Join(", ", regionCodes)}] + 000");
                    }
                }

                // WHERE 절 조합
                if (conditions.Count > 0)
                {
                    whereClause = "WHERE " + string.Join(" AND ", conditions);
                }

                // 최종 쿼리 생성
                sqlQuery = $@"
                    SELECT TOP {count}
                        관제관리번호,
                        관제상호,
                        관제고객상태코드명,
                        물건주소,
                        대표자,
                        관제연락처1
                    FROM 관제고객마스터뷰
                    {whereClause}
                    ORDER BY {orderByClause}";

                _logger.LogDebug($"실행 SQL: {sqlQuery}");

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = sqlQuery;

                // 지역코드 파라미터 추가
                if (regionCodes.Count > 0)
                {
                    for (int i = 0; i < regionCodes.Count; i++)
                    {
                        var regionParam = command.CreateParameter();
                        regionParam.ParameterName = $"@regionCode{i}";
                        regionParam.Value = regionCodes[i];
                        command.Parameters.Add(regionParam);
                    }
                }

                using var reader = await command.ExecuteReaderAsync();
                var 고객리스트 = new List<고객검색>();

                while (await reader.ReadAsync())
                {
                    var customerData = new 고객검색
                    {
                        관제관리번호 = reader["관제관리번호"]?.ToString() ?? string.Empty,
                        관제상호 = reader["관제상호"]?.ToString() ?? string.Empty,
                        관제고객상태코드명 = reader["관제고객상태코드명"]?.ToString() ?? string.Empty,
                        물건주소 = reader["물건주소"]?.ToString() ?? string.Empty,
                        대표자 = reader["대표자"]?.ToString(),
                        관제연락처1 = reader["관제연락처1"]?.ToString()
                    };

                    고객리스트.Add(customerData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"검색 완료: filterType={filterType}, query={query}, sortType={sortType}, 결과수={고객리스트.Count}");

                return Ok(고객리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "관제고객 검색 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 휴일주간 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>휴일주간 리스트</returns>
        [HttpGet("휴일주간리스트/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<휴일주간>>> Get휴일주간(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT
                        관리id,
                        관제관리번호,
                        휴일주간코드
                    FROM 관제고객휴일주간
                    WHERE 관제관리번호 = @관제관리번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 휴일주간리스트 = new List<휴일주간>();

                while (await reader.ReadAsync())
                {
                    var holidayData = new 휴일주간
                    {
                        관리id = reader["관리id"] == DBNull.Value ? 0 : Convert.ToInt32(reader["관리id"]),
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        휴일주간코드 = reader["휴일주간코드"]?.ToString()
                    };

                    휴일주간리스트.Add(holidayData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"휴일주간 조회 완료: 관제관리번호={관제관리번호}, 결과수={휴일주간리스트.Count}");
                return Ok(휴일주간리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"휴일주간 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }


        /// <summary>
        /// 관제관리번호로 부가서비스 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>부가서비스 리스트</returns>
        [HttpGet("부가서비스조회/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<부가서비스마스터>>> Get부가서비스(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT TOP 1000
                        a.관리id,
                        a.관제관리번호,
                        b.부가서비스코드명,
                        c.부가서비스제공코드명,
                        a.부가서비스일자,
                        a.추가메모
                    FROM 부가서비스마스터 a
                    LEFT JOIN 부가서비스코드마스터 b ON a.부가서비스코드 = b.부가서비스코드
                    LEFT JOIN 부가서비스제공마스터 c ON a.부가서비스제공코드 = c.부가서비스제공코드
                    WHERE a.관제관리번호 = @관제관리번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 부가서비스리스트 = new List<부가서비스마스터>();

                while (await reader.ReadAsync())
                {
                    var serviceData = new 부가서비스마스터
                    {
                        관리id = reader["관리id"] == DBNull.Value ? 0 : Convert.ToInt32(reader["관리id"]),
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        부가서비스코드명 = reader["부가서비스코드명"]?.ToString(),
                        부가서비스제공코드명 = reader["부가서비스제공코드명"]?.ToString(),
                        부가서비스일자 = reader["부가서비스일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["부가서비스일자"]),
                        추가메모 = reader["추가메모"]?.ToString()
                    };

                    부가서비스리스트.Add(serviceData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"부가서비스 조회 완료: 관제관리번호={관제관리번호}, 결과수={부가서비스리스트.Count}");
                return Ok(부가서비스리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"부가서비스 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 DVR 연동 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>DVR 연동 리스트</returns>
        [HttpGet("DVR조회/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<DVR연동마스터>>> GetDVR정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT TOP 1000
                        a.일련번호,
                        a.관제관리번호,
                        a.접속방식,
                        a.DVR종류코드,
                        b.DVR종류코드명,
                        a.접속주소,
                        a.접속포트,
                        a.접속ID,
                        a.접속암호,
                        a.추가일자
                    FROM DVR연동마스터 a
                    LEFT JOIN DVR종류코드마스터 b ON a.DVR종류코드 = b.DVR종류코드
                    WHERE a.관제관리번호 = @관제관리번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var dvr리스트 = new List<DVR연동마스터>();

                while (await reader.ReadAsync())
                {
                    var dvrData = new DVR연동마스터
                    {
                        일련번호 = reader["일련번호"] == DBNull.Value ? 0 : Convert.ToInt32(reader["일련번호"]),
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        접속방식 = reader["접속방식"] == DBNull.Value ? false : Convert.ToBoolean(reader["접속방식"]),
                        DVR종류코드 = reader["DVR종류코드"]?.ToString(),
                        DVR종류코드명 = reader["DVR종류코드명"]?.ToString(),
                        접속주소 = reader["접속주소"]?.ToString(),
                        접속포트 = reader["접속포트"]?.ToString(),
                        접속ID = reader["접속ID"]?.ToString(),
                        접속암호 = reader["접속암호"]?.ToString(),
                        추가일자 = reader["추가일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["추가일자"])
                    };

                    dvr리스트.Add(dvrData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"DVR 정보 조회 완료: 관제관리번호={관제관리번호}, 결과수={dvr리스트.Count}");
                return Ok(dvr리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"DVR 정보 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 스마트폰 인증 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>스마트폰 인증 정보 리스트</returns>
        [HttpGet("스마트폰인증번호조회/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<스마트정보조회마스터>>> Get스마트폰인증정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT
                        휴대폰번호,
                        관제관리번호,
                        영업관리번호,
                        상호명,
                        사용자이름,
                        원격경계여부,
                        원격해제여부,
                        등록일자
                    FROM 스마트정보조회마스터
                    WHERE 관제관리번호 = @관제관리번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 스마트폰인증리스트 = new List<스마트정보조회마스터>();

                while (await reader.ReadAsync())
                {
                    var authData = new 스마트정보조회마스터
                    {
                        휴대폰번호 = reader["휴대폰번호"]?.ToString(),
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        영업관리번호 = reader["영업관리번호"]?.ToString(),
                        상호명 = reader["상호명"]?.ToString(),
                        사용자이름 = reader["사용자이름"]?.ToString(),
                        원격경계여부 = reader["원격경계여부"] == DBNull.Value ? false : Convert.ToBoolean(reader["원격경계여부"]),
                        원격해제여부 = reader["원격해제여부"] == DBNull.Value ? false : Convert.ToBoolean(reader["원격해제여부"]),
                        등록일자 = reader["등록일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["등록일자"])
                    };

                    스마트폰인증리스트.Add(authData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"스마트폰 인증 정보 조회 완료: 관제관리번호={관제관리번호}, 결과수={스마트폰인증리스트.Count}");
                return Ok(스마트폰인증리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"스마트폰 인증 정보 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 문서 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>문서 정보 리스트</returns>
        [HttpGet("문서리스트/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<문서관리마스터>>> Get문서정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var 문서리스트 = await _context.문서관리마스터
                    .Where(d => d.관제관리번호 == 관제관리번호)
                    .Take(1000)
                    .ToListAsync();

                _logger.LogInformation($"문서 정보 조회 완료: 관제관리번호={관제관리번호}, 결과수={문서리스트.Count}");
                return Ok(문서리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"문서 정보 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 사용자 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>사용자 정보 리스트</returns>
        [HttpGet("사용자정보/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<사용자마스터>>> Get사용자정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT TOP 1000
                        등록번호,
                        관제관리번호,
                        사용자명,
                        직급,
                        휴대전화,
                        계약자와관계,
                        주민번호,
                        OC사용자,
                        비고,
                        무단해제허용,
                        SMS발송,
                        요원카드,
                        미경계SMS,
                        예비카드여부
                    FROM 사용자마스터
                    WHERE 관제관리번호 = @관제관리번호
                    ORDER BY Convert(int, 등록번호)";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 사용자리스트 = new List<사용자마스터>();

                while (await reader.ReadAsync())
                {
                    var userData = new 사용자마스터
                    {
                        등록번호 = reader["등록번호"]?.ToString(),
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        사용자명 = reader["사용자명"]?.ToString(),
                        직급 = reader["직급"]?.ToString(),
                        휴대전화 = reader["휴대전화"]?.ToString(),
                        계약자와관계 = reader["계약자와관계"]?.ToString(),
                        주민번호 = reader["주민번호"]?.ToString(),
                        OC사용자 = reader["OC사용자"]?.ToString(),
                        비고 = reader["비고"]?.ToString(),
                        무단해제허용 = reader["무단해제허용"] == DBNull.Value ? false : Convert.ToBoolean(reader["무단해제허용"]),
                        SMS발송 = reader["SMS발송"] == DBNull.Value ? false : Convert.ToBoolean(reader["SMS발송"]),
                        요원카드 = reader["요원카드"] == DBNull.Value ? false : Convert.ToBoolean(reader["요원카드"]),
                        미경계SMS = reader["미경계SMS"] == DBNull.Value ? false : Convert.ToBoolean(reader["미경계SMS"]),
                        예비카드여부 = reader["예비카드여부"] == DBNull.Value ? false : Convert.ToBoolean(reader["예비카드여부"]),

                    };

                    사용자리스트.Add(userData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"사용자 정보 조회 완료: 관제관리번호={관제관리번호}, 결과수={사용자리스트.Count}");
                return Ok(사용자리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"사용자 정보 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 존정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>존정보 리스트</returns>
        [HttpGet("존정보/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<존마스터>>> Get존정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT TOP 1000
                        존번호,
                        관제관리번호,
                        감지기설치위치,
                        감지기명,
                        비고
                    FROM 존코드테이블
                    WHERE 관제관리번호 = @관제관리번호
                    ORDER BY 존번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 존정보리스트 = new List<존마스터>();

                while (await reader.ReadAsync())
                {
                    var zoneData = new 존마스터
                    {
                        존번호 = reader["존번호"]?.ToString(),
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        감지기설치위치 = reader["감지기설치위치"]?.ToString(),
                        감지기명 = reader["감지기명"]?.ToString(),
                        비고 = reader["비고"]?.ToString()
                    };

                    존정보리스트.Add(zoneData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"존정보 조회 완료: 관제관리번호={관제관리번호}, 결과수={존정보리스트.Count}");
                return Ok(존정보리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"존정보 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 최근 수신신호 조회 (월별 테이블 동적 조회, 페이징 지원)
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <param name="시작일자">검색 시작일자 (YYYY-MM-DD)</param>
        /// <param name="종료일자">검색 종료일자 (YYYY-MM-DD)</param>
        /// <param name="신호필터">신호 필터 (전체신호, 경계해제신호, 처리신호제외)</param>
        /// <param name="오름차순정렬">오름차순 정렬 여부 (기본값: false)</param>
        /// <param name="skip">건너뛸 개수 (기본값: 0)</param>
        /// <param name="take">가져올 개수 (기본값: 100)</param>
        /// <returns>수신신호 리스트 및 전체 개수</returns>
        [HttpGet("최근신호/{관제관리번호}")]
        public async Task<ActionResult> getRecentSignals(
            string 관제관리번호,
            [FromQuery] string? 시작일자,
            [FromQuery] string? 종료일자,
            [FromQuery] string? 신호필터 = "전체신호",
            [FromQuery] bool 오름차순정렬 = false,
            [FromQuery] int skip = 0,
            [FromQuery] int take = 100)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                // 시작일자와 종료일자 파싱
                DateTime startDate;
                DateTime endDate;

                if (!DateTime.TryParse(시작일자, out startDate))
                {
                    return BadRequest(new { message = "시작일자 형식이 올바르지 않습니다." });
                }

                if (!DateTime.TryParse(종료일자, out endDate))
                {
                    return BadRequest(new { message = "종료일자 형식이 올바르지 않습니다." });
                }

                // 월별 테이블 목록 생성 (수신YYYYMM)
                var tableNames = new List<string>();
                var currentDate = new DateTime(startDate.Year, startDate.Month, 1);
                var lastDate = new DateTime(endDate.Year, endDate.Month, 1);

                while (currentDate <= lastDate)
                {
                    tableNames.Add($"수신{currentDate:yyyyMM}");
                    currentDate = currentDate.AddMonths(1);
                }

                if (tableNames.Count == 0)
                {
                    return Ok(new List<수신신호마스터>());
                }

                // 신호 필터 조건 생성
                string 신호필터조건 = "";
                if (신호필터 == "경계해제신호")
                {
                    신호필터조건 = "AND (신호코드마스터.신호명 LIKE N'%경계%' OR 신호코드마스터.신호명 LIKE N'%해제%')";
                }
                else if (신호필터 == "처리신호제외")
                {
                    신호필터조건 = "AND (신호코드마스터.신호명 NOT LIKE N'%처리%' OR 신호코드마스터.신호명 IS NULL)";
                }

                // 동적 SQL 생성
                var unionQueries = new List<string>();

                foreach (var tableName in tableNames)
                {
                    var query = $@"
                        SELECT
                            {tableName}.관제관리번호,
                            관제고객마스터.관제상호,
                            수신일자,
                            수신시간,
                            신호코드마스터.신호명,
                            신호코드,
                            신호존비고 as 비고,
                            관제사용자마스터.성명 as 관제자,
                            관제고객마스터.공중회선,
                            관제고객마스터.전용회선,
                            로그데이터 as 입력내용,
                            신호코드마스터.글자색,
                            신호코드마스터.바탕색
                        FROM {tableName}
                        LEFT JOIN 관제고객마스터
                            ON {tableName}.관제관리번호 = 관제고객마스터.관제관리번호
                        LEFT JOIN 신호코드마스터
                            ON 신호코드마스터.메인코드 = {tableName}.신호코드
                        LEFT JOIN 관제사용자마스터
                            ON 관제사용자마스터.로그인ID = {tableName}.관제자ID
                        WHERE {tableName}.관제관리번호 = @관제관리번호
                            AND {tableName}.수신일자 >= @시작일자
                            AND {tableName}.수신일자 <= @종료일자
                            AND 신호코드마스터.신호명 IS NOT NULL
                            AND 신호코드마스터.신호명 != ''
                            {신호필터조건}";

                    unionQueries.Add(query);
                }

                // UNION ALL로 결합
                var unionQuery = string.Join(" UNION ALL ", unionQueries);

                // 정렬 및 페이징 추가 (ROW_NUMBER를 사용한 구버전 SQL Server 호환 페이징)
                var orderByColumns = 오름차순정렬 ? "수신일자 ASC, 수신시간 ASC" : "수신일자 DESC, 수신시간 DESC";
                var finalQuery = $@"
                    SELECT * FROM (
                        SELECT *, ROW_NUMBER() OVER (ORDER BY {orderByColumns}) AS RowNum
                        FROM ({unionQuery}) AS UnionResult
                    ) AS NumberedResults
                    WHERE RowNum BETWEEN {skip + 1} AND {skip + take}";

                // 쿼리 실행
                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = finalQuery;

                // 파라미터 추가
                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = 관제관리번호;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@시작일자";
                param2.Value = startDate;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@종료일자";
                param3.Value = endDate.AddDays(1).AddSeconds(-1); // 종료일의 23:59:59까지 포함
                command.Parameters.Add(param3);

                using var reader = await command.ExecuteReaderAsync();
                var 신호리스트 = new List<수신신호마스터>();

                while (await reader.ReadAsync())
                {
                    var signal = new 수신신호마스터
                    {
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        관제상호 = reader["관제상호"]?.ToString(),
                        수신일자 = reader["수신일자"] as DateTime?,
                        수신시간 = reader["수신시간"]?.ToString(),
                        신호명 = reader["신호명"]?.ToString(),
                        신호코드 = reader["신호코드"]?.ToString(),
                        비고 = reader["비고"]?.ToString(),
                        관제자 = reader["관제자"]?.ToString(),
                        공중회선 = reader["공중회선"]?.ToString(),
                        전용회선 = reader["전용회선"]?.ToString(),
                        입력내용 = reader["입력내용"]?.ToString(),
                        글자색 = reader["글자색"]?.ToString(),
                        바탕색 = reader["바탕색"]?.ToString()
                    };

                    // SQL에서 이미 필터링되었으므로 모든 데이터 추가
                    신호리스트.Add(signal);
                }

                await connection.CloseAsync();

                // 전체 개수 조회 (필터 적용 후)
                var totalCount = 0;
                await connection.OpenAsync();

                foreach (var tableName in tableNames)
                {
                    var countCmd = connection.CreateCommand();
                    countCmd.CommandText = $@"
                        SELECT COUNT(*)
                        FROM {tableName}
                            LEFT JOIN 신호코드마스터
                            ON 신호코드마스터.메인코드 = {tableName}.신호코드
                        WHERE 관제관리번호 = @관제관리번호
                        AND 수신일자 >= @시작일자
                        AND 수신일자 <= @종료일자
                        AND 신호코드마스터.신호명 IS NOT NULL
                        AND 신호코드마스터.신호명 != ''
                        {신호필터조건}";

                    var p1 = countCmd.CreateParameter();
                    p1.ParameterName = "@관제관리번호";
                    p1.Value = 관제관리번호;
                    countCmd.Parameters.Add(p1);

                    var p2 = countCmd.CreateParameter();
                    p2.ParameterName = "@시작일자";
                    p2.Value = startDate;
                    countCmd.Parameters.Add(p2);

                    var p3 = countCmd.CreateParameter();
                    p3.ParameterName = "@종료일자";
                    p3.Value = endDate.AddDays(1).AddSeconds(-1);
                    countCmd.Parameters.Add(p3);

                    var count = await countCmd.ExecuteScalarAsync();
                    totalCount += Convert.ToInt32(count);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"최근 수신신호 조회 완료: 관제관리번호={관제관리번호}, 시작일자={시작일자}, 종료일자={종료일자}, 신호필터={신호필터}, skip={skip}, take={take}, 결과수={신호리스트.Count}, 전체개수={totalCount}");

                return Ok(new { data = 신호리스트, totalCount = totalCount });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"최근 수신신호 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 검색로그 내역조회
        /// </summary>
        [HttpGet("검색로그내역조회/{관제관리번호}")]
        public async Task<ActionResult> Get검색로그내역(
            string 관제관리번호,
            [FromQuery] string? 시작일자,
            [FromQuery] string? 종료일자,
            [FromQuery] int skip = 0,
            [FromQuery] int take = 100)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                // 시작일자와 종료일자 파싱
                DateTime startDate;
                DateTime endDate;

                if (!DateTime.TryParse(시작일자, out startDate))
                {
                    return BadRequest(new { message = "시작일자 형식이 올바르지 않습니다." });
                }

                if (!DateTime.TryParse(종료일자, out endDate))
                {
                    return BadRequest(new { message = "종료일자 형식이 올바르지 않습니다." });
                }

                // 월별 테이블 목록 생성 (수신YYYYMM)
                var tableNames = new List<string>();
                var currentDate = new DateTime(startDate.Year, startDate.Month, 1);
                var lastDate = new DateTime(endDate.Year, endDate.Month, 1);

                while (currentDate <= lastDate)
                {
                    tableNames.Add($"수신{currentDate:yyyyMM}");
                    currentDate = currentDate.AddMonths(1);
                }

                if (tableNames.Count == 0)
                {
                    return Ok(new { data = new List<검색로그마스터>(), totalCount = 0 });
                }

                // 동적 SQL 생성
                var unionQueries = new List<string>();

                foreach (var tableName in tableNames)
                {
                    var query = $@"
                        SELECT
                            관제사용자마스터.성명,
                            {tableName}.수신일자,
                            {tableName}.수신시간,
                            {tableName}.로그데이터
                        FROM {tableName}
                        INNER JOIN 관제사용자마스터
                            ON 관제사용자마스터.로그인ID = {tableName}.관제자ID
                        WHERE {tableName}.관제관리번호 = @관제관리번호
                            AND {tableName}.수신일자 >= @시작일자
                            AND {tableName}.수신일자 <= @종료일자
                            AND {tableName}.로그데이터 IS NOT NULL AND LEN(로그데이터) > 0";

                    unionQueries.Add(query);
                }

                // UNION ALL로 결합
                var unionQuery = string.Join(" UNION ALL ", unionQueries);

                // 정렬 및 페이징 추가 (ROW_NUMBER를 사용한 구버전 SQL Server 호환 페이징)
                var finalQuery = $@"
                    SELECT * FROM (
                        SELECT *, ROW_NUMBER() OVER (ORDER BY 수신일자 DESC, 수신시간 DESC) AS RowNum
                        FROM ({unionQuery}) AS UnionResult
                    ) AS NumberedResults
                    WHERE RowNum BETWEEN {skip + 1} AND {skip + take}";

                // 쿼리 실행
                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = finalQuery;

                // 파라미터 추가
                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = 관제관리번호;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@시작일자";
                param2.Value = startDate;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@종료일자";
                param3.Value = endDate.AddDays(1).AddSeconds(-1); // 종료일의 23:59:59까지 포함
                command.Parameters.Add(param3);

                using var reader = await command.ExecuteReaderAsync();
                var 로그리스트 = new List<검색로그마스터>();

                while (await reader.ReadAsync())
                {
                    var log = new 검색로그마스터
                    {
                        성명 = reader["성명"]?.ToString(),
                        기록일자 = reader["수신일자"] as DateTime?,
                        기록시간 = reader["수신시간"]?.ToString(),
                        입력내용 = reader["로그데이터"]?.ToString()
                    };

                    로그리스트.Add(log);
                }

                await connection.CloseAsync();

                // 전체 개수 조회
                var totalCount = 0;
                await connection.OpenAsync();

                foreach (var tableName in tableNames)
                {
                    var countCmd = connection.CreateCommand();
                    countCmd.CommandText = $@"
                        SELECT COUNT(*)
                        FROM {tableName}
                        WHERE 관제관리번호 = @관제관리번호
                            AND 수신일자 >= @시작일자
                            AND 수신일자 <= @종료일자
                            AND 로그데이터 IS NOT NULL AND LEN(로그데이터) > 0";

                    var p1 = countCmd.CreateParameter();
                    p1.ParameterName = "@관제관리번호";
                    p1.Value = 관제관리번호;
                    countCmd.Parameters.Add(p1);

                    var p2 = countCmd.CreateParameter();
                    p2.ParameterName = "@시작일자";
                    p2.Value = startDate;
                    countCmd.Parameters.Add(p2);

                    var p3 = countCmd.CreateParameter();
                    p3.ParameterName = "@종료일자";
                    p3.Value = endDate.AddDays(1).AddSeconds(-1);
                    countCmd.Parameters.Add(p3);

                    var count = await countCmd.ExecuteScalarAsync();
                    totalCount += Convert.ToInt32(count);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"검색로그 내역조회 완료: 관제관리번호={관제관리번호}, 시작일자={시작일자}, 종료일자={종료일자}, skip={skip}, take={take}, 결과수={로그리스트.Count}, 전체개수={totalCount}");

                return Ok(new { data = 로그리스트, totalCount = totalCount });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"검색로그 내역조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 고객정보 변동이력 조회
        /// </summary>
        [HttpGet("고객정보변동이력/{관제관리번호}")]
        public async Task<ActionResult> Get고객정보변동이력(
            string 관제관리번호,
            [FromQuery] string? 시작일자,
            [FromQuery] string? 종료일자,
            [FromQuery] int skip = 0,
            [FromQuery] int take = 100)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                // 시작일자와 종료일자 파싱
                DateTime startDate;
                DateTime endDate;

                if (!DateTime.TryParse(시작일자, out startDate))
                {
                    return BadRequest(new { message = "시작일자 형식이 올바르지 않습니다." });
                }

                if (!DateTime.TryParse(종료일자, out endDate))
                {
                    return BadRequest(new { message = "종료일자 형식이 올바르지 않습니다." });
                }

                // 쿼리 생성 (ROW_NUMBER를 사용한 구버전 SQL Server 호환 페이징)
                var query = $@"
                    SELECT * FROM (
                        SELECT
                            관제사용자마스터.성명,
                            고객변경이력마스터.변경처리일자,
                            고객변경이력마스터.변경전,
                            고객변경이력마스터.변경후,
                            고객변경이력마스터.메모,
                            ROW_NUMBER() OVER (ORDER BY 고객변경이력마스터.변경처리일자 DESC) AS RowNum
                        FROM 고객변경이력마스터
                        INNER JOIN 관제사용자마스터
                            ON 관제사용자마스터.로그인ID = 고객변경이력마스터.변경자
                        WHERE 고객변경이력마스터.고객관리번호 = @관제관리번호
                            AND 고객변경이력마스터.변경처리일자 >= @시작일자
                            AND 고객변경이력마스터.변경처리일자 <= @종료일자
                    ) AS NumberedResults
                    WHERE RowNum BETWEEN {skip + 1} AND {skip + take}";

                // 쿼리 실행
                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                // 파라미터 추가
                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = 관제관리번호;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@시작일자";
                param2.Value = startDate;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@종료일자";
                param3.Value = endDate.AddDays(1).AddSeconds(-1); // 종료일의 23:59:59까지 포함
                command.Parameters.Add(param3);

                using var reader = await command.ExecuteReaderAsync();
                var 이력리스트 = new List<고객변경이력마스터>();

                while (await reader.ReadAsync())
                {
                    var history = new 고객변경이력마스터
                    {
                        처리자 = reader["성명"]?.ToString(),
                        변경처리일시 = reader["변경처리일자"] as DateTime?,
                        변경전 = reader["변경전"]?.ToString(),
                        변경후 = reader["변경후"]?.ToString(),
                        메모 = reader["메모"]?.ToString()
                    };

                    이력리스트.Add(history);
                }

                await connection.CloseAsync();

                // 전체 개수 조회
                await connection.OpenAsync();

                var countCmd = connection.CreateCommand();
                countCmd.CommandText = @"
                    SELECT COUNT(*)
                    FROM 고객변경이력마스터
                    WHERE 고객관리번호 = @관제관리번호
                        AND 변경처리일자 >= @시작일자
                        AND 변경처리일자 <= @종료일자";

                var p1 = countCmd.CreateParameter();
                p1.ParameterName = "@관제관리번호";
                p1.Value = 관제관리번호;
                countCmd.Parameters.Add(p1);

                var p2 = countCmd.CreateParameter();
                p2.ParameterName = "@시작일자";
                p2.Value = startDate;
                countCmd.Parameters.Add(p2);

                var p3 = countCmd.CreateParameter();
                p3.ParameterName = "@종료일자";
                p3.Value = endDate.AddDays(1).AddSeconds(-1);
                countCmd.Parameters.Add(p3);

                var count = await countCmd.ExecuteScalarAsync();
                var totalCount = Convert.ToInt32(count);

                await connection.CloseAsync();

                _logger.LogInformation($"고객정보 변동이력 조회 완료: 관제관리번호={관제관리번호}, 시작일자={시작일자}, 종료일자={종료일자}, skip={skip}, take={take}, 결과수={이력리스트.Count}, 전체개수={totalCount}");

                return Ok(new { data = 이력리스트, totalCount = totalCount });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"고객정보 변동이력 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 약도 데이터 조회 (관제관리번호 기준, 최신 데이터 반환)
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>약도 이미지 데이터</returns>
        [HttpGet("약도조회/{관제관리번호}")]
        public async Task<ActionResult> Get약도(string 관제관리번호)
        {
            try
            {
                _logger.LogInformation($"약도 조회 시작: 관제관리번호={관제관리번호}");

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    SELECT TOP 1
                        관제관리번호,
                        등록일자,
                        순번,
                        DATA구분코드,
                        약도데이터,
                        비지오,
                        WMF
                    FROM 약도마스터
                    WHERE 관제관리번호 = @관제관리번호
                    ORDER BY 등록일자 DESC, 순번 DESC
                ";

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    var 약도 = new 약도마스터
                    {
                        관제관리번호 = reader["관제관리번호"]?.ToString(),
                        등록일자 = reader["등록일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["등록일자"]),
                        순번 = reader["순번"]?.ToString(),
                        DATA구분코드 = reader["DATA구분코드"]?.ToString(),
                        약도데이터 = reader["약도데이터"] == DBNull.Value ? null : (byte[])reader["약도데이터"],
                        비지오 = reader["비지오"] == DBNull.Value ? null : (byte[])reader["비지오"],
                        WMF = reader["WMF"] == DBNull.Value ? null : (byte[])reader["WMF"]
                    };

                    await connection.CloseAsync();

                    _logger.LogInformation($"약도 조회 완료: 관제관리번호={관제관리번호}, 등록일자={약도.등록일자}, 순번={약도.순번}");

                    // 바이트 배열을 Base64로 인코딩하여 반환
                    var response = new
                    {
                        관제관리번호 = 약도.관제관리번호,
                        등록일자 = 약도.등록일자,
                        순번 = 약도.순번,
                        DATA구분코드 = 약도.DATA구분코드,
                        약도데이터 = 약도.약도데이터 != null ? Convert.ToBase64String(약도.약도데이터) : null,
                        비지오 = 약도.비지오 != null ? Convert.ToBase64String(약도.비지오) : null,
                        WMF = 약도.WMF != null ? Convert.ToBase64String(약도.WMF) : null
                    };

                    return Ok(response);
                }
                else
                {
                    await connection.CloseAsync();
                    _logger.LogWarning($"약도 데이터 없음: 관제관리번호={관제관리번호}");
                    return NotFound(new { message = "약도 데이터가 없습니다." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"약도 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 도면 데이터 조회 (관제관리번호 기준, 도면마스터 및 도면마스터2 모두 조회)
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>도면 이미지 데이터 리스트</returns>
        [HttpGet("도면조회/{관제관리번호}")]
        public async Task<ActionResult> Get도면(string 관제관리번호)
        {
            try
            {
                _logger.LogInformation($"도면 조회 시작: 관제관리번호={관제관리번호}");

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var 도면리스트 = new List<object>();

                // 도면마스터 조회
                var command1 = connection.CreateCommand();
                command1.CommandText = @"
                    SELECT TOP 1
                        관제관리번호,
                        DATA구분코드,
                        등록일자,
                        도면데이터,
                        비지오
                    FROM 도면마스터
                    WHERE 관제관리번호 = @관제관리번호
                    ORDER BY 등록일자 DESC
                ";

                var param1 = command1.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = 관제관리번호;
                command1.Parameters.Add(param1);

                using (var reader = await command1.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        var 도면데이터 = reader["도면데이터"] == DBNull.Value ? null : (byte[])reader["도면데이터"];
                        var 비지오 = reader["비지오"] == DBNull.Value ? null : (byte[])reader["비지오"];

                        도면리스트.Add(new
                        {
                            관제관리번호 = reader["관제관리번호"]?.ToString(),
                            DATA구분코드 = reader["DATA구분코드"]?.ToString(),
                            등록일자 = reader["등록일자"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["등록일자"]),
                            도면데이터 = 도면데이터 != null ? Convert.ToBase64String(도면데이터) : null,
                            비지오 = 비지오 != null ? Convert.ToBase64String(비지오) : null,
                            테이블명 = "도면마스터"
                        });
                    }
                }

                // 도면마스터2 조회
                var command2 = connection.CreateCommand();
                command2.CommandText = @"
                    SELECT TOP 1
                        관제관리번호,
                        DATA구분코드,
                        등록일자,
                        도면데이터,
                        비지오
                    FROM 도면마스터2
                    WHERE 관제관리번호 = @관제관리번호
                    ORDER BY 등록일자 DESC
                ";

                var param2 = command2.CreateParameter();
                param2.ParameterName = "@관제관리번호";
                param2.Value = 관제관리번호;
                command2.Parameters.Add(param2);

                using (var reader = await command2.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        var 도면데이터 = reader["도면데이터"] == DBNull.Value ? null : (byte[])reader["도면데이터"];
                        var 비지오 = reader["비지오"] == DBNull.Value ? null : (byte[])reader["비지오"];

                        도면리스트.Add(new
                        {
                            관제관리번호 = reader["관제관리번호"]?.ToString(),
                            DATA구분코드 = reader["DATA구분코드"]?.ToString(),
                            등록일자 = reader["등록일자"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["등록일자"]),
                            도면데이터 = 도면데이터 != null ? Convert.ToBase64String(도면데이터) : null,
                            비지오 = 비지오 != null ? Convert.ToBase64String(비지오) : null,
                            테이블명 = "도면마스터2"
                        });
                    }
                }

                await connection.CloseAsync();

                if (도면리스트.Count == 0)
                {
                    _logger.LogWarning($"도면 데이터 없음: 관제관리번호={관제관리번호}");
                    return NotFound(new { message = "도면 데이터가 없습니다." });
                }

                _logger.LogInformation($"도면 조회 완료: 관제관리번호={관제관리번호}, 도면개수={도면리스트.Count}");

                return Ok(도면리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"도면 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 AS접수 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>AS접수 리스트</returns>
        [HttpGet("AS조회/{관제관리번호}")]
        public async Task<ActionResult<IEnumerable<AS접수조회>>> GetAS접수리스트(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var query = @"
                    SELECT
                        관제고객마스터.관제상호,
                        AS접수마스터.고객이름,
                        AS접수마스터.고객연락처,
                        AS접수마스터.요청일자,
                        AS접수마스터.요청시간,
                        AS접수마스터.요청제목,
                        AS접수마스터.접수일자,
                        AS접수마스터.접수시간,
                        AS접수마스터.세부내용,
                        담당자코드마스터.담당자코드명,
                        AS접수마스터.처리여부,
                        관제사용자마스터.성명,
                        AS접수마스터.처리비고
                    FROM AS접수마스터
                    LEFT JOIN 관제고객마스터 ON 관제고객마스터.관제관리번호 = AS접수마스터.관제관리번호
                    LEFT JOIN 담당자코드마스터 ON 담당자코드마스터.담당자코드 = AS접수마스터.담당구역
                    LEFT JOIN 관제사용자마스터 ON 관제사용자마스터.로그인id = AS접수마스터.입력자
                    WHERE AS접수마스터.관제관리번호 = @관제관리번호
                    ORDER BY AS접수마스터.접수일자 DESC, AS접수마스터.접수시간 DESC";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var as접수리스트 = new List<AS접수조회>();

                while (await reader.ReadAsync())
                {
                    var asData = new AS접수조회
                    {
                        관제상호 = reader["관제상호"]?.ToString(),
                        고객이름 = reader["고객이름"]?.ToString(),
                        고객연락처 = reader["고객연락처"]?.ToString(),
                        요청일자 = reader["요청일자"] as DateTime?,
                        요청시간 = reader["요청시간"]?.ToString(),
                        요청제목 = reader["요청제목"]?.ToString(),
                        접수일자 = reader["접수일자"] as DateTime?,
                        접수시간 = reader["접수시간"]?.ToString(),
                        세부내용 = reader["세부내용"]?.ToString(),
                        담당자코드명 = reader["담당자코드명"]?.ToString(),
                        처리여부 = reader["처리여부"]?.ToString(),
                        성명 = reader["성명"]?.ToString(),
                        처리비고 = reader["처리비고"]?.ToString()
                    };

                    as접수리스트.Add(asData);
                }

                await connection.CloseAsync();

                _logger.LogInformation($"AS접수 정보 조회 완료: 관제관리번호={관제관리번호}, 결과수={as접수리스트.Count}");
                return Ok(as접수리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"AS접수 정보 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 고객번호로 영업정보 조회 (ERP 데이터베이스)
        /// </summary>
        /// <param name="customerNumber">고객번호</param>
        /// <returns>영업정보</returns>
        [HttpGet("영업정보/{customerNumber}")]
        public async Task<ActionResult<영업정보>> Get영업정보(string customerNumber)
        {
            try
            {
                _logger.LogInformation($"영업정보 조회 요청: 고객번호={customerNumber}");

                if (string.IsNullOrWhiteSpace(customerNumber))
                {
                    _logger.LogWarning("고객번호가 비어있거나 null입니다.");
                    return BadRequest(new { message = "고객번호는 필수입니다.", receivedValue = customerNumber });
                }

                // ERP DB 연결 확인
                var connection = _erpContext.Database.GetDbConnection();
                if (string.IsNullOrWhiteSpace(connection.ConnectionString))
                {
                    _logger.LogError("ERP 데이터베이스 연결 문자열이 없습니다.");
                    return StatusCode(503, new
                    {
                        message = "ERP_DB_NOT_CONNECTED",
                        detail = "영업DB에 연결되지 않음. 관리자에게 문의하세요."
                    });
                }

                try
                {
                    await connection.OpenAsync();
                }
                catch (Exception dbEx)
                {
                    _logger.LogError(dbEx, "ERP 데이터베이스 연결 실패");
                    return StatusCode(503, new
                    {
                        message = "ERP_DB_NOT_CONNECTED",
                        detail = "영업DB에 연결되지 않음. 관리자에게 문의하세요."
                    });
                }

                // 고객마스터뷰에서 기본 정보 조회
                var customerQuery = @"
                    SELECT
                        고객번호,
                        상호명,
                        고객명,
                        sangtel1,
                        팩스번호,
                        휴대전화1,
                        고객상태코드내용,
                        결제표시,
                        권역명,
                        영업관리자성명,
                        사업자번호,
                        사업자상호,
                        가입대표자,
                        사업자주소1,
                        업태코드,
                        업종코드,
                        전자이메일,
                        월정료,
                        부가세,
                        총매출,
                        가입보증금
                    FROM 고객마스터뷰
                    WHERE 고객번호 = @고객번호";

                var customerCommand = connection.CreateCommand();
                customerCommand.CommandText = customerQuery;
                var customerParam = customerCommand.CreateParameter();
                customerParam.ParameterName = "@고객번호";
                customerParam.Value = customerNumber;
                customerCommand.Parameters.Add(customerParam);

                영업정보? salesInfo = null;

                using (var reader = await customerCommand.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        salesInfo = new 영업정보
                        {
                            // 기본정보
                            고객번호 = reader["고객번호"]?.ToString(),
                            상호명 = reader["상호명"]?.ToString(),
                            대표자 = reader["고객명"]?.ToString(),
                            상호전화 = reader["sangtel1"]?.ToString(),
                            팩스번호 = reader["팩스번호"]?.ToString(),
                            휴대전화 = reader["휴대전화1"]?.ToString(),
                            고객상태 = reader["고객상태코드내용"]?.ToString(),
                            납입방법 = reader["결제표시"]?.ToString(),
                            담당권역 = reader["권역명"]?.ToString(),
                            신규판매자 = reader["영업관리자성명"]?.ToString(),

                            // 사업자정보
                            사업자등록번호 = reader["사업자번호"]?.ToString(),
                            사업자상호 = reader["사업자상호"]?.ToString(),
                            사업자대표자 = reader["가입대표자"]?.ToString(),
                            사업장주소 = reader["사업자주소1"]?.ToString(),
                            업태 = reader["업태코드"]?.ToString(),
                            종목 = reader["업종코드"]?.ToString(),
                            계산서이메일 = reader["전자이메일"]?.ToString(),

                            // 월정료 정보
                            월정료 = reader["월정료"] == DBNull.Value ? null : Convert.ToDecimal(reader["월정료"]),
                            VAT = reader["부가세"] == DBNull.Value ? null : Convert.ToDecimal(reader["부가세"]),
                            총금액 = reader["총매출"] == DBNull.Value ? null : Convert.ToDecimal(reader["총매출"]),
                            보증금 = reader["가입보증금"] == DBNull.Value ? null : Convert.ToDecimal(reader["가입보증금"]),
                            통합관리건수 = 0
                        };
                    }
                }

                if (salesInfo == null)
                {
                    await connection.CloseAsync();
                    return NotFound(new { message = $"고객번호 {customerNumber}에 해당하는 영업정보를 찾을 수 없습니다." });
                }

                // 매출마스터뷰에서 미납 정보 조회
                var unpaidQuery = @"
                    SELECT
                        청구금액 as 미납총금액,
                        COUNT(수금여부) as 미납월분
                    FROM 매출마스터뷰
                    WHERE 고객번호 = @고객번호
                        AND 수금여부 = 0
                    GROUP BY 청구금액";

                var unpaidCommand = connection.CreateCommand();
                unpaidCommand.CommandText = unpaidQuery;
                var unpaidParam = unpaidCommand.CreateParameter();
                unpaidParam.ParameterName = "@고객번호";
                unpaidParam.Value = customerNumber;
                unpaidCommand.Parameters.Add(unpaidParam);

                using (var reader = await unpaidCommand.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        salesInfo.미납총금액 = reader["미납총금액"] == DBNull.Value ? null : Convert.ToDecimal(reader["미납총금액"]);
                        salesInfo.미납월분 = reader["미납월분"] == DBNull.Value ? null : Convert.ToInt32(reader["미납월분"]);
                    }
                }

                await connection.CloseAsync();

                _logger.LogInformation($"영업정보 조회 완료: 고객번호={customerNumber}");
                return Ok(salesInfo);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"영업정보 조회 중 오류 발생: 고객번호={customerNumber}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 고객번호로 최근수금이력 조회 (ERP 데이터베이스)
        /// </summary>
        /// <param name="customerNumber">고객번호</param>
        /// <returns>최근수금이력 리스트</returns>
        [HttpGet("최근수금이력/{customerNumber}")]
        public async Task<ActionResult<IEnumerable<매출마스터뷰>>> Get최근수금이력(string customerNumber)
        {
            try
            {
                _logger.LogInformation($"최근수금이력 조회 요청: 고객번호={customerNumber}");

                if (string.IsNullOrWhiteSpace(customerNumber))
                {
                    _logger.LogWarning("고객번호가 비어있거나 null입니다.");
                    return BadRequest(new { message = "고객번호는 필수입니다.", receivedValue = customerNumber });
                }

                // ERP DB 연결 확인
                var connection = _erpContext.Database.GetDbConnection();
                if (string.IsNullOrWhiteSpace(connection.ConnectionString))
                {
                    _logger.LogError("ERP 데이터베이스 연결 문자열이 없습니다.");
                    return StatusCode(503, new
                    {
                        message = "ERP_DB_NOT_CONNECTED",
                        detail = "영업DB에 연결되지 않음. 관리자에게 문의하세요."
                    });
                }

                try
                {
                    await connection.OpenAsync();
                }
                catch (Exception dbEx)
                {
                    _logger.LogError(dbEx, "ERP 데이터베이스 연결 실패");
                    return StatusCode(503, new
                    {
                        message = "ERP_DB_NOT_CONNECTED",
                        detail = "영업DB에 연결되지 않음. 관리자에게 문의하세요."
                    });
                }

                // 최근수금이력 조회
                var query = @"
                    SELECT TOP (1000)
                        매출년월,
                        청구금액,
                        실입금액,
                        입금방법코드마스터.입금방법코드명,
                        납입일자,
                        수금여부,
                        인사관리마스터.성명,
                        비고
                    FROM [NeoERP].[dbo].[매출마스터뷰]
                    LEFT JOIN 입금방법코드마스터 ON 입금방법코드마스터.입금방법코드 = 매출마스터뷰.입금방법코드
                    LEFT JOIN 인사관리마스터 ON 인사관리마스터.사번 = 매출마스터뷰.처리자ID
                    WHERE 고객번호 = @고객번호
                    ORDER BY 매출년월 DESC";

                var command = connection.CreateCommand();
                command.CommandText = query;
                var param = command.CreateParameter();
                param.ParameterName = "@고객번호";
                param.Value = customerNumber;
                command.Parameters.Add(param);

                var paymentHistoryList = new List<매출마스터뷰>();

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        var 수금여부 = reader["수금여부"] != DBNull.Value && Convert.ToBoolean(reader["수금여부"]);

                        paymentHistoryList.Add(new 매출마스터뷰
                        {
                            매출년월 = reader["매출년월"]?.ToString(),
                            청구금액 = reader["청구금액"] == DBNull.Value ? null : Convert.ToDecimal(reader["청구금액"]),
                            실입금액 = reader["실입금액"] == DBNull.Value ? null : Convert.ToDecimal(reader["실입금액"]),
                            입금방법 = reader["입금방법코드명"]?.ToString(),
                            납입일자 = reader["납입일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["납입일자"]),
                            수금여부 = reader["수금여부"] == DBNull.Value ? false : Convert.ToBoolean(reader["수금여부"]),
                            처리자 = reader["성명"]?.ToString(),
                            비고 = reader["비고"]?.ToString()
                        });
                    }
                }

                await connection.CloseAsync();

                _logger.LogInformation($"최근수금이력 조회 완료: 고객번호={customerNumber}, 결과수={paymentHistoryList.Count}");
                return Ok(paymentHistoryList);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"최근수금이력 조회 중 오류 발생: 고객번호={customerNumber}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 고객번호로 최근 방문 및 A/S이력 조회 (ERP 데이터베이스)
        /// </summary>
        /// <param name="customerNumber">고객번호</param>
        /// <returns>최근 방문 및 A/S이력 리스트</returns>
        [HttpGet("방문AS조회/{customerNumber}")]
        public async Task<ActionResult<IEnumerable<AS접수마스터뷰>>> Get최근방문AS이력(string customerNumber)
        {
            try
            {
                _logger.LogInformation($"최근 방문 및 A/S이력 조회 요청: 고객번호={customerNumber}");

                if (string.IsNullOrWhiteSpace(customerNumber))
                {
                    _logger.LogWarning("고객번호가 비어있거나 null입니다.");
                    return BadRequest(new { message = "고객번호는 필수입니다.", receivedValue = customerNumber });
                }

                // ERP DB 연결 확인
                var connection = _erpContext.Database.GetDbConnection();
                if (string.IsNullOrWhiteSpace(connection.ConnectionString))
                {
                    _logger.LogError("ERP 데이터베이스 연결 문자열이 없습니다.");
                    return StatusCode(503, new
                    {
                        message = "ERP_DB_NOT_CONNECTED",
                        detail = "영업DB에 연결되지 않음. 관리자에게 문의하세요."
                    });
                }

                try
                {
                    await connection.OpenAsync();
                }
                catch (Exception dbEx)
                {
                    _logger.LogError(dbEx, "ERP 데이터베이스 연결 실패");
                    return StatusCode(503, new
                    {
                        message = "ERP_DB_NOT_CONNECTED",
                        detail = "영업DB에 연결되지 않음. 관리자에게 문의하세요."
                    });
                }

                // 최근 방문 및 A/S이력 조회
                var query = @"
                    SELECT TOP (1000)
                        요청일자,
                        권역명,
                        요청제목,
                        처리여부,
                        처리일시,
                        처리비고,
                        입력자성명,
                        처리자성명,
                        처리개인
                    FROM AS접수마스터뷰
                    WHERE 고객번호 = @고객번호
                    ORDER BY 요청일자 DESC";

                var command = connection.CreateCommand();
                command.CommandText = query;
                var param = command.CreateParameter();
                param.ParameterName = "@고객번호";
                param.Value = customerNumber;
                command.Parameters.Add(param);

                var visitAsHistoryList = new List<AS접수마스터뷰>();

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        var 처리여부 = reader["처리여부"] != DBNull.Value && Convert.ToBoolean(reader["처리여부"]);

                        visitAsHistoryList.Add(new AS접수마스터뷰
                        {
                            요청일자 = reader["요청일자"]?.ToString(),
                            권역명 = reader["권역명"]?.ToString(),
                            요청제목 = reader["요청제목"]?.ToString(),
                            처리여부 = reader["처리여부"] == DBNull.Value ? false : Convert.ToBoolean(reader["처리여부"]),
                            처리일시 = reader["처리일시"]?.ToString(),
                            처리비고 = reader["처리비고"]?.ToString(),
                            접수자성명 = reader["입력자성명"]?.ToString(),
                            처리자성명 = reader["처리자성명"]?.ToString(),
                            개인AS처리자 = reader["처리개인"]?.ToString()
                        });
                    }
                }

                await connection.CloseAsync();

                _logger.LogInformation($"최근 방문 및 A/S이력 조회 완료: 고객번호={customerNumber}, 결과수={visitAsHistoryList.Count}");
                return Ok(visitAsHistoryList);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"최근 방문 및 A/S이력 조회 중 오류 발생: 고객번호={customerNumber}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 관제개시 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>관제개시 정보 리스트</returns>
        [HttpGet("관제개시조회/{관제관리번호}/")]
        public async Task<ActionResult> Get관제개시(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    SELECT TOP (1000)
                        [경비개시일자],
                        [존점검결과],
                        [키테스트],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [점검자],
                        [관제확인자],
                        [설치공사자],
                        [키인수자],
                        [비고사항]
                    FROM [neosecurity_Ring].[dbo].[관제개시마스터]
                    WHERE 관제관리번호 = @관제관리번호
                ";

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 개시리스트 = new List<object>();

                while (await reader.ReadAsync())
                {
                    개시리스트.Add(new
                    {
                        개시 = reader["경비개시일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["경비개시일자"]).ToString("yyyy-MM-dd"),
                        ZONECK = reader["존점검결과"] == DBNull.Value ? false : Convert.ToBoolean(reader["존점검결과"]),
                        KEYCK = reader["키테스트"] == DBNull.Value ? false : Convert.ToBoolean(reader["키테스트"]),
                        KEYS = reader["키수량"] == DBNull.Value ? 0 : Convert.ToInt32(reader["키수량"]),
                        도면 = reader["도면점검"] == DBNull.Value ? false : Convert.ToBoolean(reader["도면점검"]),
                        고객카드 = reader["고객카드"] == DBNull.Value ? false : Convert.ToBoolean(reader["고객카드"]),
                        개시처리자 = reader["점검자"]?.ToString(),
                        관제확인자 = reader["관제확인자"]?.ToString(),
                        설치공사자 = reader["설치공사자"]?.ToString(),
                        키인수자 = reader["키인수자"]?.ToString(),
                        비고 = reader["비고사항"]?.ToString()
                    });
                }

                await connection.CloseAsync();

                _logger.LogInformation($"관제개시 조회 완료: 관제관리번호={관제관리번호}, 결과수={개시리스트.Count}");
                return Ok(개시리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"관제개시 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제개시 정보 추가
        /// </summary>
        /// <param name="request">관제개시 정보</param>
        /// <returns>추가 결과</returns>
        [HttpPost("관제개시정보추가")]
        public async Task<ActionResult> Post관제개시([FromBody] 관제개시Request request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    INSERT INTO [neosecurity_Ring].[dbo].[관제개시마스터]
                    (
                        [관제관리번호],
                        [경비개시일자],
                        [존점검결과],
                        [키테스트],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [점검자],
                        [관제확인자],
                        [설치공사자],
                        [키인수자],
                        [비고사항]
                    )
                    VALUES
                    (
                        @관제관리번호,
                        @경비개시일자,
                        @존점검결과,
                        @키테스트,
                        @키수량,
                        @도면점검,
                        @고객카드,
                        @점검자,
                        @관제확인자,
                        @설치공사자,
                        @키인수자,
                        @비고사항
                    )
                ";

                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = request.관제관리번호;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@경비개시일자";
                param2.Value = request.경비개시일자.HasValue ? request.경비개시일자.Value : DBNull.Value;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@존점검결과";
                param3.Value = request.존점검결과.HasValue ? request.존점검결과.Value : DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@키테스트";
                param4.Value = request.키테스트.HasValue ? request.키테스트.Value : DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@키수량";
                param5.Value = request.키수량.HasValue ? request.키수량.Value : DBNull.Value;
                command.Parameters.Add(param5);

                var param6 = command.CreateParameter();
                param6.ParameterName = "@도면점검";
                param6.Value = request.도면점검.HasValue ? request.도면점검.Value : DBNull.Value;
                command.Parameters.Add(param6);

                var param7 = command.CreateParameter();
                param7.ParameterName = "@고객카드";
                param7.Value = request.고객카드.HasValue ? request.고객카드.Value : DBNull.Value;
                command.Parameters.Add(param7);

                var param8 = command.CreateParameter();
                param8.ParameterName = "@점검자";
                param8.Value = string.IsNullOrWhiteSpace(request.점검자) ? DBNull.Value : request.점검자;
                command.Parameters.Add(param8);

                var param9 = command.CreateParameter();
                param9.ParameterName = "@관제확인자";
                param9.Value = string.IsNullOrWhiteSpace(request.관제확인자) ? DBNull.Value : request.관제확인자;
                command.Parameters.Add(param9);

                var param10 = command.CreateParameter();
                param10.ParameterName = "@설치공사자";
                param10.Value = string.IsNullOrWhiteSpace(request.설치공사자) ? DBNull.Value : request.설치공사자;
                command.Parameters.Add(param10);

                var param11 = command.CreateParameter();
                param11.ParameterName = "@키인수자";
                param11.Value = string.IsNullOrWhiteSpace(request.키인수자) ? DBNull.Value : request.키인수자;
                command.Parameters.Add(param11);

                var param12 = command.CreateParameter();
                param12.ParameterName = "@비고사항";
                param12.Value = string.IsNullOrWhiteSpace(request.비고사항) ? DBNull.Value : request.비고사항;
                command.Parameters.Add(param12);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"관제개시 추가 완료: 관제관리번호={request.관제관리번호}");
                return StatusCode(201, new { message = "관제개시 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "관제개시 추가 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제관리번호로 보수점검 완료이력 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>보수점검 완료이력 리스트</returns>
        [HttpGet("보수점검조회/{관제관리번호}")]
        public async Task<ActionResult> Get보수점검(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    SELECT TOP (1000)
                        [발생자],
                        [점검기준월],
                        [존점검],
                        [키테스트],
                        [키예탁],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [처리자],
                        [고객요청사항]
                    FROM [neosecurity_Ring].[dbo].[보수점검지시마스터]
                    WHERE 관제관리번호 = @관제관리번호 AND 처리완료여부 = '1'
                ";

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 점검리스트 = new List<object>();

                while (await reader.ReadAsync())
                {
                    점검리스트.Add(new
                    {
                        지시자 = reader["발생자"]?.ToString(),
                        점검기준월 = reader["점검기준월"] == DBNull.Value ? null : Convert.ToDateTime(reader["점검기준월"]).ToString("yyyy-MM-dd"),
                        존점검 = reader["존점검"] == DBNull.Value ? false : Convert.ToBoolean(reader["존점검"]),
                        키테스트 = reader["키테스트"] == DBNull.Value ? false : Convert.ToBoolean(reader["키테스트"]),
                        키예탁 = reader["키예탁"] == DBNull.Value ? false : Convert.ToBoolean(reader["키예탁"]),
                        키수량 = reader["키수량"] == DBNull.Value ? 0 : Convert.ToInt32(reader["키수량"]),
                        도면점검 = reader["도면점검"] == DBNull.Value ? false : Convert.ToBoolean(reader["도면점검"]),
                        고객카드 = reader["고객카드"] == DBNull.Value ? false : Convert.ToBoolean(reader["고객카드"]),
                        점검완료자 = reader["처리자"]?.ToString(),
                        고객요청사항 = reader["고객요청사항"]?.ToString()
                    });
                }

                await connection.CloseAsync();

                _logger.LogInformation($"보수점검 완료이력 조회 완료: 관제관리번호={관제관리번호}, 결과수={점검리스트.Count}");
                return Ok(점검리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"보수점검 완료이력 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 보수점검 정보 추가
        /// </summary>
        /// <param name="request">보수점검 정보</param>
        /// <returns>추가 결과</returns>
        [HttpPost("보수점검추가")]
        public async Task<ActionResult> Post보수점검([FromBody] 보수점검Request request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    INSERT INTO [neosecurity_Ring].[dbo].[보수점검지시마스터]
                    (
                        [관제관리번호],
                        [발생자],
                        [점검기준월],
                        [처리일자],
                        [존점검],
                        [키테스트],
                        [키예탁],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [처리자],
                        [고객요청사항],
                        [처리완료여부]
                    )
                    VALUES
                    (
                        @관제관리번호,
                        @발생자,
                        @점검기준월,
                        @처리일자,
                        @존점검,
                        @키테스트,
                        @키예탁,
                        @키수량,
                        @도면점검,
                        @고객카드,
                        @처리자,
                        @고객요청사항,
                        '1'
                    )
                ";

                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = request.관제관리번호;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@발생자";
                param2.Value = string.IsNullOrWhiteSpace(request.발생자) ? DBNull.Value : request.발생자;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@점검기준월";
                param3.Value = request.점검기준월.HasValue ? request.점검기준월.Value : DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@처리일자";
                param4.Value = request.처리일자.HasValue ? request.처리일자.Value : DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@존점검";
                param5.Value = request.존점검.HasValue ? request.존점검.Value : DBNull.Value;
                command.Parameters.Add(param5);

                var param6 = command.CreateParameter();
                param6.ParameterName = "@키테스트";
                param6.Value = request.키테스트.HasValue ? request.키테스트.Value : DBNull.Value;
                command.Parameters.Add(param6);

                var param7 = command.CreateParameter();
                param7.ParameterName = "@키예탁";
                param7.Value = request.키예탁.HasValue ? request.키예탁.Value : DBNull.Value;
                command.Parameters.Add(param7);

                var param8 = command.CreateParameter();
                param8.ParameterName = "@키수량";
                param8.Value = request.키수량.HasValue ? request.키수량.Value : DBNull.Value;
                command.Parameters.Add(param8);

                var param9 = command.CreateParameter();
                param9.ParameterName = "@도면점검";
                param9.Value = request.도면점검.HasValue ? request.도면점검.Value : DBNull.Value;
                command.Parameters.Add(param9);

                var param10 = command.CreateParameter();
                param10.ParameterName = "@고객카드";
                param10.Value = request.고객카드.HasValue ? request.고객카드.Value : DBNull.Value;
                command.Parameters.Add(param10);

                var param11 = command.CreateParameter();
                param11.ParameterName = "@처리자";
                param11.Value = string.IsNullOrWhiteSpace(request.처리자) ? DBNull.Value : request.처리자;
                command.Parameters.Add(param11);

                var param12 = command.CreateParameter();
                param12.ParameterName = "@고객요청사항";
                param12.Value = string.IsNullOrWhiteSpace(request.고객요청사항) ? DBNull.Value : request.고객요청사항;
                command.Parameters.Add(param12);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"보수점검 추가 완료: 관제관리번호={request.관제관리번호}");
                return StatusCode(201, new { message = "보수점검 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "보수점검 추가 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 개통코드로 개통업체 정보 검증
        /// </summary>
        /// <param name="code">개통코드</param>
        /// <returns>개통업체 정보</returns>
        [HttpGet("개통코드인증/{code}")]
        public ActionResult<OpeningCompany> VerifyOpeningCode(string code)
        {
            // 개통업체 정보 리스트 (하드코딩)
            var companies = ConnectionString.GetCompanies();

            var company = companies.FirstOrDefault(c => c.개통코드 == code);

            if (company == null)
            {
                return NotFound(new { message = "개통코드가 일치하지 않습니다." });
            }

            // appsettings.json의 SecurityConnection을 업데이트
            try
            {
                var connectionString = company.GetConnectionString();

                // 메모리 내 설정 업데이트
                _configuration["ConnectionStrings:SecurityConnection"] = connectionString;

                // appsettings.json 파일 직접 수정
                UpdateAppSettingsJson(connectionString);

                _logger.LogInformation($"SecurityConnection updated for company: {company.개통업체명}");
                _logger.LogInformation($"New connection string: {connectionString}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Failed to update SecurityConnection: {ex.Message}");
            }

            return Ok(company);
        }

        /// <summary>
        /// appsettings.json 파일의 SecurityConnection 업데이트
        /// </summary>
        /// <param name="connectionString">새로운 연결 문자열</param>
        private void UpdateAppSettingsJson(string connectionString)
        {
            try
            {
                // appsettings.json 파일 경로
                var appSettingsPath = Path.Combine(AppContext.BaseDirectory, "appsettings.json");

                if (!System.IO.File.Exists(appSettingsPath))
                {
                    _logger.LogWarning($"appsettings.json file not found at: {appSettingsPath}");
                    return;
                }

                // 파일 읽기
                var json = System.IO.File.ReadAllText(appSettingsPath);
                var jsonDocument = JsonDocument.Parse(json);
                var root = jsonDocument.RootElement;

                // Dictionary로 변환
                var settings = new Dictionary<string, object>();
                foreach (var property in root.EnumerateObject())
                {
                    if (property.Name == "ConnectionStrings")
                    {
                        var connectionStrings = new Dictionary<string, object>();
                        foreach (var conn in property.Value.EnumerateObject())
                        {
                            if (conn.Name == "SecurityConnection")
                            {
                                connectionStrings[conn.Name] = connectionString;
                            }
                            else
                            {
                                connectionStrings[conn.Name] = conn.Value.GetString() ?? "";
                            }
                        }
                        settings[property.Name] = connectionStrings;
                    }
                    else
                    {
                        settings[property.Name] = JsonSerializer.Deserialize<object>(property.Value.GetRawText()) ?? new object();
                    }
                }

                // JSON으로 직렬화
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                };
                var updatedJson = JsonSerializer.Serialize(settings, options);

                // 파일 쓰기
                System.IO.File.WriteAllText(appSettingsPath, updatedJson);

                _logger.LogInformation($"appsettings.json updated successfully at: {appSettingsPath}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Failed to update appsettings.json: {ex.Message}");
            }
        }

        /// <summary>
        /// 로그인 검증
        /// </summary>
        /// <param name="id">사용자 ID</param>
        /// <param name="password">사용자 비밀번호</param>
        /// <returns>로그인 사용자 정보</returns>
        [HttpPost("로그인")]
        public async Task<ActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                var query = @"
                    SELECT TOP 1
                        로그인id,
                        성명,
                        ID,
                        PASS,
                        사용여부,
                        지역코드,
                        최종로그인
                    FROM [neosecurity_Ring].[dbo].[관제사용자마스터]
                    WHERE ID = @ID
                    ORDER BY 로그인id";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var idParam = command.CreateParameter();
                idParam.ParameterName = "@ID";
                idParam.Value = request.Id;
                command.Parameters.Add(idParam);

                using var reader = await command.ExecuteReaderAsync();

                if (!await reader.ReadAsync())
                {
                    await connection.CloseAsync();
                    return Unauthorized(new { message = "아이디 또는 비밀번호가 일치하지 않습니다." });
                }

                var 사용여부 = reader["사용여부"] != DBNull.Value && Convert.ToBoolean(reader["사용여부"]);
                var 저장된비밀번호 = reader["PASS"]?.ToString() ?? string.Empty;

                // 사용여부 확인
                if (!사용여부)
                {
                    await connection.CloseAsync();
                    return Unauthorized(new { message = "로그인 권한이 없습니다." });
                }

                // 비밀번호 확인
                if (저장된비밀번호 != request.Password)
                {
                    await connection.CloseAsync();
                    return Unauthorized(new { message = "아이디 또는 비밀번호가 일치하지 않습니다." });
                }

                // 로그인 성공 - 사용자 정보 반환
                var loginUser = new
                {
                    로그인id = Convert.ToInt32(reader["로그인id"]),
                    성명 = reader["성명"]?.ToString() ?? string.Empty,
                    ID = reader["ID"]?.ToString() ?? string.Empty,
                    지역코드 = reader["지역코드"]?.ToString() ?? string.Empty,
                    최종로그인 = reader["최종로그인"] != DBNull.Value
                        ? Convert.ToDateTime(reader["최종로그인"])
                        : (DateTime?)null
                };

                await connection.CloseAsync();

                // 최종로그인 시간 업데이트
                await UpdateLastLoginTime(loginUser.로그인id);

                return Ok(loginUser);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "로그인 처리 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 최종로그인 시간 업데이트
        /// </summary>
        private async Task UpdateLastLoginTime(int 로그인id)
        {
            try
            {
                var query = @"
                    UPDATE [neosecurity_Ring].[dbo].[관제사용자마스터]
                    SET 최종로그인 = GETDATE()
                    WHERE 로그인id = @로그인id";

                var connection = _context.Database.GetDbConnection();
                if (connection.State != System.Data.ConnectionState.Open)
                {
                    await connection.OpenAsync();
                }

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var idParam = command.CreateParameter();
                idParam.ParameterName = "@로그인id";
                idParam.Value = 로그인id;
                command.Parameters.Add(idParam);

                await command.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "최종로그인 시간 업데이트 중 오류 발생");
            }
        }
    }

    /// <summary>
    /// 관제개시 추가 요청 모델
    /// </summary>
    public class 관제개시Request
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public DateTime? 경비개시일자 { get; set; }
        public bool? 존점검결과 { get; set; }
        public bool? 키테스트 { get; set; }
        public int? 키수량 { get; set; }
        public bool? 도면점검 { get; set; }
        public bool? 고객카드 { get; set; }
        public string? 점검자 { get; set; }
        public string? 관제확인자 { get; set; }
        public string? 설치공사자 { get; set; }
        public string? 키인수자 { get; set; }
        public string? 비고사항 { get; set; }
    }

    /// <summary>
    /// 보수점검 추가 요청 모델
    /// </summary>
    public class 보수점검Request
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public string? 발생자 { get; set; }
        public DateTime? 점검기준월 { get; set; }
        public DateTime? 처리일자 { get; set; }
        public bool? 존점검 { get; set; }
        public bool? 키테스트 { get; set; }
        public bool? 키예탁 { get; set; }
        public int? 키수량 { get; set; }
        public bool? 도면점검 { get; set; }
        public bool? 고객카드 { get; set; }
        public string? 처리자 { get; set; }
        public string? 고객요청사항 { get; set; }
    }

    /// <summary>
    /// 개통업체 정보 모델
    /// </summary>
    public class OpeningCompany
    {
        public int 일련번호 { get; set; }
        public string 개통업체명 { get; set; } = string.Empty;
        public string 개통코드 { get; set; } = string.Empty;
        public string DB서버 { get; set; } = string.Empty;
        public string 포트 { get; set; } = string.Empty;
        public string DB명 { get; set; } = string.Empty;
        public string 사용자ID { get; set; } = string.Empty;
        public string 비밀번호 { get; set; } = string.Empty;

        /// <summary>
        /// 연결 문자열 생성
        /// </summary>
        public string GetConnectionString()
        {
            return $"Server={DB서버},{포트};Database={DB명};User Id={사용자ID};Password={비밀번호};TrustServerCertificate=True;";
        }
    }

    /// <summary>
    /// 로그인 요청 모델
    /// </summary>
    public class LoginRequest
    {
        public string Id { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
