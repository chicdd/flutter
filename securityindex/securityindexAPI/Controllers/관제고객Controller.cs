using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;
using System.Diagnostics;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class 관제고객Controller : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<관제고객Controller> _logger;

        public 관제고객Controller(ApplicationDbContext context, ILogger<관제고객Controller> logger)
        {
            _context = context;
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
    }
}
