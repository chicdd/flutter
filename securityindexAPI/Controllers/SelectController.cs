using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;
using System.Diagnostics;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api/관제고객")]
    public class SelectController : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly neo_erpaDBContext _erpContext;
        private readonly ILogger<SelectController> _logger;

        public SelectController(SecurityRingDBContext context, neo_erpaDBContext erpContext, ILogger<SelectController> logger)
        {
            _context = context;
            _erpContext = erpContext;
            _logger = logger;
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
                var 고객리스트 = await _context.관제고객마스터뷰
                    .Select(c => new 고객검색
                    {
                        관제관리번호 = c.관제관리번호,
                        관제상호 = c.관제상호,
                        관제고객상태코드명 = c.관제고객상태코드명 ?? string.Empty,
                        물건주소 = c.물건주소 ?? string.Empty,
                        대표자 = c.대표자,
                        관제연락처1 = c.관제연락처1
                    })
                    .Take(100)
                    .ToListAsync();

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
        /// <returns>관제고객 리스트</returns>
        [HttpGet("top")]
        public async Task<ActionResult<IEnumerable<고객검색>>> GetTop관제고객([FromQuery] int count = 100)
        {
            try
            {
                if (count <= 0 || count > 1000)
                {
                    return BadRequest(new { message = "count는 1에서 1000 사이의 값이어야 합니다." });
                }

                var 고객리스트 = await _context.관제고객마스터뷰
                    .Select(c => new 고객검색
                    {
                        관제관리번호 = c.관제관리번호,
                        관제상호 = c.관제상호,
                        관제고객상태코드명 = c.관제고객상태코드명 ?? string.Empty,
                        물건주소 = c.물건주소 ?? string.Empty,
                        대표자 = c.대표자,
                        관제연락처1 = c.관제연락처1
                    })
                    .Take(count)
                    .ToListAsync();

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

                var 고객상세 = await _context.관제고객마스터뷰
                    .Where(c => c.관제관리번호 == 관제관리번호)
                    .FirstOrDefaultAsync();

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
            [FromQuery] int count = 100)
        {
            try
            {
                if (count <= 0 || count > 1000)
                {
                    return BadRequest(new { message = "count는 1에서 1000 사이의 값이어야 합니다." });
                }

                IQueryable<관제고객마스터> queryable;

                // 휴대전화 필터는 사용자마스터 테이블과 JOIN 필요
                if (filterType == "사용자HP" && !string.IsNullOrWhiteSpace(query))
                {
                    var searchQuery = query.Trim().ToLower();

                    // JOIN을 사용하여 OPENJSON 문제 회피
                    queryable = from 관 in _context.관제고객마스터뷰
                                join 사용자 in _context.사용자마스터
                                    on 관.관제관리번호 equals 사용자.관제관리번호
                                where 사용자.휴대전화 != null && 사용자.휴대전화.ToLower().Contains(searchQuery)
                                select 관;

                    _logger.LogInformation($"휴대전화 검색: query={query}");
                }
                else
                {
                    // 다른 필터들은 관제고객마스터뷰에서 직접 검색
                    queryable = _context.관제고객마스터뷰.AsQueryable();

                    // 검색어가 있는 경우에만 필터링 적용
                    if (!string.IsNullOrWhiteSpace(query))
                    {
                        var searchQuery = query.Trim().ToLower();

                        queryable = filterType switch
                        {
                            "고객번호" => queryable.Where(c => c.관제관리번호.ToLower().Contains(searchQuery)),
                            "상호" => queryable.Where(c => c.관제상호.ToLower().Contains(searchQuery)),
                            "대표자" => queryable.Where(c => c.대표자 != null && c.대표자.ToLower().Contains(searchQuery)),
                            "물건주소" => queryable.Where(c => c.물건주소 != null && c.물건주소.ToLower().Contains(searchQuery)),
                            // 전화번호는 관제연락처1 열에서 검색
                            "전화번호" => queryable.Where(c => c.관제연락처1 != null && c.관제연락처1.ToLower().Contains(searchQuery)),
                            "관제연락처1" => queryable.Where(c => c.관제연락처1 != null && c.관제연락처1.ToLower().Contains(searchQuery)),
                            _ => queryable.Where(c =>
                                c.관제관리번호.ToLower().Contains(searchQuery) ||
                                c.관제상호.ToLower().Contains(searchQuery) ||
                                (c.대표자 != null && c.대표자.ToLower().Contains(searchQuery)) ||
                                (c.물건주소 != null && c.물건주소.ToLower().Contains(searchQuery)))
                        };
                    }
                }


                // 정렬 적용
                queryable = sortType switch
                {
                    "상호정렬" => queryable.OrderBy(c => c.관제상호),
                    "번호정렬" or _ => queryable.OrderBy(c => c.관제관리번호)
                };

                // 필요한 필드만 선택하여 고객검색 객체로 변환
                var finalQuery = queryable
                    .Select(c => new 고객검색
                    {
                        관제관리번호 = c.관제관리번호,
                        관제상호 = c.관제상호,
                        관제고객상태코드명 = c.관제고객상태코드명 ?? string.Empty,
                        물건주소 = c.물건주소 ?? string.Empty,
                        대표자 = c.대표자,
                        관제연락처1 = c.관제연락처1
                    })
                    .Take(count);

                // 최종 SQL 쿼리 디버그 출력
                var sqlQuery = finalQuery.ToQueryString();
                Debug.WriteLine("=== 관제고객 검색 SQL 쿼리 ===");
                Debug.WriteLine($"FilterType: {filterType}, Query: {query}, SortType: {sortType}, Count: {count}");
                Debug.WriteLine(sqlQuery);
                Debug.WriteLine("================================");

                _logger.LogDebug($"실행 SQL: {sqlQuery}");

                var 고객리스트 = await finalQuery.ToListAsync();

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
        [HttpGet("{관제관리번호}/holiday")]
        public async Task<ActionResult<IEnumerable<휴일주간>>> Get휴일주간(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var 휴일주간리스트 = await _context.관제고객휴일주간
                    .Where(h => h.관제관리번호 == 관제관리번호)
                    .Select(h => new 휴일주간
                    {
                        관리id = h.관리id,
                        관제관리번호 = h.관제관리번호,
                        휴일주간코드 = h.휴일주간코드
                    })
                    .ToListAsync();

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
        [HttpGet("{관제관리번호}/service")]
        public async Task<ActionResult<IEnumerable<부가서비스마스터>>> Get부가서비스(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var 부가서비스리스트 = await (from a in _context.부가서비스마스터
                                      join b in _context.부가서비스코드마스터 on a.부가서비스코드 equals b.부가서비스코드 into bGroup
                                      from b in bGroup.DefaultIfEmpty()
                                      join c in _context.부가서비스제공마스터 on a.부가서비스제공코드 equals c.부가서비스제공코드 into cGroup
                                      from c in cGroup.DefaultIfEmpty()
                                      where a.관제관리번호 == 관제관리번호
                                      select new 부가서비스마스터
                                      {
                                          관제관리번호 = a.관제관리번호,
                                          부가서비스코드명 = b.부가서비스코드명,
                                          부가서비스제공코드명 = c.부가서비스제공코드명,
                                          부가서비스일자 = a.부가서비스일자,
                                          추가메모 = a.추가메모
                                      })
                    .Take(1000)
                    .ToListAsync();

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
        [HttpGet("{관제관리번호}/dvr")]
        public async Task<ActionResult<IEnumerable<DVR연동마스터>>> GetDVR정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var dvr리스트 = await (from a in _context.DVR연동마스터
                                    join b in _context.DVR종류코드마스터 on a.DVR종류코드 equals b.DVR종류코드 into bGroup
                                    from b in bGroup.DefaultIfEmpty()
                                    where a.관제관리번호 == 관제관리번호
                                    select new DVR연동마스터
                                    {
                                        관제관리번호 = a.관제관리번호,
                                        접속방식 = a.접속방식,
                                        DVR종류코드 = a.DVR종류코드,
                                        DVR종류코드명 = b.DVR종류코드명,
                                        접속주소 = a.접속주소,
                                        접속포트 = a.접속포트,
                                        접속ID = a.접속ID,
                                        접속암호 = a.접속암호,
                                        추가일자 = a.추가일자
                                    })
                    .Take(1000)
                    .ToListAsync();

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
        [HttpGet("{관제관리번호}/smartphone-auth")]
        public async Task<ActionResult<IEnumerable<스마트정보조회마스터>>> Get스마트폰인증정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var 스마트폰인증리스트 = await _context.스마트정보조회마스터
                    .Where(s => s.관제관리번호 == 관제관리번호)
                    .ToListAsync();

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
        [HttpGet("{관제관리번호}/documents")]
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
        [HttpGet("{관제관리번호}/user-info")]
        public async Task<ActionResult<IEnumerable<사용자마스터>>> Get사용자정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var 사용자리스트 = await _context.사용자마스터
                    .Where(u => u.관제관리번호 == 관제관리번호)
                    .OrderBy(u => u.등록번호)
                    .Take(1000)
                    .ToListAsync();

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
        [HttpGet("{관제관리번호}/zone-info")]
        public async Task<ActionResult<IEnumerable<존마스터>>> Get존정보(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var 존정보리스트 = await _context.존마스터
                    .Where(z => z.관제관리번호 == 관제관리번호)
                    .OrderBy(z => z.존번호)
                    .Take(1000)
                    .ToListAsync();

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
        [HttpGet("{관제관리번호}/recent-signals")]
        public async Task<ActionResult> Get최근수신신호(
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
                            AND {tableName}.수신일자 <= @종료일자";

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

                    // 신호 필터 적용
                    if (신호필터 == "경계해제신호")
                    {
                        // 경계/해제 신호만 포함
                        if (signal.신호명?.Contains("경계") == true || signal.신호명?.Contains("해제") == true)
                        {
                            신호리스트.Add(signal);
                        }
                    }
                    else if (신호필터 == "처리신호제외")
                    {
                        // 처리 신호 제외
                        if (signal.신호명?.Contains("처리") != true)
                        {
                            신호리스트.Add(signal);
                        }
                    }
                    else
                    {
                        // 전체신호
                        신호리스트.Add(signal);
                    }
                }

                await connection.CloseAsync();

                // 전체 개수 조회 (필터 적용 전)
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
                            AND 수신일자 <= @종료일자";

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
        [HttpGet("{관제관리번호}/ashistory")]
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
        [HttpGet("sales-info/{customerNumber}")]
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
                    return StatusCode(503, new {
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
                    return StatusCode(503, new {
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
        [HttpGet("payment-history/{customerNumber}")]
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
        [HttpGet("visit-as-history/{customerNumber}")]
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
    }
}
